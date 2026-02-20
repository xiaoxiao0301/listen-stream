// Package crypto provides AES-256-GCM symmetric encryption/decryption
// used by ConfigService to protect secrets stored in system_configs table.
//
// Wire format (base64-encoded JSON):
//
//	{ "iv": "<hex 12-byte nonce>", "data": "<hex ciphertext+GCM-tag>" }
//
// The GCM authentication tag (16 bytes) is appended by cipher.AEAD.Seal
// and embedded at the end of the "data" field. On decryption, AEAD.Open
// verifies the tag automatically; a tampered value returns an error.
package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
)

// cipherPayload is the persisted JSON structure.
type cipherPayload struct {
	IV   string `json:"iv"`   // hex-encoded 12-byte GCM nonce
	Data string `json:"data"` // hex-encoded ciphertext || GCM tag (16 bytes suffix)
}

// ParseKey decodes a 64-character hex string into a 32-byte AES-256 key.
//
// Call this once at startup; fatal-exit if the key is invalid.
//
//	key, err := crypto.ParseKey(os.Getenv("CONFIG_ENCRYPTION_KEY")
//	if err != nil { log.Fatalf("CONFIG_ENCRYPTION_KEY invalid: %v", err) }
func ParseKey(hexKey string) ([]byte, error) {
	if len(hexKey) != 64 {
		return nil, fmt.Errorf(
			"CONFIG_ENCRYPTION_KEY must be 64 hex chars (32 bytes), got %d", len(hexKey))
	}
	key, err := hex.DecodeString(hexKey)
	if err != nil {
		return nil, fmt.Errorf("CONFIG_ENCRYPTION_KEY is not valid hex: %w", err)
	}
	return key, nil
}

// Encrypt encrypts plaintext with AES-256-GCM and returns a base64-JSON string.
//
// A fresh random nonce is generated for every call; identical plaintexts
// produce different ciphertexts (IND-CPA secure).
func Encrypt(key []byte, plaintext string) (string, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", fmt.Errorf("create cipher: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("create gcm: %w", err)
	}
	// Nonce: 12 bytes (GCM standard)
	nonce := make([]byte, gcm.NonceSize()) // NonceSize() == 12
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("generate nonce: %w", err)
	}
	ciphertext := gcm.Seal(nil, nonce, []byte(plaintext), nil)
	// Seal appends: encrypted_plaintext || auth_tag (16 bytes)
	payload := cipherPayload{
		IV:   hex.EncodeToString(nonce),
		Data: hex.EncodeToString(ciphertext),
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("marshal payload: %w", err)
	}
	return base64.StdEncoding.EncodeToString(raw), nil
}

// Decrypt reverses Encrypt. Returns the original plaintext or an error
// if the ciphertext has been tampered with (GCM tag mismatch).
func Decrypt(key []byte, encoded string) (string, error) {
	raw, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return "", fmt.Errorf("base64 decode: %w", err)
	}
	var payload cipherPayload
	if err = json.Unmarshal(raw, &payload); err != nil {
		return "", fmt.Errorf("unmarshal payload: %w", err)
	}
	nonce, err := hex.DecodeString(payload.IV)
	if err != nil {
		return "", fmt.Errorf("decode nonce: %w", err)
	}
	ciphertext, err := hex.DecodeString(payload.Data)
	if err != nil {
		return "", fmt.Errorf("decode ciphertext: %w", err)
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", fmt.Errorf("create cipher: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("create gcm: %w", err)
	}
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	// Open verifies the auth tag and decrypts
	if err != nil {
		// Do not propagate the internal error message to avoid oracle attacks
		return "", errors.New("decryption failed: ciphertext may be tampered")
	}
	return string(plaintext), nil
}
