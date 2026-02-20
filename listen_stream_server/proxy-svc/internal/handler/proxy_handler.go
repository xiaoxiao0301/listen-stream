// Package handler contains the core proxy dispatch logic and all route handlers.
package handler

import (
	"crypto/sha256"
	"fmt"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"listen-stream/proxy-svc/internal/cache"
	"listen-stream/proxy-svc/internal/upstream"
	"listen-stream/shared/pkg/rdb"
)

// ProxyHandler is the central proxy dispatcher.
// Each route handler embeds *ProxyHandler and delegates to handle().
type ProxyHandler struct {
	client *upstream.Client
	cache  *cache.ProxyCache
	log    *zap.Logger
}

// NewProxyHandler creates a ProxyHandler ready to serve requests.
func NewProxyHandler(client *upstream.Client, rdbClient *rdb.Client, log *zap.Logger) *ProxyHandler {
	return &ProxyHandler{
		client: client,
		cache:  cache.NewProxyCache(rdbClient),
		log:    log,
	}
}

// handle is the single dispatch point: cache lookup → upstream → cache write.
//
//  1. Normalise query params (sort keys + values alphabetically) and SHA-256
//     hash them to build a stable cache key.
//  2. Cache HIT  → set ETag header; return 304 on If-None-Match match, else 200.
//  3. Cache MISS with ttl > 0 → call upstream, cache response, return 200.
//  4. Cache MISS with ttl == 0 → forward directly, no cache write.
//  5. Upstream failure on a cached (possibly stale) path → return stale copy
//     with X-Cache: STALE header rather than propagating a 5xx.
func (h *ProxyHandler) handle(c *gin.Context, upstreamPath string, ttl time.Duration) {
	ctx := c.Request.Context()

	// ── 1. Build cache key ───────────────────────────────────────────────────
	cacheKey := ""
	if ttl > 0 {
		cacheKey = buildCacheKey(upstreamPath, c.Request.URL.RawQuery)
	}

	// ── 2. Cache lookup ──────────────────────────────────────────────────────
	if ttl > 0 {
		entry, err := h.cache.Get(ctx, cacheKey)
		if err == nil && entry != nil {
			c.Header("ETag", entry.ETag)
			c.Header("X-Cache", "HIT")
			if c.GetHeader("If-None-Match") == entry.ETag {
				c.Status(http.StatusNotModified)
				return
			}
			c.Data(http.StatusOK, "application/json; charset=utf-8", entry.Body)
			return
		}
	}

	// ── 3 / 4. Call upstream ─────────────────────────────────────────────────
	body, err := h.client.Do(ctx, upstreamPath, c.Request.URL.RawQuery)
	if err != nil {
		// ── 5. Stale fallback ─────────────────────────────────────────────
		if ttl > 0 {
			stale, serr := h.cache.GetStale(ctx, cacheKey)
			if serr == nil && stale != nil {
				h.log.Warn("upstream error, serving stale cache",
					zap.String("path", upstreamPath), zap.Error(err))
				c.Header("ETag", stale.ETag)
				c.Header("X-Cache", "STALE")
				c.Data(http.StatusOK, "application/json; charset=utf-8", stale.Body)
				return
			}
		}
		h.log.Error("upstream error", zap.String("path", upstreamPath), zap.Error(err))
		c.JSON(http.StatusBadGateway, gin.H{"code": "UPSTREAM_ERROR", "message": "upstream unavailable"})
		return
	}

	// ── ETag from body SHA-256 prefix ────────────────────────────────────────
	sum := sha256.Sum256(body)
	etag := fmt.Sprintf(`"%x"`, sum[:8])

	// ── Write cache ──────────────────────────────────────────────────────────
	if ttl > 0 {
		entry := &cache.Entry{Body: body, ETag: etag}
		_ = h.cache.Set(ctx, cacheKey, entry, ttl)
	}

	c.Header("ETag", etag)
	c.Header("X-Cache", "MISS")
	c.Data(http.StatusOK, "application/json; charset=utf-8", body)
}

// buildCacheKey returns a stable Redis key for (upstreamPath, rawQuery).
// Query parameters are sorted so ?a=1&b=2 and ?b=2&a=1 hash identically.
func buildCacheKey(upstreamPath, rawQuery string) string {
	normalised := normaliseQuery(rawQuery)
	h := sha256.Sum256([]byte(upstreamPath + "?" + normalised))
	return rdb.KeyProxyCache(upstreamPath, fmt.Sprintf("%x", h[:8]))
}

// normaliseQuery sorts query parameters for cache key stability.
func normaliseQuery(rawQuery string) string {
	if rawQuery == "" {
		return ""
	}
	parts := strings.Split(rawQuery, "&")
	sort.Strings(parts)
	return strings.Join(parts, "&")
}
