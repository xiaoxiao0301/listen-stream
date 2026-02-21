// Command server is the entry point for auth-svc.
//
// Startup sequence:
//  1. Load env (godotenv, optional .env)
//  2. Connect PostgreSQL (pgxpool) and Redis
//  3. Boot ConfigService and Preload
//  4. Wire application components
//  5. Register HTTP routes
//  6. Listen on :8001
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

	"listen-stream/auth-svc/internal/handler"
	"listen-stream/auth-svc/internal/repo"
	"listen-stream/auth-svc/internal/service"
	"listen-stream/auth-svc/internal/service/sms"
	"listen-stream/shared/pkg/config"
	"listen-stream/shared/pkg/crypto"
	"listen-stream/shared/pkg/rdb"
)

func main() {
	// ── 1. Load env ───────────────────────────────────────────────────────────
	_ = godotenv.Load() // ignore missing .env in production

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
	querier := repo.New(pool)
	jwtSvc := service.NewJWTService(cfgSvc)
	smsAdapter, err := sms.NewAdapter(context.Background(), cfgSvc)
	if err != nil {
		// SMS_PROVIDER not yet configured — fall back to dev-log adapter so
		// the login flow works out of the box during local development.
		// Verification codes will be printed to the auth-svc log instead of
		// being delivered via SMS.
		// For production, set SMS_PROVIDER=aliyun|tencent in the admin panel.
		logger.Warn("SMS adapter init failed, falling back to dev-log adapter (set SMS_PROVIDER in admin panel for production)", zap.Error(err))
		smsAdapter = sms.DevLogAdapter{}
	}
	smsSvc := service.NewSMSService(smsAdapter, rdbClient, logger)
	authHandler := handler.NewAuthHandler(jwtSvc, smsSvc, querier, rdbClient, cfgSvc, logger)

	// ── 7. HTTP routes ─────────────────────────────────────────────────────────
	r := gin.New()
	r.Use(gin.Recovery())
	r.GET("/health", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status": "ok"}) })
	authHandler.Register(r.Group("/auth"))

	// ── 8. Serve ───────────────────────────────────────────────────────────────
	addr := envOr("LISTEN_ADDR", ":8001")
	srv := &http.Server{Addr: addr, Handler: r}

	go func() {
		logger.Info("auth-svc listening", zap.String("addr", addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("shutting down auth-svc")

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
