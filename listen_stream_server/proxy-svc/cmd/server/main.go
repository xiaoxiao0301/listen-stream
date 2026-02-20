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

	api := r.Group("/api", proxymw.RequireUser(cfgSvc))
	{
		handler.NewRecommendHandler(proxyHandler).Register(api)
		handler.NewPlaylistHandler(proxyHandler).Register(api)
		handler.NewSingerHandler(proxyHandler).Register(api)
		handler.NewRankingHandler(proxyHandler).Register(api)
		handler.NewRadioHandler(proxyHandler).Register(api)
		handler.NewMVHandler(proxyHandler).Register(api)
		handler.NewAlbumHandler(proxyHandler).Register(api)
		handler.NewSearchHandler(proxyHandler).Register(api)
		handler.NewLyricHandler(proxyHandler).Register(api)
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
