// Package middleware provides Gin middleware for sync-svc.
package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"listen-stream/shared/pkg/config"
)

// UserClaims mirrors the JWT payload issued by auth-svc.
type UserClaims struct {
	jwt.RegisteredClaims
	DeviceID string `json:"device_id"`
	Role     string `json:"role"`
}

// RequireUser rejects requests without a valid user Bearer token.
// The JWT secret is read from ConfigService (30 s cache).
func RequireUser(cfgSvc config.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			// WebSocket fallback: accept ?token= query param
			token = c.Query("token")
		}
		claims, err := parseUserToken(c.Request.Context(), token, cfgSvc)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized,
				gin.H{"code": "UNAUTHORIZED", "message": err.Error()})
			return
		}
		c.Set("user_id", claims.Subject)
		c.Set("device_id", claims.DeviceID)
		c.Set("role", claims.Role)
		c.Next()
	}
}

func bearerToken(c *gin.Context) string {
	auth := c.GetHeader("Authorization")
	if strings.HasPrefix(auth, "Bearer ") {
		return auth[7:]
	}
	return ""
}

func parseUserToken(ctx context.Context, tokenStr string, cfgSvc config.Service) (*UserClaims, error) {
	if tokenStr == "" {
		return nil, fmt.Errorf("missing bearer token")
	}
	secret, err := cfgSvc.Get(ctx, "USER_JWT_SECRET")
	if err != nil {
		return nil, fmt.Errorf("cannot load signing key")
	}
	tok, err := jwt.ParseWithClaims(tokenStr, &UserClaims{},
		func(t *jwt.Token) (interface{}, error) {
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
			}
			return []byte(secret), nil
		},
		jwt.WithAudience("user"),
		jwt.WithExpirationRequired(),
	)
	if err != nil {
		return nil, err
	}
	claims, ok := tok.Claims.(*UserClaims)
	if !ok || !tok.Valid {
		return nil, jwt.ErrTokenInvalidClaims
	}
	return claims, nil
}
