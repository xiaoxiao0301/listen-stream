// Package rdb wraps go-redis/v9 with a minimal, mockable interface
// used across all four services.
package rdb

import (
	"context"
	"fmt"
	"time"

	goredis "github.com/redis/go-redis/v9"
)

// Client is a thin wrapper around *goredis.Client, exposing only the
// operations used by Listen Stream. All methods accept a context so
// callers can propagate deadlines and cancellations.
type Client struct {
	rdb *goredis.Client
}

// New creates a Client from a Redis URL (redis://[:password@]host:port/db).
// It does NOT dial immediately; the connection is lazy (first command).
func New(redisURL string) *Client {
	opts, err := goredis.ParseURL(redisURL)
	if err != nil {
		panic(fmt.Sprintf("rdb: invalid REDIS_URL %q: %v", redisURL, err))
	}
	return &Client{rdb: goredis.NewClient(opts)}
}

// Ping checks connectivity. Call once at startup.
func (c *Client) Ping(ctx context.Context) error {
	return c.rdb.Ping(ctx).Err()
}

// Close releases the underlying connection pool.
func (c *Client) Close() error {
	return c.rdb.Close()
}

// ── Basic KV ─────────────────────────────────────────────────────────────────

// Get retrieves the string value of key.
// Returns goredis.Nil error when the key does not exist.
func (c *Client) Get(ctx context.Context, key string) (string, error) {
	return c.rdb.Get(ctx, key).Result()
}

// Set stores value with a TTL. ttl == 0 means no expiry.
func (c *Client) Set(ctx context.Context, key, value string, ttl time.Duration) error {
	return c.rdb.Set(ctx, key, value, ttl).Err()
}

// SetNX sets value only if key does NOT exist (atomic).
// Returns true if the key was set, false if it already existed.
// Used by D-C: writing RT hash on login (SETNX rt:{device_id}).
func (c *Client) SetNX(ctx context.Context, key, value string, ttl time.Duration) (bool, error) {
	return c.rdb.SetNX(ctx, key, value, ttl).Result()
}

// GetDel atomically reads and deletes a key.
// Returns (value, nil) on success.
// Returns ("", goredis.Nil) when the key does not exist (RT expired / already used).
// This is the D-C primitive: concurrent requests race; only the first caller
// receives the value; the second gets Nil and must return 401.
func (c *Client) GetDel(ctx context.Context, key string) (string, error) {
	return c.rdb.GetDel(ctx, key).Result()
}

// Del deletes one or more keys. Silently succeeds if any key is missing.
func (c *Client) Del(ctx context.Context, keys ...string) error {
	return c.rdb.Del(ctx, keys...).Err()
}

// TTL returns the remaining TTL for key.
// Returns (-2 * time.Second, nil) if key does not exist.
// Returns (-1 * time.Second, nil) if key has no expiry.
func (c *Client) TTL(ctx context.Context, key string) (time.Duration, error) {
	return c.rdb.TTL(ctx, key).Result()
}

// Incr increments an integer counter and sets ttl on first creation.
// Used for admin login failure tracking.
func (c *Client) Incr(ctx context.Context, key string, ttl time.Duration) (int64, error) {
	pipe := c.rdb.Pipeline()
	incr := pipe.Incr(ctx, key)
	pipe.Expire(ctx, key, ttl) // no-op if key already has a TTL
	if _, err := pipe.Exec(ctx); err != nil {
		return 0, err
	}
	return incr.Val(), nil
}

// ── Scan + Del (batch) ───────────────────────────────────────────────────────

// ScanDel deletes all keys matching pattern (e.g. "rt:*").
// Internally uses SCAN with a cursor to avoid blocking; processes in batches
// of 100. Returns the total number of deleted keys.
// Used by admin-svc when USER_JWT_SECRET is rotated.
func (c *Client) ScanDel(ctx context.Context, pattern string) (int64, error) {
	var cursor uint64
	var total int64
	for {
		keys, nextCursor, err := c.rdb.Scan(ctx, cursor, pattern, 100).Result()
		if err != nil {
			return total, fmt.Errorf("scan %q: %w", pattern, err)
		}
		if len(keys) > 0 {
			n, err := c.rdb.Del(ctx, keys...).Result()
			if err != nil {
				return total, fmt.Errorf("del batch: %w", err)
			}
			total += n
		}
		cursor = nextCursor
		if cursor == 0 {
			break
		}
	}
	return total, nil
}

// ── Pub/Sub ───────────────────────────────────────────────────────────────────

// Publish sends a message to a channel. Fire-and-forget; errors are logged
// by the caller but do not fail the main operation.
func (c *Client) Publish(ctx context.Context, channel, msg string) error {
	return c.rdb.Publish(ctx, channel, msg).Err()
}

// Subscribe returns a *goredis.PubSub for the given channels.
// Call pubsub.Channel() to receive messages. Remember to call pubsub.Close()
// when done (typically in a goroutine listening until context is cancelled).
func (c *Client) Subscribe(ctx context.Context, channels ...string) *goredis.PubSub {
	return c.rdb.Subscribe(ctx, channels...)
}

// PSubscribe returns a *goredis.PubSub for pattern-based subscription.
// Used by WS Hub to subscribe to "ws:user:*".
func (c *Client) PSubscribe(ctx context.Context, patterns ...string) *goredis.PubSub {
	return c.rdb.PSubscribe(ctx, patterns...)
}
