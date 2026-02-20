package sms

import (
	"context"
	"fmt"
	"strings"

	"listen-stream/shared/pkg/config"
)

// NewAdapter reads SMS_PROVIDER from ConfigService and returns the corresponding
// Adapter implementation.
//
// Supported values for SMS_PROVIDER: "aliyun", "tencent" (case-insensitive).
// Config key is not cached here — the adapters themselves read per-request
// credentials via ConfigService (30 s cache).
func NewAdapter(ctx context.Context, cfgSvc config.Service) (Adapter, error) {
	provider, err := cfgSvc.Get(ctx, "SMS_PROVIDER")
	if err != nil {
		return nil, fmt.Errorf("sms factory: read SMS_PROVIDER: %w", err)
	}

	switch strings.ToLower(strings.TrimSpace(provider)) {
	case "aliyun":
		return NewAliyunAdapter(cfgSvc), nil
	case "tencent":
		return NewTencentAdapter(cfgSvc), nil
	default:
		return nil, fmt.Errorf("sms factory: unknown SMS_PROVIDER %q (supported: aliyun, tencent)", provider)
	}
}
