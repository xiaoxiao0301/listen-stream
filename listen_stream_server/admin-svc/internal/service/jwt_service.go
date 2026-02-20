// Package service provides JWT signing and verification for admin-svc.
//
// admin-svc uses ADMIN_JWT_SECRET only (aud="admin"). User tokens are
// rejected so admin credentials cannot be forged by regular users.
package service

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"listen-stream/shared/pkg/config"
)

const (
	cfgAdminJWTSecret  = "ADMIN_JWT_SECRET"
	cfgAdminTokenTTL   = "ADMIN_TOKEN_TTL" // seconds, default 7200
	defaultAdminTokenTTL = int64(7200)
)

// AdminClaims embeds standard JWT claims plus admin-specific fields.
type AdminClaims struct {
	jwt.RegisteredClaims
	Username string `json:"username"`
	Role     string `json:"role"`
}

// JWTService signs and verifies admin Access Tokens.
type JWTService interface {
	SignAdminAccessToken(ctx context.Context, adminID, username, role string) (string, error)
	VerifyAdminToken(ctx context.Context, tokenStr string) (*AdminClaims, error)
	AccessTokenTTL(ctx context.Context) (int64, error)
}

type jwtService struct {
	cfgSvc config.Service
}

// NewJWTService creates a JWTService backed by ConfigService.
func NewJWTService(cfgSvc config.Service) JWTService {
	return &jwtService{cfgSvc: cfgSvc}
}

func (s *jwtService) SignAdminAccessToken(ctx context.Context, adminID, username, role string) (string, error) {
	secret, err := s.cfgSvc.Get(ctx, cfgAdminJWTSecret)
	if err != nil {
		return "", fmt.Errorf("jwt: get ADMIN_JWT_SECRET: %w", err)
	}
	ttl, _ := s.AccessTokenTTL(ctx)
	claims := AdminClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   adminID,
			Audience:  jwt.ClaimStrings{"admin"},
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(ttl) * time.Second)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ID:        uuid.NewString(),
		},
		Username: username,
		Role:     role,
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func (s *jwtService) VerifyAdminToken(ctx context.Context, tokenStr string) (*AdminClaims, error) {
	secret, err := s.cfgSvc.Get(ctx, cfgAdminJWTSecret)
	if err != nil {
		return nil, fmt.Errorf("jwt: get ADMIN_JWT_SECRET: %w", err)
	}
	token, err := jwt.ParseWithClaims(
		tokenStr,
		&AdminClaims{},
		func(t *jwt.Token) (interface{}, error) {
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
			}
			return []byte(secret), nil
		},
		jwt.WithAudience("admin"),
		jwt.WithExpirationRequired(),
	)
	if err != nil {
		return nil, err
	}
	claims, ok := token.Claims.(*AdminClaims)
	if !ok || !token.Valid {
		return nil, jwt.ErrTokenInvalidClaims
	}
	return claims, nil
}

func (s *jwtService) AccessTokenTTL(ctx context.Context) (int64, error) {
	raw, err := s.cfgSvc.Get(ctx, cfgAdminTokenTTL)
	if err != nil {
		return defaultAdminTokenTTL, nil
	}
	ttl, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || ttl <= 0 {
		return defaultAdminTokenTTL, nil
	}
	return ttl, nil
}
