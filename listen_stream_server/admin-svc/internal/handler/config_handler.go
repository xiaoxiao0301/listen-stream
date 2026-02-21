// Package handler — config_handler implements API/JWT/SMS configuration management (Prompt B.3).
//
// All GET responses mask secret values via util.MaskSecret.
// PUT /admin/config/jwt requires SUPER_ADMIN role.
// Rotating USER_JWT_SECRET bulk-deletes all RT keys and broadcasts
// a config.jwt_rotated WS event to all users.
package handler

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	mw "listen-stream/admin-svc/internal/middleware"
	"listen-stream/admin-svc/internal/repo"
	"listen-stream/admin-svc/internal/util"
	"listen-stream/shared/pkg/rdb"
)

// ConfigHandler manages system configuration via admin API.
type ConfigHandler struct{ *Base }

// NewConfigHandler creates a ConfigHandler.
func NewConfigHandler(b *Base) *ConfigHandler { return &ConfigHandler{b} }

// Register mounts config routes. All require RequireAdmin; JWT update requires SUPER_ADMIN.
func (h *ConfigHandler) Register(rg *gin.RouterGroup) {
	auth := mw.RequireAdmin(h.jwtSvc)
	rg.GET("/api", auth, h.getAPIConfig)
	rg.PUT("/api", auth, h.updateAPIConfig)
	rg.POST("/api/test", auth, h.testAPIConnection)
	rg.GET("/jwt", auth, h.getJWTConfig)
	rg.PUT("/jwt", auth, mw.RequireRole("SUPER_ADMIN"), h.updateJWTConfig)
	rg.GET("/sms", auth, h.getSMSConfig)
	rg.PUT("/sms", auth, h.updateSMSConfig)
	rg.GET("/sms/records", auth, h.getSMSRecords)
	rg.DELETE("/sms/records", auth, h.clearSMSRecords)
}

// ── API config ────────────────────────────────────────────────────────────────

var apiConfigKeys = []string{"API_BASE_URL", "API_KEY", "COOKIE"}

func (h *ConfigHandler) getAPIConfig(c *gin.Context) {
	ctx := c.Request.Context()
	vals, err := h.cfgSvc.GetMany(ctx, apiConfigKeys)
	if err != nil {
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "config read failed")
		return
	}
	for _, k := range []string{"API_KEY", "COOKIE"} {
		if v, ok := vals[k]; ok {
			vals[k] = util.MaskSecret(v)
		}
	}
	c.JSON(http.StatusOK, vals)
}

func (h *ConfigHandler) updateAPIConfig(c *gin.Context) {
	var req map[string]string
	if err := c.ShouldBindJSON(&req); err != nil {
		jsonErr(c, http.StatusBadRequest, "INVALID_REQUEST", err.Error())
		return
	}
	ctx := c.Request.Context()
	claims := mw.GetAdminClaims(c)
	updatedBy := ""
	if claims != nil {
		updatedBy = claims.Username
	}
	allowed := map[string]bool{"API_BASE_URL": true, "API_KEY": true, "COOKIE": true, "COOKIE_REFRESH_CRON": true}
	for k, v := range req {
		if !allowed[k] {
			continue
		}
		// Trim whitespace from values to prevent common input errors
		v = strings.TrimSpace(v)
		if err := h.cfgSvc.Set(ctx, k, v, updatedBy); err != nil {
			h.log.Error("update api config", zap.String("key", k), zap.Error(err))
			jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to update "+k)
			return
		}
		go auditLog(context.Background(), h.q, claims.Subject, "CONFIG_UPDATE",
			ptrStr(k), ptrStr("[secret]"), ptrStr("[secret]"), c.ClientIP())
	}
	c.JSON(http.StatusOK, gin.H{"updated": len(req)})
}

// testAPIConnection sends a connectivity probe to the upstream music API.
func (h *ConfigHandler) testAPIConnection(c *gin.Context) {
	ctx := c.Request.Context()
	baseURL, _ := h.cfgSvc.Get(ctx, "API_BASE_URL")
	cookie, _ := h.cfgSvc.Get(ctx, "COOKIE")
	apiKey, _ := h.cfgSvc.Get(ctx, "API_KEY")
	if baseURL == "" {
		jsonErr(c, http.StatusBadRequest, "NOT_CONFIGURED", "API_BASE_URL is not set")
		return
	}

	start := time.Now()
	client := &http.Client{Timeout: 5 * time.Second}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, baseURL+"/recommend/banner", nil)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"success": false, "error": err.Error()})
		return
	}
	if cookie != "" {
		req.Header.Set("Cookie", cookie)
	}
	if apiKey != "" {
		req.Header.Set("X-Api-Key", apiKey)
	}
	resp, err := client.Do(req)
	latency := time.Since(start).Milliseconds()
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"ok": false, "latency_ms": latency, "error": err.Error()})
		return
	}
	defer resp.Body.Close()
	c.JSON(http.StatusOK, gin.H{
		"ok":          resp.StatusCode < 400,
		"status_code": resp.StatusCode,
		"latency_ms":  latency,
	})
}

// ── JWT config ────────────────────────────────────────────────────────────────

var jwtConfigKeys = []string{"USER_JWT_SECRET", "ADMIN_JWT_SECRET", "ACCESS_TOKEN_TTL", "REFRESH_TOKEN_TTL", "MAX_DEVICES"}

func (h *ConfigHandler) getJWTConfig(c *gin.Context) {
	ctx := c.Request.Context()
	vals, err := h.cfgSvc.GetMany(ctx, jwtConfigKeys)
	if err != nil {
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "config read failed")
		return
	}
	for _, k := range []string{"USER_JWT_SECRET", "ADMIN_JWT_SECRET"} {
		if v, ok := vals[k]; ok {
			vals[k] = util.MaskSecret(v)
		}
	}
	c.JSON(http.StatusOK, vals)
}

func (h *ConfigHandler) updateJWTConfig(c *gin.Context) {
	var req map[string]string
	if err := c.ShouldBindJSON(&req); err != nil {
		jsonErr(c, http.StatusBadRequest, "INVALID_REQUEST", err.Error())
		return
	}
	ctx := c.Request.Context()
	claims := mw.GetAdminClaims(c)
	updatedBy := claims.Username

	allowed := map[string]bool{
		"USER_JWT_SECRET":   true,
		"ADMIN_JWT_SECRET":  true,
		"ACCESS_TOKEN_TTL":  true,
		"REFRESH_TOKEN_TTL": true,
		"MAX_DEVICES":       true,
	}

	affectedSessions := int64(0)

	for k, v := range req {
		if !allowed[k] || v == "" {
			continue
		}
		// Trim whitespace from values
		v = strings.TrimSpace(v)

		if k == "USER_JWT_SECRET" {
			// Rotate USER_JWT_SECRET: revoke all RTs and broadcast WS event
			if err := h.cfgSvc.Set(ctx, k, v, updatedBy); err != nil {
				jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to rotate USER_JWT_SECRET")
				return
			}
			deleted, err := h.rdb.ScanDel(ctx, "rt:*")
			if err != nil {
				h.log.Warn("ScanDel rt:*", zap.Error(err))
			}
			affectedSessions = deleted
			go h.broadcastJWTRotated(ctx, deleted)
			go auditLog(context.Background(), h.q, claims.Subject, "JWT_SECRET_ROTATED",
				ptrStr(k), ptrStr("[密钥已更换]"), ptrStr("[密钥已更换]"), c.ClientIP())
			continue
		}

		if k == "ADMIN_JWT_SECRET" {
			// Rotate ADMIN_JWT_SECRET (no WS push — admin sessions log back in manually)
			if err := h.cfgSvc.Set(ctx, k, v, updatedBy); err != nil {
				jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to rotate ADMIN_JWT_SECRET")
				return
			}
			go auditLog(context.Background(), h.q, claims.Subject, "JWT_ADMIN_SECRET_ROTATED",
				ptrStr(k), ptrStr("[密钥已更换]"), ptrStr("[密钥已更换]"), c.ClientIP())
			continue
		}

		// Non-secret keys (TTL, MAX_DEVICES)
		if err := h.cfgSvc.Set(ctx, k, v, updatedBy); err != nil {
			h.log.Error("update jwt config", zap.String("key", k), zap.Error(err))
		}
	}

	c.JSON(http.StatusOK, gin.H{"affected_sessions": affectedSessions})
}

// broadcastJWTRotated sends a config.jwt_rotated event to every user's WS channel.
func (h *ConfigHandler) broadcastJWTRotated(ctx context.Context, affectedCount int64) {
	users, err := h.q.ListUsers(ctx, repo.ListUsersParams{Limit: 10000, Offset: 0, Phone: ""})
	if err != nil {
		h.log.Error("list users for jwt broadcast", zap.Error(err))
		return
	}
	msg, _ := json.Marshal(map[string]interface{}{
		"event": "config.jwt_rotated",
		"data":  map[string]interface{}{"affected_sessions": affectedCount},
	})
	for _, u := range users {
		if err := h.rdb.Publish(ctx, rdb.KeyWSChannel(u.ID), string(msg)); err != nil {
			h.log.Warn("publish jwt_rotated", zap.String("user", u.ID), zap.Error(err))
		}
	}
}

// ── SMS config ────────────────────────────────────────────────────────────────

var smsConfigKeys = []string{"SMS_PROVIDER", "SMS_APP_ID", "SMS_APP_KEY", "SMS_SIGN_NAME", "SMS_TEMPLATE"}

func (h *ConfigHandler) getSMSConfig(c *gin.Context) {
	ctx := c.Request.Context()
	vals, err := h.cfgSvc.GetMany(ctx, smsConfigKeys)
	if err != nil {
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "config read failed")
		return
	}
	if v, ok := vals["SMS_APP_KEY"]; ok {
		vals["SMS_APP_KEY"] = util.MaskSecret(v)
	}
	c.JSON(http.StatusOK, vals)
}

func (h *ConfigHandler) updateSMSConfig(c *gin.Context) {
	var req map[string]string
	if err := c.ShouldBindJSON(&req); err != nil {
		jsonErr(c, http.StatusBadRequest, "INVALID_REQUEST", err.Error())
		return
	}
	ctx := c.Request.Context()
	claims := mw.GetAdminClaims(c)
	allowed := map[string]bool{"SMS_PROVIDER": true, "SMS_APP_ID": true, "SMS_APP_KEY": true, "SMS_SIGN_NAME": true, "SMS_TEMPLATE": true}
	for k, v := range req {
		if !allowed[k] {
			continue
		}
		// Trim whitespace from values
		v = strings.TrimSpace(v)
		if err := h.cfgSvc.Set(ctx, k, v, claims.Username); err != nil {
			jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to update "+k)
			return
		}
	}
	c.JSON(http.StatusOK, gin.H{"updated": len(req)})
}

// ── SMS dev log records ──────────────────────────────────────────────────────────────────

// getSMSRecords returns the last 200 SMS codes sent in dev mode.
// Each entry is a JSON object {phone, code, sent_at}.
//
//	GET /admin/config/sms/records
func (h *ConfigHandler) getSMSRecords(c *gin.Context) {
	ctx := c.Request.Context()
	entries, err := h.rdb.ZRevRange(ctx, rdb.KeyDevSMSLog(), 0, 199)
	if err != nil {
		h.log.Error("get sms records", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	records := make([]map[string]string, 0, len(entries))
	for _, e := range entries {
		var m map[string]string
		if err := json.Unmarshal([]byte(e), &m); err == nil {
			records = append(records, m)
		}
	}
	c.JSON(http.StatusOK, gin.H{"data": records, "total": len(records)})
}

// clearSMSRecords deletes all dev-mode SMS log entries from Redis.
//
//	DELETE /admin/config/sms/records
func (h *ConfigHandler) clearSMSRecords(c *gin.Context) {
	if err := h.rdb.ZDel(c.Request.Context(), rdb.KeyDevSMSLog()); err != nil {
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	c.JSON(http.StatusOK, gin.H{"cleared": true})
}
