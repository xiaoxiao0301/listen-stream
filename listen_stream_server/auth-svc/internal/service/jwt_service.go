// Package service implements JWTService: dual-key JWT issuance and verification
// implementing architecture decision D-A.
//
// D-A summary:
//   - USER_JWT_SECRET  signs tokens with aud=["user"];  read from ConfigService.
//   - ADMIN_JWT_SECRET signs tokens with aud=["admin"]; read from ConfigService.
//   - The two secrets are completely independent: rotating one does NOT affect
//     tokens signed by the other.
//   - ConfigService provides a 30 s in-memory cache, so per-request key lookups
//     are cheap and reflect admin changes within 30 s.
package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"listen-stream/shared/pkg/config"
)

// ── Config key constants ──────────────────────────────────────────────────────

const (
	cfgUserJWTSecret   = "USER_JWT_SECRET"
	cfgAdminJWTSecret  = "ADMIN_JWT_SECRET"
	cfgAccessTokenTTL  = "ACCESS_TOKEN_TTL"   // seconds, default 7200
	cfgRefreshTokenTTL = "REFRESH_TOKEN_TTL"  // seconds, default 2592000
)

// Default TTL values used when the config key is absent or unparseable.
const (
	defaultATTL = int64(7200)
	defaultRTTL = int64(2592000)
)

// ── Claims ─────────────────────────────────────────────────────────────────────

// UserClaims is embedded in every Access Token issued for end users.
// aud MUST be ["user"] — verified by RequireUser middleware.
type UserClaims struct {
	jwt.RegisteredClaims
	DeviceID string `json:"device_id"`
	Role     string `json:"role"`
}

// AdminClaims is embedded in every Access Token issued for admin users.
// aud MUST be ["admin"] — verified by RequireAdmin middleware.
type AdminClaims struct {
	jwt.RegisteredClaims
	Username string `json:"username"`
	Role     string `json:"role"`
}

// ── Interface ─────────────────────────────────────────────────────────────────

// JWTService issues and verifies JWTs for both user and admin flows.
type JWTService interface {
	// SignUserAccessToken creates a signed JWT for a regular user.
	// Key: USER_JWT_SECRET (from ConfigService, 30 s cache).
	// aud: ["user"], sub: userID, custom: device_id, role.
	SignUserAccessToken(ctx context.Context, userID, deviceID, role string) (string, error)

	// VerifyUserToken parses and validates a user Access Token.
	// Returns ErrTokenSignatureInvalid after key rotation.
	// Never returns (nil, nil) — either the claims or an error is non-nil.
	VerifyUserToken(ctx context.Context, tokenStr string) (*UserClaims, error)

	// SignAdminAccessToken creates a signed JWT for an admin user.
	// Key: ADMIN_JWT_SECRET (from ConfigService, 30 s cache).
	// aud: ["admin"]. Admin tokens have NO Refresh Token.
	SignAdminAccessToken(ctx context.Context, adminID, username, role string) (string, error)

	// VerifyAdminToken parses and validates an admin Access Token.
	VerifyAdminToken(ctx context.Context, tokenStr string) (*AdminClaims, error)

	// IssueRefreshToken generates a cryptographically random RT and its hash.
	//   rt     = uuid v4 plaintext (returned to client, stored nowhere)
	//   rtHash = hex(SHA-256(rt))  (persisted in Redis + devices.rt_hash)
	// The caller is responsible for writing rtHash to Redis with SETNX.
	IssueRefreshToken() (rt string, rtHash string)

	// AccessTokenTTL returns the AT lifetime in seconds (from config, default 7200).
	AccessTokenTTL(ctx context.Context) (int64, error)

	// RefreshTokenTTL returns the RT lifetime in seconds (default 2592000 = 30 days).
	RefreshTokenTTL(ctx context.Context) (int64, error)
}

// ── Implementation ────────────────────────────────────────────────────────────

type jwtService struct {
	cfgSvc config.Service
}

// NewJWTService creates a JWTService backed by the given ConfigService.
func NewJWTService(cfgSvc config.Service) JWTService {
	return &jwtService{cfgSvc: cfgSvc}
}

// SignUserAccessToken signs a user AT with USER_JWT_SECRET.
func (s *jwtService) SignUserAccessToken(ctx context.Context, userID, deviceID, role string) (string, error) {
	secret, err := s.cfgSvc.Get(ctx, cfgUserJWTSecret)
	if err != nil {
		return "", fmt.Errorf("jwt: get USER_JWT_SECRET: %w", err)
	}
	ttl, err := s.AccessTokenTTL(ctx)
	if err != nil {
		ttl = defaultATTL
	}
	claims := UserClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			Audience:  jwt.ClaimStrings{"user"},
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(ttl) * time.Second)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ID:        uuid.NewString(),
		},
		DeviceID: deviceID,
		Role:     role,
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// VerifyUserToken validates a user AT. The key is fetched from ConfigService
// on every call (30 s cache); after USER_JWT_SECRET rotation the old tokens
// fail immediately with jwt.ErrTokenSignatureInvalid.
func (s *jwtService) VerifyUserToken(ctx context.Context, tokenStr string) (*UserClaims, error) {
	secret, err := s.cfgSvc.Get(ctx, cfgUserJWTSecret)
	if err != nil {
		return nil, fmt.Errorf("jwt: get USER_JWT_SECRET: %w", err)
	}
	token, err := jwt.ParseWithClaims(
		tokenStr,
		&UserClaims{},
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

// SignAdminAccessToken signs an admin AT with ADMIN_JWT_SECRET.
func (s *jwtService) SignAdminAccessToken(ctx context.Context, adminID, username, role string) (string, error) {
	secret, err := s.cfgSvc.Get(ctx, cfgAdminJWTSecret)
	if err != nil {
		return "", fmt.Errorf("jwt: get ADMIN_JWT_SECRET: %w", err)
	}
	ttl, err := s.AccessTokenTTL(ctx)
	if err != nil {
		ttl = defaultATTL
	}
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

// VerifyAdminToken validates an admin AT against ADMIN_JWT_SECRET.
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

// IssueRefreshToken generates a UUID v4 RT and its SHA-256 hex hash.
// Only the hash is persisted (Redis + DB); the plaintext RT is returned to
// the client exactly once and never stored server-side.
func (s *jwtService) IssueRefreshToken() (string, string) {
	rt := uuid.NewString()
	sum := sha256.Sum256([]byte(rt))
	return rt, hex.EncodeToString(sum[:])
}

// AccessTokenTTL reads ACCESS_TOKEN_TTL from config; falls back to 7200.
func (s *jwtService) AccessTokenTTL(ctx context.Context) (int64, error) {
	raw, err := s.cfgSvc.Get(ctx, cfgAccessTokenTTL)
	if err != nil {
		// not fatal: use default
		return defaultATTL, nil
	}
	ttl, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || ttl <= 0 {
		return defaultATTL, nil
	}
	return ttl, nil
}

// RefreshTokenTTL reads REFRESH_TOKEN_TTL from config; falls back to 2592000.
func (s *jwtService) RefreshTokenTTL(ctx context.Context) (int64, error) {
	raw, err := s.cfgSvc.Get(ctx, cfgRefreshTokenTTL)
	if err != nil {
		return defaultRTTL, nil
	}
	ttl, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || ttl <= 0 {
		return defaultRTTL, nil
	}
	return ttl, nil
}
