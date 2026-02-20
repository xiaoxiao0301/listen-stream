// Package handler contains all HTTP handlers for sync-svc.
package handler

import (
	"go.uber.org/zap"
	"listen-stream/shared/pkg/rdb"
	"listen-stream/sync-svc/internal/repo"
	"listen-stream/sync-svc/internal/ws"
)

// Base holds dependencies shared by all sync-svc handlers.
type Base struct {
	q   repo.Querier
	rdb *rdb.Client
	hub *ws.Hub
	log *zap.Logger
}

// NewBase creates a Base with the given dependencies.
func NewBase(q repo.Querier, rdbClient *rdb.Client, hub *ws.Hub, log *zap.Logger) *Base {
	return &Base{q: q, rdb: rdbClient, hub: hub, log: log}
}

// userID reads the user ID from the Gin context (set by RequireUser middleware).
func userIDFromCtx(ctx interface{ GetString(string) string }) string {
	return ctx.GetString("user_id")
}
