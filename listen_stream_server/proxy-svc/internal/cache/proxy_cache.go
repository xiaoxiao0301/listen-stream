// Package cache provides the Redis-backed proxy response cache.
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"listen-stream/shared/pkg/rdb"
)

// Entry holds a cached HTTP response body and its ETag.
type Entry struct {
	Body []byte `json:"body"`
	ETag string `json:"etag"`
}

// ProxyCache stores and retrieves serialised HTTP responses in Redis.
// For every cached path it writes two Redis keys:
//   - live key  (TTL == requested ttl)  — served on normal hits
//   - stale key (TTL == 2 × ttl)        — served when upstream is unavailable
type ProxyCache struct {
	rdb *rdb.Client
}

// NewProxyCache creates a ProxyCache backed by the given Redis client.
func NewProxyCache(rdbClient *rdb.Client) *ProxyCache {
	return &ProxyCache{rdb: rdbClient}
}

// Get returns the live cached entry for key, or an error on miss / unmarshal failure.
func (c *ProxyCache) Get(ctx context.Context, key string) (*Entry, error) {
	return c.load(ctx, key)
}

// GetStale returns the stale-backup entry for key (survives 2× the original TTL).
// Used as a fallback when the upstream is unavailable.
func (c *ProxyCache) GetStale(ctx context.Context, key string) (*Entry, error) {
	return c.load(ctx, staleKey(key))
}

// Set stores entry under key with the given TTL and also writes a stale-backup key
// with 2× the TTL so that GetStale can serve it after the live entry expires.
// TTL == 0 is a no-op (uncached endpoints must not call Set).
func (c *ProxyCache) Set(ctx context.Context, key string, e *Entry, ttl time.Duration) error {
	if ttl == 0 {
		return nil
	}
	data, err := json.Marshal(e)
	if err != nil {
		return fmt.Errorf("cache: marshal: %w", err)
	}
	val := string(data)
	// Live key
	if err := c.rdb.Set(ctx, key, val, ttl); err != nil {
		return fmt.Errorf("cache: set live: %w", err)
	}
	// Stale backup — ignore errors (best effort)
	_ = c.rdb.Set(ctx, staleKey(key), val, ttl*2)
	return nil
}

// ── helpers ──────────────────────────────────────────────────────────────────

func (c *ProxyCache) load(ctx context.Context, key string) (*Entry, error) {
	raw, err := c.rdb.Get(ctx, key)
	if err != nil {
		return nil, fmt.Errorf("cache miss: %w", err)
	}
	var e Entry
	if err := json.Unmarshal([]byte(raw), &e); err != nil {
		return nil, fmt.Errorf("cache: unmarshal: %w", err)
	}
	return &e, nil
}

func staleKey(key string) string {
	return key + ":stale"
}
