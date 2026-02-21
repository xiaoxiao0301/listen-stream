// Command server is the entry point for proxy-svc.
//
// proxy-svc is a stateless reverse-proxy that:
//   - Authenticates requests using JWTs (no DB lookup — lightweight)
//   - Caches upstream API responses in Redis with per-endpoint TTLs
//   - Falls back to stale cache when the upstream is unavailable
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"go.uber.org/zap"

	"listen-stream/proxy-svc/internal/handler"
	proxymw "listen-stream/proxy-svc/internal/middleware"
	"listen-stream/proxy-svc/internal/upstream"
	"listen-stream/shared/pkg/config"
	"listen-stream/shared/pkg/crypto"
	"listen-stream/shared/pkg/rdb"
)

func main() {
	// ── 1. Load env ───────────────────────────────────────────────────────────
	_ = godotenv.Load()

	// ── 2. Logger ─────────────────────────────────────────────────────────────
	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatalf("init logger: %v", err)
	}
	defer logger.Sync() //nolint:errcheck

	// ── 3. PostgreSQL (for ConfigService) ─────────────────────────────────────
	dbURL := mustEnv("DATABASE_URL")
	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		logger.Fatal("connect postgres", zap.Error(err))
	}
	defer pool.Close()

	// ── 4. Redis ──────────────────────────────────────────────────────────────
	rdbClient := rdb.New(mustEnv("REDIS_URL"))
	defer rdbClient.Close()

	// ── 5. ConfigService ──────────────────────────────────────────────────────
	encKey, err := crypto.ParseKey(mustEnv("CONFIG_ENCRYPTION_KEY"))
	if err != nil {
		logger.Fatal("parse CONFIG_ENCRYPTION_KEY", zap.Error(err))
	}
	cfgSvc := config.New(pool, encKey)
	if err = cfgSvc.Preload(context.Background()); err != nil {
		logger.Warn("config preload failed (non-fatal)", zap.Error(err))
	}

	// ── 6. Application components ─────────────────────────────────────────────
	// NewProxyHandler wires the upstream client and Redis cache internally.
	upstreamClient := upstream.New(cfgSvc)
	proxyHandler := handler.NewProxyHandler(upstreamClient, rdbClient, logger)

	// ── 7. HTTP routes ─────────────────────────────────────────────────────────
	r := gin.New()
	r.Use(gin.Recovery())
	r.GET("/health", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status": "ok"}) })

	// Reverse proxy for auth-svc: forward /auth/* and /user/* to localhost:8001
	authURL := envOr("AUTH_SERVICE_URL", "http://localhost:8001")
	r.Any("/auth/*path", proxyToService(authURL, logger))
	r.Any("/user/*path", proxyToService(authURL, logger))

	api := r.Group("/api", proxymw.RequireUser(cfgSvc))
	{
		// Recommend endpoints under /api/recommend/*
		handler.NewRecommendHandler(proxyHandler).Register(api.Group("/recommend"))
		// Each resource gets its own sub-group to avoid path conflicts
		handler.NewPlaylistHandler(proxyHandler).Register(api.Group("/playlist"))
		handler.NewSingerHandler(proxyHandler).Register(api.Group("/artist"))
		handler.NewRankingHandler(proxyHandler).Register(api.Group("/ranking"))
		handler.NewRadioHandler(proxyHandler).Register(api.Group("/radio"))
		handler.NewMVHandler(proxyHandler).Register(api.Group("/mv"))
		handler.NewAlbumHandler(proxyHandler).Register(api.Group("/album"))
		handler.NewSearchHandler(proxyHandler).Register(api.Group("/search"))
		handler.NewLyricHandler(proxyHandler).Register(api.Group("/lyric"))
	}

	// ── 8. Serve ───────────────────────────────────────────────────────────────
	addr := envOr("LISTEN_ADDR", ":8002")
	srv := &http.Server{Addr: addr, Handler: r}

	go func() {
		logger.Info("proxy-svc listening", zap.String("addr", addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("shutting down proxy-svc")

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logger.Error("graceful shutdown failed", zap.Error(err))
	}
}

func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("required env var %s is not set", key)
	}
	return v
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

// proxyToService creates a reverse proxy handler that forwards requests to a backend service.
func proxyToService(targetURL string, logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Build target URL: targetURL + original path + query
		path := c.Param("path")
		fullPath := c.Request.URL.Path[:len(c.Request.URL.Path)-len(path)] + path
		targetReq := targetURL + fullPath
		if c.Request.URL.RawQuery != "" {
			targetReq += "?" + c.Request.URL.RawQuery
		}

		// Create proxy request
		req, err := http.NewRequestWithContext(c.Request.Context(), c.Request.Method, targetReq, c.Request.Body)
		if err != nil {
			logger.Error("proxy: create request", zap.Error(err))
			c.JSON(http.StatusBadGateway, gin.H{"code": "PROXY_ERROR"})
			return
		}

		// Copy headers
		for k, vv := range c.Request.Header {
			for _, v := range vv {
				req.Header.Add(k, v)
			}
		}

		// Forward request
		client := &http.Client{Timeout: 30 * time.Second}
		resp, err := client.Do(req)
		if err != nil {
			logger.Error("proxy: forward request", zap.Error(err), zap.String("target", targetReq))
			c.JSON(http.StatusBadGateway, gin.H{"code": "SERVICE_UNAVAILABLE"})
			return
		}
		defer resp.Body.Close()

		// Copy response headers
		for k, vv := range resp.Header {
			for _, v := range vv {
				c.Writer.Header().Add(k, v)
			}
		}

		// Copy response status and body
		c.Status(resp.StatusCode)
		_, _ = c.Writer.Write(mustReadAll(resp.Body))
	}
}

func mustReadAll(r interface{ Read([]byte) (int, error) }) []byte {
	buf := make([]byte, 0, 4096)
	tmp := make([]byte, 1024)
	for {
		n, err := r.Read(tmp)
		buf = append(buf, tmp[:n]...)
		if err != nil {
			break
		}
	}
	return buf
}
