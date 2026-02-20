// Package service defines domain-level error types shared across auth-svc services.
package service

import (
	"errors"
	"fmt"
)

// ── SMS errors ────────────────────────────────────────────────────────────────

// ErrRateLimited is returned by SMSService.SendCode when the phone number has
// exceeded the per-minute send limit.
type ErrRateLimited struct {
	// RetryAfter is the number of seconds until the rate-limit window expires.
	RetryAfter int64
}

func (e ErrRateLimited) Error() string {
	return fmt.Sprintf("rate limited: retry after %d seconds", e.RetryAfter)
}

// ErrInvalidCode is returned by SMSService.VerifyCode when the provided
// verification code is incorrect.
var ErrInvalidCode = errors.New("invalid verification code")

// ErrCodeExpired is returned by SMSService.VerifyCode when no pending code
// exists for the given phone (may have expired or was already consumed).
var ErrCodeExpired = errors.New("verification code expired or not found")

// ErrSMSDelivery is returned by SMSService.SendCode when the SMS gateway
// reports a delivery failure.  The code has already been removed from Redis.
var ErrSMSDelivery = errors.New("SMS delivery failed")

// ── Device / auth errors ──────────────────────────────────────────────────────

// ErrDeviceRevoked means the device record no longer exists in the DB.
var ErrDeviceRevoked = errors.New("device revoked")

// ErrTokenReused means the RT was already consumed (replay detected, D-C).
var ErrTokenReused = errors.New("token already used")
