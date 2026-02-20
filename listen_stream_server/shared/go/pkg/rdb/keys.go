// Package rdb provides Redis key naming functions shared across all services.
// Using explicit constructor functions (rather than string constants) ensures
// key format changes are tracked at compile time.
package rdb

import "fmt"

// ── Auth / Devices ──────────────────────────────────────────

// KeyRT is the Redis key that maps a device_id to its Refresh Token hash.
// TTL == REFRESH_TOKEN_TTL (from ConfigService).
// D-C: written with SETNX on login; read+deleted atomically with GETDEL on refresh.
func KeyRT(deviceID string) string {
	return fmt.Sprintf("rt:%s", deviceID)
}

// ── SMS ─────────────────────────────────────────────────────

// KeySMSCode stores the 6-digit verification code for a phone number.
// TTL == 5 minutes (hard-coded in SMSService).
func KeySMSCode(phone string) string {
	return fmt.Sprintf("sms:%s", phone)
}

// KeySMSLimit is the rate-limit sentinel for a phone number.
// TTL == 60 s (one request per minute).
func KeySMSLimit(phone string) string {
	return fmt.Sprintf("sms:limit:%s", phone)
}

// ── Proxy Cache ──────────────────────────────────────────────

// KeyProxyCache is the Redis key for a cached third-party API response.
// path: upstream path (e.g. "/recommend/banner")
// qHash: SHA-256 hex of the sorted query string (first 16 chars for brevity)
func KeyProxyCache(path, qHash string) string {
	return fmt.Sprintf("proxy:%s:%s", path, qHash)
}

// ── WebSocket Pub/Sub ────────────────────────────────────────

// KeyWSChannel is the Redis Pub/Sub channel for pushing events to a user.
// All sync-svc instances subscribe to these channels (pattern: ws:user:*).
func KeyWSChannel(userID string) string {
	return fmt.Sprintf("ws:user:%s", userID)
}

// ── Admin ────────────────────────────────────────────────────

// KeyAdminFail tracks consecutive login failures for an admin username.
// TTL == 15 minutes; counter >= 5 locks the account.
func KeyAdminFail(username string) string {
	return fmt.Sprintf("admin:fail:%s", username)
}

// ── Cookie Health ────────────────────────────────────────────

// KeyCookieAlert is set when the scheduled Cookie refresh fails.
// TTL == 24 h; admin dashboard reads this to show an alert banner.
func KeyCookieAlert() string {
	return "cookie:alert"
}
