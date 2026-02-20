// Package middleware provides Gin middleware for authentication and authorization.
//
// Role hierarchy (lowest → highest): USER < ADMIN < SUPER_ADMIN
//
// Context keys (use typed helpers — never read directly):
//
//	- ctxUserClaims  *service.UserClaims
//	- ctxAdminClaims *service.AdminClaims
//
// Usage example:
//
//	r.POST("/user/logout",
//	    middleware.RequireUser(jwtSvc, deviceQuerier),
//	    handlers.Logout,
//	)
//
//	adminAPI.Use(middleware.RequireAdmin(jwtSvc))
//	adminAPI.GET("/users", middleware.RequireRole("ADMIN"), handlers.ListUsers)
package middleware

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"

	"listen-stream/auth-svc/internal/repo"
	"listen-stream/auth-svc/internal/service"
)

// ── Context key types ─────────────────────────────────────────────────────────

type contextKey string

const (
	ctxUserClaims  contextKey = "user_claims"
	ctxAdminClaims contextKey = "admin_claims"
)

// ── Role hierarchy ────────────────────────────────────────────────────────────

var roleRank = map[string]int{
	"USER":        0,
	"ADMIN":       1,
	"SUPER_ADMIN": 2,
}

// ── Error codes (match openapi.yaml ErrorCode enum) ───────────────────────────

const (
	errCodeUnauthenticated = "UNAUTHENTICATED"
	errCodeDisabled        = "USER_DISABLED"
	errCodeTokenExpired    = "TOKEN_EXPIRED"
	errCodeInvalidToken    = "INVALID_TOKEN"
	errCodePermission      = "PERMISSION_DENIED"
)

func jsonErr(c *gin.Context, statusCode int, code, message string) {
	c.AbortWithStatusJSON(statusCode, gin.H{
		"code":    code,
		"message": message,
	})
}

// ── Bearer token extraction ───────────────────────────────────────────────────

// extractBearer returns the raw token string from "Authorization: Bearer <token>".
// Returns "" if the header is absent or malformed.
func extractBearer(c *gin.Context) string {
	h := c.GetHeader("Authorization")
	if h == "" || !strings.HasPrefix(h, "Bearer ") {
		return ""
	}
	return strings.TrimPrefix(h, "Bearer ")
}

// ── User middleware ───────────────────────────────────────────────────────────

// RequireUser validates a user AT (aud=["user"]) and checks the user is not
// disabled.  On success it writes *UserClaims to the Gin context.
//
// Errors surfaced:
//   - 401 UNAUTHENTICATED — missing / malformed token
//   - 401 TOKEN_EXPIRED   — expired token
//   - 401 INVALID_TOKEN   — bad signature / wrong audience
//   - 403 USER_DISABLED   — user.disabled = true in DB
func RequireUser(jwtSvc service.JWTService, userQuerier repo.Querier) gin.HandlerFunc {
	return func(c *gin.Context) {
		raw := extractBearer(c)
		if raw == "" {
			jsonErr(c, http.StatusUnauthorized, errCodeUnauthenticated, "authorization header missing or malformed")
			return
		}
		claims, err := jwtSvc.VerifyUserToken(c.Request.Context(), raw)
		if err != nil {
			if errors.Is(err, jwt.ErrTokenExpired) {
				jsonErr(c, http.StatusUnauthorized, errCodeTokenExpired, "access token expired")
				return
			}
			jsonErr(c, http.StatusUnauthorized, errCodeInvalidToken, "invalid token")
			return
		}
		// Check user enabled status via DB (Querier is sqlc-generated).
		user, err := userQuerier.GetUserByID(c.Request.Context(), claims.Subject)
		if err != nil {
			// Row not found ≡ deleted/purged user → treat as unauthenticated.
			jsonErr(c, http.StatusUnauthorized, errCodeUnauthenticated, "user not found")
			return
		}
		if user.Disabled {
			jsonErr(c, http.StatusForbidden, errCodeDisabled, "account disabled")
			return
		}
		c.Set(string(ctxUserClaims), claims)
		c.Next()
	}
}

// GetUserClaims returns the *UserClaims stored by RequireUser.
// Returns nil if the middleware was not executed.
func GetUserClaims(c *gin.Context) *service.UserClaims {
	v, _ := c.Get(string(ctxUserClaims))
	claims, _ := v.(*service.UserClaims)
	return claims
}

// ── Admin middleware ──────────────────────────────────────────────────────────

// RequireAdmin validates an admin AT (aud=["admin"]).
//
// Admin sessions do NOT have Refresh Tokens; expiry means re-login.
//
// Errors surfaced:
//   - 401 UNAUTHENTICATED — missing / malformed token
//   - 401 TOKEN_EXPIRED   — expired token
//   - 401 INVALID_TOKEN   — bad signature / wrong audience
func RequireAdmin(jwtSvc service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		raw := extractBearer(c)
		if raw == "" {
			jsonErr(c, http.StatusUnauthorized, errCodeUnauthenticated, "authorization header missing or malformed")
			return
		}
		claims, err := jwtSvc.VerifyAdminToken(c.Request.Context(), raw)
		if err != nil {
			if errors.Is(err, jwt.ErrTokenExpired) {
				jsonErr(c, http.StatusUnauthorized, errCodeTokenExpired, "access token expired")
				return
			}
			jsonErr(c, http.StatusUnauthorized, errCodeInvalidToken, "invalid token")
			return
		}
		c.Set(string(ctxAdminClaims), claims)
		c.Next()
	}
}

// GetAdminClaims returns the *AdminClaims stored by RequireAdmin.
// Returns nil if the middleware was not executed.
func GetAdminClaims(c *gin.Context) *service.AdminClaims {
	v, _ := c.Get(string(ctxAdminClaims))
	claims, _ := v.(*service.AdminClaims)
	return claims
}

// ── Role-based access control ─────────────────────────────────────────────────

// RequireRole enforces a minimum role level.
//
// Must be chained after RequireUser or RequireAdmin.
//
//	middleware.RequireRole("ADMIN")      requires at least ADMIN
//	middleware.RequireRole("SUPER_ADMIN") requires SUPER_ADMIN exactly equivalent
//
// Supported roles: "USER", "ADMIN", "SUPER_ADMIN"
func RequireRole(minRole string) gin.HandlerFunc {
	minRank, ok := roleRank[minRole]
	if !ok {
		panic("middleware.RequireRole: unknown role " + minRole)
	}
	return func(c *gin.Context) {
		var actualRole string
		if claims := GetUserClaims(c); claims != nil {
			actualRole = claims.Role
		} else if claims := GetAdminClaims(c); claims != nil {
			actualRole = claims.Role
		} else {
			jsonErr(c, http.StatusUnauthorized, errCodeUnauthenticated, "no authenticated principal")
			return
		}
		rank, known := roleRank[actualRole]
		if !known || rank < minRank {
			jsonErr(c, http.StatusForbidden, errCodePermission,
				"requires role "+minRole+" or higher")
			return
		}
		c.Next()
	}
}
