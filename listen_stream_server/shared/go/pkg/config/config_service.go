// Package config provides ConfigService: a thread-safe, encrypted configuration
// reader backed by PostgreSQL's system_configs table with a 30-second in-memory
// cache to avoid per-request DB round-trips.
//
// Startup contract:
//  1. Call New(pool, encKey) to create the service.
//  2. Call Preload(ctx) before starting the HTTP server to prime the cache.
//  3. Inject as a dependency into handlers and JWT service.
package config

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"listen-stream/shared/pkg/crypto"
)

// cacheTTL is the maximum age of a cached config value before the next
// read forces a DB refresh. 30 s balances freshness and DB load.
const cacheTTL = 30 * time.Second

// ── Interface ─────────────────────────────────────────────────────────────────

// Service is the interface consumed by other packages.
// All methods are safe for concurrent use.
type Service interface {
	// Get returns the decrypted value for key.
	// Reads from cache if the entry is fresh; otherwise queries DB.
	// Returns ErrConfigNotFound if the key has never been set.
	Get(ctx context.Context, key string) (string, error)

	// GetMany returns decrypted values for a set of keys in one DB round-trip
	// (for keys not already cached). Missing keys are omitted from the map.
	GetMany(ctx context.Context, keys []string) (map[string]string, error)

	// Set encrypts value and persists it to DB, then invalidates the cache entry.
	// updatedBy should be the admin username or "system"/"setup"/"cron".
	Set(ctx context.Context, key, value, updatedBy string) error

	// Preload fetches all rows from system_configs and warms the cache.
	// Call once during startup before serving requests.
	Preload(ctx context.Context) error

	// Invalidate evicts a specific key from the in-memory cache.
	// Called after Set, or externally when another instance signals a change.
	Invalidate(key string)
}

// ErrConfigNotFound is returned by Get when the key does not exist in DB.
var ErrConfigNotFound = errors.New("config: key not found")

// ── Implementation ────────────────────────────────────────────────────────────

type cacheEntry struct {
	value     string
	expiresAt time.Time
}

type configService struct {
	pool   *pgxpool.Pool
	encKey []byte
	mu     sync.RWMutex
	cache  map[string]cacheEntry // protected by mu
}

// New creates a ConfigService. encKey must be a 32-byte AES-256 key obtained
// from crypto.ParseKey(os.Getenv("CONFIG_ENCRYPTION_KEY")).
func New(pool *pgxpool.Pool, encKey []byte) Service {
	return &configService{
		pool:   pool,
		encKey: encKey,
		cache:  make(map[string]cacheEntry),
	}
}

// Get returns the decrypted config value, using the 30 s cache when possible.
func (s *configService) Get(ctx context.Context, key string) (string, error) {
	// Fast path: read lock, check cache freshness
	s.mu.RLock()
	if entry, ok := s.cache[key]; ok && time.Now().Before(entry.expiresAt) {
		s.mu.RUnlock()
		return entry.value, nil
	}
	s.mu.RUnlock()
	// Slow path: query DB, then upgrade to write lock to update cache
	val, err := s.fetchOne(ctx, key)
	if err != nil {
		return "", err
	}
	s.mu.Lock()
	s.cache[key] = cacheEntry{value: val, expiresAt: time.Now().Add(cacheTTL)}
	s.mu.Unlock()
	return val, nil
}

// GetMany returns multiple values; uncached keys are fetched in a single query.
func (s *configService) GetMany(ctx context.Context, keys []string) (map[string]string, error) {
	result := make(map[string]string, len(keys))
	var missing []string
	s.mu.RLock()
	for _, k := range keys {
		if entry, ok := s.cache[k]; ok && time.Now().Before(entry.expiresAt) {
			result[k] = entry.value
		} else {
			missing = append(missing, k)
		}
	}
	s.mu.RUnlock()
	if len(missing) == 0 {
		return result, nil
	}
	// Fetch missing keys with a single IN query
	rows, err := s.pool.Query(ctx,
		`SELECT key, value FROM system_configs WHERE key = ANY($1)`, missing)
	if err != nil {
		return nil, fmt.Errorf("config.GetMany query: %w", err)
	}
	defer rows.Close()
	s.mu.Lock()
	defer s.mu.Unlock()
	for rows.Next() {
		var k, encVal string
		if err := rows.Scan(&k, &encVal); err != nil {
			return nil, fmt.Errorf("config.GetMany scan: %w", err)
		}
		plain, err := crypto.Decrypt(s.encKey, encVal)
		if err != nil {
			return nil, fmt.Errorf("config.GetMany decrypt %q: %w", k, err)
		}
		s.cache[k] = cacheEntry{value: plain, expiresAt: time.Now().Add(cacheTTL)}
		result[k] = plain
	}
	return result, rows.Err()
}

// Set encrypts value and writes to DB, then evicts the cache entry.
func (s *configService) Set(ctx context.Context, key, value, updatedBy string) error {
	encrypted, err := crypto.Encrypt(s.encKey, value)
	if err != nil {
		return fmt.Errorf("config.Set encrypt %q: %w", key, err)
	}
	_, err = s.pool.Exec(ctx,
		`INSERT INTO system_configs (key, value, updated_by)
		 VALUES ($1, $2, $3)
		 ON CONFLICT (key) DO UPDATE
		   SET value = EXCLUDED.value,
		       updated_at = NOW(),
		       updated_by = EXCLUDED.updated_by`,
		key, encrypted, updatedBy,
	)
	if err != nil {
		return fmt.Errorf("config.Set upsert %q: %w", key, err)
	}
	s.Invalidate(key)
	return nil
}

// Preload fetches and decrypts all rows, warming the cache before first request.
func (s *configService) Preload(ctx context.Context) error {
	rows, err := s.pool.Query(ctx, `SELECT key, value FROM system_configs`)
	if err != nil {
		return fmt.Errorf("config.Preload query: %w", err)
	}
	defer rows.Close()
	s.mu.Lock()
	defer s.mu.Unlock()
	exp := time.Now().Add(cacheTTL)
	for rows.Next() {
		var k, encVal string
		if err := rows.Scan(&k, &encVal); err != nil {
			return fmt.Errorf("config.Preload scan: %w", err)
		}
		plain, err := crypto.Decrypt(s.encKey, encVal)
		if err != nil {
			// A decrypt failure means the encryption key is wrong. Fail fast.
			return fmt.Errorf("config.Preload decrypt %q: %w (check CONFIG_ENCRYPTION_KEY)", k, err)
		}
		s.cache[k] = cacheEntry{value: plain, expiresAt: exp}
	}
	return rows.Err()
}

// Invalidate evicts a key from the in-memory cache.
func (s *configService) Invalidate(key string) {
	s.mu.Lock()
	delete(s.cache, key)
	s.mu.Unlock()
}

// ── private helpers ───────────────────────────────────────────────────────────

func (s *configService) fetchOne(ctx context.Context, key string) (string, error) {
	var encVal string
	err := s.pool.QueryRow(ctx,
		`SELECT value FROM system_configs WHERE key = $1`, key,
	).Scan(&encVal)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", fmt.Errorf("%w: %q", ErrConfigNotFound, key)
		}
		return "", fmt.Errorf("config.Get query %q: %w", key, err)
	}
	return crypto.Decrypt(s.encKey, encVal)
}
