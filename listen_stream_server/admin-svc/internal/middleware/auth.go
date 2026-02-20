// Package middleware provides Gin middleware for admin-svc.
package middleware

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"

	"listen-stream/admin-svc/internal/service"
)

type contextKey string

const ctxAdminClaims contextKey = "admin_claims"

var roleRank = map[string]int{
	"USER":        0,
	"ADMIN":       1,
	"SUPER_ADMIN": 2,
}

const (
	errUnauthenticated = "UNAUTHENTICATED"
	errTokenExpired    = "TOKEN_EXPIRED"
	errInvalidToken    = "INVALID_TOKEN"
	errPermission      = "PERMISSION_DENIED"
)

func jsonErr(c *gin.Context, status int, code, msg string) {
	c.AbortWithStatusJSON(status, gin.H{"code": code, "message": msg})
}

func extractBearer(c *gin.Context) string {
	h := c.GetHeader("Authorization")
	if h == "" || !strings.HasPrefix(h, "Bearer ") {
		return ""
	}
	return strings.TrimPrefix(h, "Bearer ")
}

// RequireAdmin validates an admin AT (aud=["admin"]) and writes *AdminClaims to context.
func RequireAdmin(jwtSvc service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		raw := extractBearer(c)
		if raw == "" {
			jsonErr(c, http.StatusUnauthorized, errUnauthenticated, "authorization header missing or malformed")
			return
		}
		claims, err := jwtSvc.VerifyAdminToken(c.Request.Context(), raw)
		if err != nil {
			if errors.Is(err, jwt.ErrTokenExpired) {
				jsonErr(c, http.StatusUnauthorized, errTokenExpired, "token expired")
				return
			}
			jsonErr(c, http.StatusUnauthorized, errInvalidToken, "invalid token")
			return
		}
		c.Set(string(ctxAdminClaims), claims)
		c.Next()
	}
}

// GetAdminClaims returns *AdminClaims stored by RequireAdmin. Returns nil if not set.
func GetAdminClaims(c *gin.Context) *service.AdminClaims {
	v, _ := c.Get(string(ctxAdminClaims))
	claims, _ := v.(*service.AdminClaims)
	return claims
}

// RequireRole enforces a minimum role. Must chain after RequireAdmin.
func RequireRole(minRole string) gin.HandlerFunc {
	minRank, ok := roleRank[minRole]
	if !ok {
		panic("middleware.RequireRole: unknown role " + minRole)
	}
	return func(c *gin.Context) {
		claims := GetAdminClaims(c)
		if claims == nil {
			jsonErr(c, http.StatusUnauthorized, errUnauthenticated, "no authenticated principal")
			return
		}
		rank, known := roleRank[claims.Role]
		if !known || rank < minRank {
			jsonErr(c, http.StatusForbidden, errPermission, "requires role "+minRole+" or higher")
			return
		}
		c.Next()
	}
}
