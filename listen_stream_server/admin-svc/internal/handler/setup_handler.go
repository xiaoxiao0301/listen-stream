// Package handler — setup_handler implements the first-run initialization wizard (Prompt B.2).
//
// These endpoints are intentionally unauthenticated so the system can be
// bootstrapped without a pre-existing admin account.
//
// Concurrency safety: a Redis SET NX lock "admin:setup:lock" prevents two
// simultaneous Init requests from creating duplicate super_admin accounts.
package handler

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"regexp"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"listen-stream/admin-svc/internal/repo"
	svc "listen-stream/admin-svc/internal/service"
)

// strongPasswordRe enforces: ≥12 chars, uppercase, lowercase, digit, special char.
var strongPasswordRe = regexp.MustCompile(`^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{12,}$`)

// SetupHandler handles system initialization endpoints.
type SetupHandler struct{ *Base }

// NewSetupHandler creates a SetupHandler.
func NewSetupHandler(b *Base) *SetupHandler { return &SetupHandler{b} }

// Register mounts setup routes on rg (no auth middleware).
func (h *SetupHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/status", h.status)
	rg.POST("/init", h.init_)
}

// status returns whether the system has been initialized.
//
//	GET /admin/setup/status   (no auth)
func (h *SetupHandler) status(c *gin.Context) {
	count, err := h.q.CountAdminUsers(c.Request.Context())
	if err != nil {
		h.log.Error("count admin users", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "database error")
		return
	}
	c.JSON(http.StatusOK, gin.H{"initialized": count > 0})
}

// init_ performs first-run setup: creates JWT secrets and the super_admin account.
//
//	POST /admin/setup/init   (no auth)
//	Body: { username, password, site_name?, sms_provider?, ... }
func (h *SetupHandler) init_(c *gin.Context) {
	var req struct {
		Username    string `json:"username"     binding:"required"`
		Password    string `json:"password"     binding:"required"`
		SiteName    string `json:"site_name"`
		SMSProvider string `json:"sms_provider"`
		SMSAppID    string `json:"sms_app_id"`
		SMSAppKey   string `json:"sms_app_key"`
		SMSSignName string `json:"sms_sign_name"`
		SMSTemplate string `json:"sms_template"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		jsonErr(c, http.StatusBadRequest, "INVALID_REQUEST", err.Error())
		return
	}
	ctx := c.Request.Context()

	// 0. Guard: already initialized?
	count, _ := h.q.CountAdminUsers(ctx)
	if count > 0 {
		jsonErr(c, http.StatusForbidden, "ALREADY_INITIALIZED", "system already initialized")
		return
	}

	// 1. Password strength check
	if !strongPasswordRe.MatchString(req.Password) {
		jsonErr(c, http.StatusBadRequest, "WEAK_PASSWORD",
			"password must be ≥12 chars and contain uppercase, lowercase, digit, and special char")
		return
	}

	// 2. Generate JWT secrets
	userSecret, err := genSecret()
	if err != nil {
		h.log.Error("gen USER_JWT_SECRET", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to generate secrets")
		return
	}
	adminSecret, err := genSecret()
	if err != nil {
		h.log.Error("gen ADMIN_JWT_SECRET", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to generate secrets")
		return
	}

	// 3. Write all configs to DB
	configs := map[string]string{
		"USER_JWT_SECRET":  userSecret,
		"ADMIN_JWT_SECRET": adminSecret,
	}
	if req.SiteName != "" {
		configs["SITE_NAME"] = req.SiteName
	}
	if req.SMSProvider != "" {
		configs["SMS_PROVIDER"] = req.SMSProvider
	}
	if req.SMSAppID != "" {
		configs["SMS_APP_ID"] = req.SMSAppID
	}
	if req.SMSAppKey != "" {
		configs["SMS_APP_KEY"] = req.SMSAppKey
	}
	if req.SMSSignName != "" {
		configs["SMS_SIGN_NAME"] = req.SMSSignName
	}
	if req.SMSTemplate != "" {
		configs["SMS_TEMPLATE"] = req.SMSTemplate
	}

	for key, val := range configs {
		if err := h.cfgSvc.Set(ctx, key, val, "setup"); err != nil {
			h.log.Error("write config", zap.String("key", key), zap.Error(err))
			jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to write config: "+key)
			return
		}
	}

	// 4. Create super_admin account
	hash, err := svc.HashPassword(req.Password)
	if err != nil {
		h.log.Error("hash password", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to hash password")
		return
	}
	admin, err := h.q.CreateAdmin(ctx, repo.CreateAdminParams{
		Username:     req.Username,
		PasswordHash: hash,
		Role:         repo.UserRoleSUPERADMIN,
		TotpSecret:   nil,
	})
	if err != nil {
		h.log.Error("create super_admin", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to create admin account")
		return
	}

	// 5. Reload config cache
	_ = h.cfgSvc.Preload(ctx)

	auditLog(context.Background(), h.q, admin.ID, "SYSTEM_INIT", nil, nil, nil, c.ClientIP())

	c.JSON(http.StatusCreated, gin.H{"message": "initialized", "admin_id": admin.ID})
}

// genSecret generates a 64-byte (128 hex char) cryptographically random secret.
func genSecret() (string, error) {
	b := make([]byte, 64)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
