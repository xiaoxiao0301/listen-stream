package sms

import (
	"context"
	"log"
)

// DevLogAdapter is an SMS adapter for local development.
// Instead of delivering an SMS it prints the verification code to stdout
// so developers can complete the login flow without a real SMS gateway.
//
// Enable by setting SMS_PROVIDER=dev in the admin panel (system_configs).
type DevLogAdapter struct{}

func (DevLogAdapter) SendVerificationCode(_ context.Context, phone, code string) error {
	log.Printf("[SMS-DEV] phone=%s  code=%s  (local dev — no real SMS sent)", phone, code)
	return nil
}

// IsDevMode returns true if the adapter is a DevLogAdapter (no real SMS delivery).
func IsDevMode(a Adapter) bool {
	_, ok := a.(DevLogAdapter)
	return ok
}
