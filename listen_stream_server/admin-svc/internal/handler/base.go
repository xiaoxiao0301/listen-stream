// Package handler contains all HTTP handlers for admin-svc.
package handler

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"listen-stream/admin-svc/internal/repo"
	"listen-stream/admin-svc/internal/service"
	"listen-stream/shared/pkg/config"
	"listen-stream/shared/pkg/rdb"
)

// Base holds common dependencies shared by all admin-svc handlers.
type Base struct {
	q      repo.Querier
	rdb    *rdb.Client
	cfgSvc config.Service
	jwtSvc service.JWTService
	log    *zap.Logger
}

// NewBase creates a Base.
func NewBase(q repo.Querier, rdbClient *rdb.Client, cfgSvc config.Service, jwtSvc service.JWTService, log *zap.Logger) *Base {
	return &Base{q: q, rdb: rdbClient, cfgSvc: cfgSvc, jwtSvc: jwtSvc, log: log}
}

// jsonErr writes a JSON error response and aborts.
func jsonErr(c *gin.Context, status int, code, msg string) {
	c.AbortWithStatusJSON(status, gin.H{"code": code, "message": msg})
}

// ptrStr returns a *string from s.
func ptrStr(s string) *string { return &s }

// intPage parses page / size query params with sane defaults.
func intPage(c *gin.Context) (int32, int32) {
	page := int32(1)
	size := int32(20)
	if p := c.Query("page"); p != "" {
		var v int32
		if _, err := fmt.Sscan(p, &v); err == nil && v > 0 {
			page = v
		}
	}
	if s := c.Query("size"); s != "" {
		var v int32
		if _, err := fmt.Sscan(s, &v); err == nil && v > 0 && v <= 100 {
			size = v
		}
	}
	return page, size
}

// okJSON sends 200 JSON.
func okJSON(c *gin.Context, data gin.H) { c.JSON(http.StatusOK, data) }
