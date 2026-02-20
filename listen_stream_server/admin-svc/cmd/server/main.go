// admin-svc/cmd/server/main.go - HTTP server entry point for the admin service.
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

	"listen-stream/admin-svc/internal/handler"
	mw "listen-stream/admin-svc/internal/middleware"
	"listen-stream/admin-svc/internal/repo"
	"listen-stream/admin-svc/internal/service"
	sharedConfig "listen-stream/shared/pkg/config"
	"listen-stream/shared/pkg/crypto"
	"listen-stream/shared/pkg/rdb"
)

func main() {
	// ── 0. Load .env (optional) ────────────────────────────────────────────────
	_ = godotenv.Load()

	// ── 1. Logger ──────────────────────────────────────────────────────────────
	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatalf("init logger: %v", err)
	}
	defer logger.Sync()

	// ── 2. Postgres ────────────────────────────────────────────────────────────
	pool, err := pgxpool.New(context.Background(), mustEnv("DATABASE_URL"))
	if err != nil {
		logger.Fatal("pgxpool.New", zap.Error(err))
	}
	defer pool.Close()

	// ── 3. Redis ───────────────────────────────────────────────────────────────
	rdbClient := rdb.New(mustEnv("REDIS_URL"))
	if err := rdbClient.Ping(context.Background()); err != nil {
		logger.Fatal("redis ping", zap.Error(err))
	}

	// ── 4. Config service ──────────────────────────────────────────────────────
	encKey, err := crypto.ParseKey(mustEnv("CONFIG_ENCRYPTION_KEY"))
	if err != nil {
		logger.Fatal("parse CONFIG_ENCRYPTION_KEY", zap.Error(err))
	}
	cfgSvc := sharedConfig.New(pool, encKey)
	if err := cfgSvc.Preload(context.Background()); err != nil {
		logger.Fatal("config preload", zap.Error(err))
	}

	// ── 5. sqlc repository ─────────────────────────────────────────────────────
	q := repo.New(pool)

	// ── 6. Services ────────────────────────────────────────────────────────────
	jwtSvc := service.NewJWTService(cfgSvc)

	// ── 7. Handler base ────────────────────────────────────────────────────────
	base := handler.NewBase(q, rdbClient, cfgSvc, jwtSvc, logger)

	// ── 8. Gin router ──────────────────────────────────────────────────────────
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(accessLogger(logger))

	// Health check (no auth)
	r.GET("/health", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status": "ok"}) })

	// Public setup endpoints (no auth — bootstrap only)
	setupH := handler.NewSetupHandler(base)
	setup := r.Group("/admin/setup")
	setupH.Register(setup)

	// Auth endpoints (login is public; logout injects its own RequireAdmin via Register)
	authH := handler.NewAdminAuthHandler(base)
	authH.Register(r.Group("/admin/auth"))

	// Authenticated admin API
	api := r.Group("/admin", mw.RequireAdmin(jwtSvc))

	configH := handler.NewConfigHandler(base)
	configH.Register(api.Group("/config"))

	userH := handler.NewUserHandler(base)
	userH.Register(api.Group("/users"))

	deviceH := handler.NewDeviceHandler(base)
	deviceH.Register(api.Group("/devices"))

	logH := handler.NewLogHandler(base)
	logH.Register(api.Group("/logs"))

	statsH := handler.NewStatsHandler(base)
	statsH.Register(api.Group("/stats"))

	// ── 9. Start server with graceful shutdown ─────────────────────────────────
	port := getEnv("PORT", "8004")
	srv := &http.Server{Addr: ":" + port, Handler: r}

	go func() {
		logger.Info("admin-svc started", zap.String("port", port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("ListenAndServe", zap.Error(err))
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("shutting down admin-svc...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logger.Error("server shutdown", zap.Error(err))
	}
	logger.Info("admin-svc stopped")
}

// accessLogger is a minimal zap access-log middleware.
func accessLogger(log *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		log.Info("access",
			zap.String("method", c.Request.Method),
			zap.String("path", c.Request.URL.Path),
			zap.Int("status", c.Writer.Status()),
			zap.Duration("latency", time.Since(start)),
			zap.String("ip", c.ClientIP()),
		)
	}
}

func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("required env %s is not set", key)
	}
	return v
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
