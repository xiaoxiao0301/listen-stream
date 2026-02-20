// Package middleware provides Gin middleware for proxy-svc.
package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"listen-stream/shared/pkg/config"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// UserClaims mirrors auth-svc claims; only sub + device_id are needed here.
type UserClaims struct {
	jwt.RegisteredClaims
	DeviceID string `json:"device_id"`
	Role     string `json:"role"`
}

// proxy-svc verifies user JWTs independently — no cross-service call.
// The secret is fetched from ConfigService on every verify (30 s cache in ConfigService).

// RequireUser aborts with 401 if the request lacks a valid user Bearer token.
func RequireUser(cfgSvc config.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, err := parseUserToken(c.Request.Context(), c.GetHeader("Authorization"), cfgSvc)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"code": "UNAUTHORIZED", "message": err.Error()})
			return
		}
		c.Set("user_id", claims.Subject)
		c.Set("device_id", claims.DeviceID)
		c.Set("role", claims.Role)
		c.Next()
	}
}

// OptionalUser sets user identity if a valid Bearer token is present.
// The request is NOT rejected when the token is absent.
func OptionalUser(cfgSvc config.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		auth := c.GetHeader("Authorization")
		if auth == "" {
			c.Next()
			return
		}
		claims, err := parseUserToken(c.Request.Context(), auth, cfgSvc)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"code": "INVALID_TOKEN"})
			return
		}
		c.Set("user_id", claims.Subject)
		c.Set("device_id", claims.DeviceID)
		c.Set("role", claims.Role)
		c.Next()
	}
}

func parseUserToken(ctx context.Context, authHeader string, cfgSvc config.Service) (*UserClaims, error) {
	const prefix = "Bearer "
	if !strings.HasPrefix(authHeader, prefix) {
		return nil, fmt.Errorf("missing bearer token")
	}
	tokenStr := authHeader[len(prefix):]
	secret, err := cfgSvc.Get(ctx, "USER_JWT_SECRET")
	if err != nil {
		return nil, fmt.Errorf("cannot load signing key")
	}
	token, err := jwt.ParseWithClaims(tokenStr, &UserClaims{},
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
	claims, ok := token.Claims.(*UserClaims)
	if !ok || !token.Valid {
		return nil, jwt.ErrTokenInvalidClaims
	}
	return claims, nil
}
