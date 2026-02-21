package service

import (
	"context"
	"crypto/rand"
	"crypto/subtle"
	"encoding/json"
	"fmt"
	"time"

	goredis "github.com/redis/go-redis/v9"
	"go.uber.org/zap"

	"listen-stream/auth-svc/internal/service/sms"
	"listen-stream/shared/pkg/rdb"
)

const (
	// smsCodeTTL is how long a pending code stays valid after issue.
	smsCodeTTL = 5 * time.Minute
	// smsRateLimitTTL is the minimum interval between sends to the same phone.
	smsRateLimitTTL = 60 * time.Second
	// smsCodeLen is the number of digits in the verification code.
	smsCodeLen = 6
)

// SMSService manages code lifecycle: generation, rate-limiting, and verification.
// It does NOT know which SMS provider is used — that is the Adapter's concern.
//
// State flow:
//
//	SendCode:
//	  [rate limited?] ──yes──▶ ErrRateLimited
//	       │
//	       no
//	       ▼
//	  generate 6-digit code
//	       ▼
//	  redis SET sms:{phone} code  TTL=5m
//	  redis SET sms:limit:{phone} "1" TTL=60s
//	       ▼
//	  adapter.Send (may fail)
//	  [delivery fail?] ──yes──▶ DEL sms:{phone} → ErrSMSDelivery
//	       │
//	       no
//	       ▼
//	  return nil
//
//	VerifyCode:
//	  [code exists?] ──no──▶ ErrCodeExpired
//	       │
//	       yes
//	       ▼
//	  ConstantTimeCompare
//	  [match?] ──no──▶ ErrInvalidCode
//	       │
//	       yes
//	       ▼
//	  DEL sms:{phone}  (one-time use)
//	  return nil
type SMSService struct {
	adapter sms.Adapter
	rdb     *rdb.Client
	log     *zap.Logger
	devMode bool // true when using DevLogAdapter — codes are stored in Redis for admin panel
}

// NewSMSService creates an SMSService.
func NewSMSService(adapter sms.Adapter, rdbClient *rdb.Client, log *zap.Logger) *SMSService {
	return &SMSService{
		adapter: adapter,
		rdb:     rdbClient,
		log:     log,
		devMode: sms.IsDevMode(adapter),
	}
}

// SendCode generates a verification code, rate-limits the phone number, stores
// it in Redis, and delivers it via the configured SMS adapter.
func (s *SMSService) SendCode(ctx context.Context, phone string) error {
	// Check rate limit: if key exists, a code was already sent within 60 s.
	_, err := s.rdb.Get(ctx, rdb.KeySMSLimit(phone))
	if err == nil {
		// Key exists — rate limited. Return TTL as retryAfter.
		ttl, _ := s.rdb.TTL(ctx, rdb.KeySMSLimit(phone))
		retryAfter := int64(ttl.Seconds())
		if retryAfter <= 0 {
			retryAfter = int64(smsRateLimitTTL.Seconds())
		}
		return ErrRateLimited{RetryAfter: retryAfter}
	}

	// Generate 6-digit code using crypto/rand.
	code, err := randomDigits(smsCodeLen)
	if err != nil {
		return fmt.Errorf("sms: generate code: %w", err)
	}

	// Store the code and rate-limit sentinel in Redis.
	if err := s.rdb.Set(ctx, rdb.KeySMSCode(phone), code, smsCodeTTL); err != nil {
		return fmt.Errorf("sms: store code: %w", err)
	}
	if err := s.rdb.Set(ctx, rdb.KeySMSLimit(phone), "1", smsRateLimitTTL); err != nil {
		// Non-fatal: code is stored; worst case user can resend immediately.
		s.log.Warn("sms: failed to set rate-limit key", zap.String("phone", phone), zap.Error(err))
	}

	// Deliver via adapter.
	if err := s.adapter.SendVerificationCode(ctx, phone, code); err != nil {
		// Roll back the pending code so it cannot be guessed.
		_ = s.rdb.Del(ctx, rdb.KeySMSCode(phone))
		s.log.Error("sms: delivery failed", zap.String("phone", phone), zap.Error(err))
		return ErrSMSDelivery
	}

	s.log.Info("sms: code sent", zap.String("phone", phone))

	// In dev mode, write to the admin-visible sorted set so the SMS Logs panel can show the code.
	if s.devMode {
		s.writeDevLog(ctx, phone, code)
	}

	return nil
}

// writeDevLog appends a sent code to the Redis sorted-set ring buffer read by the admin panel.
func (s *SMSService) writeDevLog(ctx context.Context, phone, code string) {
	now := time.Now().UTC()
	entry, _ := json.Marshal(map[string]string{
		"phone":   phone,
		"code":    code,
		"sent_at": now.Format(time.RFC3339),
	})
	if err := s.rdb.ZAddTrim(ctx, rdb.KeyDevSMSLog(), float64(now.UnixMilli()), string(entry), 200); err != nil {
		s.log.Warn("sms: dev log write failed", zap.Error(err))
	}
}

// VerifyCode validates the one-time code and removes it from Redis on success.
// Returns ErrCodeExpired, ErrInvalidCode, or nil.
func (s *SMSService) VerifyCode(ctx context.Context, phone, input string) error {
	stored, err := s.rdb.Get(ctx, rdb.KeySMSCode(phone))
	if err != nil {
		if err == goredis.Nil {
			return ErrCodeExpired
		}
		return fmt.Errorf("sms: read code: %w", err)
	}

	// Constant-time comparison to prevent timing side-channel.
	if subtle.ConstantTimeCompare([]byte(stored), []byte(input)) != 1 {
		return ErrInvalidCode
	}

	// One-time use: delete immediately after successful verification.
	_ = s.rdb.Del(ctx, rdb.KeySMSCode(phone))
	return nil
}

// randomDigits generates n cryptographically random decimal digits.
func randomDigits(n int) (string, error) {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	digits := make([]byte, n)
	for i, v := range b {
		digits[i] = '0' + (v % 10)
	}
	return string(digits), nil
}
