// Command server is the entry point for sync-svc.
//
// sync-svc responsibilities:
//   - User data sync (favorites, history, playlists, progress)
//   - WebSocket hub for real-time push notifications
//   - Cookie refresh cron job
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

	"listen-stream/sync-svc/internal/cron"
	"listen-stream/sync-svc/internal/handler"
	syncmw "listen-stream/sync-svc/internal/middleware"
	"listen-stream/sync-svc/internal/repo"
	"listen-stream/sync-svc/internal/ws"
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

	// ── 3. PostgreSQL ─────────────────────────────────────────────────────────
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
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	querier := repo.New(pool)
	// ws.New is the Hub constructor (package-level New convention)
	hub := ws.New(rdbClient, logger)
	go hub.Start(ctx)

	cookieCron := cron.New(cfgSvc, rdbClient, logger)
	if err := cookieCron.Start(ctx); err != nil {
		logger.Warn("cookie cron start failed (non-fatal)", zap.Error(err))
	}

	base := handler.NewBase(querier, rdbClient, hub, logger)

	// ── 7. HTTP routes ─────────────────────────────────────────────────────────
	r := gin.New()
	r.Use(gin.Recovery())

	// WebSocket endpoint (auth via JWT — Bearer or ?token= — using same RequireUser middleware)
	wsHandler := ws.NewWSHandler(hub, cfgSvc, logger)
	wsGroup := r.Group("", syncmw.RequireUser(cfgSvc))
	wsHandler.Register(wsGroup)

	api := r.Group("/api", syncmw.RequireUser(cfgSvc))
	{
		handler.NewFavoritesHandler(base).Register(api)
		handler.NewHistoryHandler(base).Register(api)
		handler.NewPlaylistHandler(base).Register(api)
		handler.NewSyncHandler(base).Register(api)
		handler.NewDeviceHandler(base).Register(api)
	}

	// ── 8. Serve ───────────────────────────────────────────────────────────────
	addr := envOr("LISTEN_ADDR", ":8003")
	srv := &http.Server{Addr: addr, Handler: r}

	go func() {
		logger.Info("sync-svc listening", zap.String("addr", addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("shutting down sync-svc")

	cancel() // stop hub and cron

	shutCtx, shutCancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer shutCancel()
	if err := srv.Shutdown(shutCtx); err != nil {
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
