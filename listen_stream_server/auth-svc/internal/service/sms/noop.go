package sms

import (
	"context"
	"errors"
)

// ErrSMSNotConfigured is returned by NoopAdapter when SMS has not been configured yet.
var ErrSMSNotConfigured = errors.New("SMS provider not configured; set SMS_PROVIDER in system_configs via the admin panel")

// NoopAdapter is a stub SMS adapter used when no provider is configured.
// It allows auth-svc to start without crashing, but rejects all send requests.
type NoopAdapter struct{}

func (NoopAdapter) SendVerificationCode(_ context.Context, _, _ string) error {
	return ErrSMSNotConfigured
}
