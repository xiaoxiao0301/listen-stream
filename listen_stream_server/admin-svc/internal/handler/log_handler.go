// Package handler — log_handler serves operation and proxy audit logs.
package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	mw "listen-stream/admin-svc/internal/middleware"
	"listen-stream/admin-svc/internal/repo"
)

// LogHandler serves admin audit log endpoints.
type LogHandler struct{ *Base }

// NewLogHandler creates a LogHandler.
func NewLogHandler(b *Base) *LogHandler { return &LogHandler{b} }

// Register mounts log routes; all require RequireAdmin.
func (h *LogHandler) Register(rg *gin.RouterGroup) {
	auth := mw.RequireAdmin(h.jwtSvc)
	rg.GET("/operations", auth, h.listOperationLogs)
	rg.GET("/proxy", auth, h.listProxyLogs)
}

// listOperationLogs returns paginated admin operation logs.
//
//	GET /admin/logs/operations?page=&size=&type=
func (h *LogHandler) listOperationLogs(c *gin.Context) {
	page, size := intPage(c)
	action := c.Query("type") // maps ?type= to action filter

	ctx := c.Request.Context()
	total, err := h.q.CountOperationLogs(ctx, action)
	if err != nil {
		h.log.Error("count operation logs", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	logs, err := h.q.ListOperationLogs(ctx, repo.ListOperationLogsParams{
		Limit:  size,
		Offset: (page - 1) * size,
		Action: action,
	})
	if err != nil {
		h.log.Error("list operation logs", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": logs, "total": total, "page": page, "size": size})
}

// listProxyLogs is a stub; proxy_logs table is not in the current schema.
//
//	GET /admin/logs/proxy?page=&size=&status=
func (h *LogHandler) listProxyLogs(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"data": []interface{}{}, "total": 0})
}
