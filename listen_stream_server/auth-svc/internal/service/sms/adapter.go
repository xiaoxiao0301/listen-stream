// Package sms defines the SMS delivery abstraction and its concrete adapters.
//
// The active adapter is selected at runtime from ConfigService key SMS_PROVIDER
// ("aliyun" | "tencent").  Switching providers requires no recompile — only a
// DB config change followed by a service restart (or a ConfigService.Preload
// call if live reload is added later).
package sms

import "context"

// Adapter sends a one-time verification code to a phone number.
// All implementations MUST be safe for concurrent use.
type Adapter interface {
	// SendVerificationCode delivers a 6-digit numeric code to the given phone.
	// phone is always in E.164 format (e.g. "+8613800138000").
	// Returns nil on successful delivery, non-nil on any gateway error.
	SendVerificationCode(ctx context.Context, phone, code string) error
}
