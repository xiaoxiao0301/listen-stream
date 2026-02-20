// Package handler — stats_handler provides admin overview statistics.
package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
	"go.uber.org/zap"

	mw "listen-stream/admin-svc/internal/middleware"
	"listen-stream/shared/pkg/rdb"
)

// StatsHandler serves admin overview stats.
type StatsHandler struct{ *Base }

// NewStatsHandler creates a StatsHandler.
func NewStatsHandler(b *Base) *StatsHandler { return &StatsHandler{b} }

// Register mounts stats routes.
func (h *StatsHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/overview", mw.RequireAdmin(h.jwtSvc), h.overview)
}

// overview returns aggregate system statistics.
//
//	GET /admin/stats/overview
func (h *StatsHandler) overview(c *gin.Context) {
	ctx := c.Request.Context()

	totalUsers, err := h.q.CountUsers(ctx)
	if err != nil {
		h.log.Error("count users", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	totalDevices, err := h.q.CountTotalDevices(ctx)
	if err != nil {
		h.log.Error("count devices", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	weekAgo := pgtype.Timestamptz{Time: time.Now().Add(-7 * 24 * time.Hour), Valid: true}
	activeUsers7d, err := h.q.CountActiveUsersSince(ctx, weekAgo)
	if err != nil {
		h.log.Warn("count active users", zap.Error(err))
	}

	// Cookie alert: non-empty value means an alert is active
	cookieAlertVal, _ := h.rdb.Get(ctx, rdb.KeyCookieAlert())
	cookieAlert := cookieAlertVal != ""

	c.JSON(http.StatusOK, gin.H{
		"total_users":      totalUsers,
		"total_devices":    totalDevices,
		"active_users_7d":  activeUsers7d,
		"cookie_alert":     cookieAlert,
	})
}
