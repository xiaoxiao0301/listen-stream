// Package util provides utility helpers for admin-svc.
package util

// MaskSecret partially obscures a secret string for safe display in API responses.
//
// Rules:
//   - len <= 10  → "***"
//   - otherwise  → first 6 chars + "***" + last 4 chars
//
// Example: MaskSecret("abcdefghij1234") → "abcdef***1234"
func MaskSecret(s string) string {
	if len(s) <= 10 {
		return "***"
	}
	return s[:6] + "***" + s[len(s)-4:]
}
