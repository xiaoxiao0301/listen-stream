// Package service provides business-logic services for admin-svc.
package service

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"fmt"

	"golang.org/x/crypto/argon2"
)

// argon2id tuning parameters (OWASP recommended minimums for interactive logins).
const (
	argonTime    = 1
	argonMemory  = 64 * 1024 // 64 MiB
	argonThreads = 4
	argonKeyLen  = 32
	argonSaltLen = 16
)

// HashPassword derives an Argon2id PHC string from the plain-text password.
//
// Format: $argon2id$v=19$m=65536,t=1,p=4$<base64 salt>$<base64 hash>
func HashPassword(password string) (string, error) {
	salt := make([]byte, argonSaltLen)
	if _, err := rand.Read(salt); err != nil {
		return "", fmt.Errorf("argon2id: generate salt: %w", err)
	}
	hash := argon2.IDKey([]byte(password), salt, argonTime, argonMemory, argonThreads, argonKeyLen)
	return fmt.Sprintf(
		"$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s",
		argon2.Version,
		argonMemory,
		argonTime,
		argonThreads,
		base64.RawStdEncoding.EncodeToString(salt),
		base64.RawStdEncoding.EncodeToString(hash),
	), nil
}

// VerifyPassword reports whether password matches the PHC hash produced by HashPassword.
// Returns false (not an error) on any mismatch.
func VerifyPassword(password, phc string) bool {
	params, salt, hash, err := decodePHC(phc)
	if err != nil {
		return false
	}
	compare := argon2.IDKey([]byte(password), salt, params[0], params[1], uint8(params[2]), uint32(len(hash)))
	return subtle.ConstantTimeCompare(hash, compare) == 1
}

// decodePHC parses a $argon2id$… PHC string.
// Returns [time, memory, threads], salt, hash, error.
func decodePHC(phc string) ([3]uint32, []byte, []byte, error) {
	var zero [3]uint32
	var version int
	var t, m, p uint32
	n, err2 := fmt.Sscanf(phc,
		"$argon2id$v=%d$m=%d,t=%d,p=%d$",
		&version, &m, &t, &p,
	)
	if err2 != nil || n != 4 {
		return zero, nil, nil, fmt.Errorf("argon2id: parse phc header: %w", err2)
	}
	// Extract salt and hash by splitting on $
	parts := splitPHC(phc)
	if len(parts) < 2 {
		return zero, nil, nil, fmt.Errorf("argon2id: not enough parts in phc")
	}
	salt, err := base64.RawStdEncoding.DecodeString(parts[len(parts)-2])
	if err != nil {
		return zero, nil, nil, fmt.Errorf("argon2id: decode salt: %w", err)
	}
	hash, err := base64.RawStdEncoding.DecodeString(parts[len(parts)-1])
	if err != nil {
		return zero, nil, nil, fmt.Errorf("argon2id: decode hash: %w", err)
	}
	return [3]uint32{t, m, p}, salt, hash, nil
}

func splitPHC(s string) []string {
	var parts []string
	start := 0
	for i, c := range s {
		if c == '$' && i > 0 {
			part := s[start:i]
			if part != "" {
				parts = append(parts, part)
			}
			start = i + 1
		}
	}
	if start < len(s) {
		parts = append(parts, s[start:])
	}
	return parts
}
