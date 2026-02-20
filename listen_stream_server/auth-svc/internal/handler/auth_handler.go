// Package handler implements the HTTP handlers for auth-svc.
package handler

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"fmt"
	"net/http"
	"regexp"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	goredis "github.com/redis/go-redis/v9"
	"go.uber.org/zap"

	"listen-stream/auth-svc/internal/middleware"
	"listen-stream/auth-svc/internal/repo"
	"listen-stream/auth-svc/internal/service"
	"listen-stream/shared/pkg/config"
	"listen-stream/shared/pkg/rdb"
)

var e164Regexp = regexp.MustCompile(`^\+[1-9]\d{6,14}$`)

const (
	cfgMaxDevices = "MAX_DEVICES"
	defaultMaxDev = 5
)

// AuthHandler holds all dependencies for auth endpoints.
type AuthHandler struct {
	jwtSvc  service.JWTService
	smsSvc  *service.SMSService
	querier repo.Querier
	rdb     *rdb.Client
	cfgSvc  config.Service
	log     *zap.Logger
}

// NewAuthHandler constructs an AuthHandler.
func NewAuthHandler(
	jwtSvc service.JWTService,
	smsSvc *service.SMSService,
	querier repo.Querier,
	rdbClient *rdb.Client,
	cfgSvc config.Service,
	log *zap.Logger,
) *AuthHandler {
	return &AuthHandler{
		jwtSvc:  jwtSvc,
		smsSvc:  smsSvc,
		querier: querier,
		rdb:     rdbClient,
		cfgSvc:  cfgSvc,
		log:     log,
	}
}

// Register mounts all auth routes on rg.
func (h *AuthHandler) Register(rg *gin.RouterGroup) {
	rg.POST("/sms/send", h.SendSMSCode)
	rg.POST("/sms/verify", h.VerifySMSCode)
	rg.POST("/refresh", h.Refresh)
	rg.POST("/logout", middleware.RequireUser(h.jwtSvc, h.querier), h.Logout)
	rg.GET("/devices", middleware.RequireUser(h.jwtSvc, h.querier), h.ListDevices)
	rg.DELETE("/devices/:deviceId", middleware.RequireUser(h.jwtSvc, h.querier), h.RevokeDevice)
}

// SendSMSCode handles POST /auth/sms/send.
func (h *AuthHandler) SendSMSCode(c *gin.Context) {
	var req struct {
		Phone string `json:"phone" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_PARAMS", "message": err.Error()})
		return
	}
	if !e164Regexp.MatchString(req.Phone) {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_PHONE"})
		return
	}
	err := h.smsSvc.SendCode(c.Request.Context(), req.Phone)
	switch {
	case err == nil:
		c.JSON(http.StatusOK, gin.H{"message": "ok"})
	case isRateLimited(err):
		var rl service.ErrRateLimited
		errors.As(err, &rl)
		c.JSON(http.StatusTooManyRequests, gin.H{"code": "RATE_LIMITED", "retry_after": rl.RetryAfter})
	default:
		h.log.Warn("sms send failed", zap.String("phone", req.Phone), zap.Error(err))
		c.JSON(http.StatusOK, gin.H{"message": "ok"})
	}
}

// VerifySMSCode handles POST /auth/sms/verify.
func (h *AuthHandler) VerifySMSCode(c *gin.Context) {
	var req struct {
		Phone    string `json:"phone"     binding:"required"`
		Code     string `json:"code"      binding:"required"`
		DeviceID string `json:"device_id"`
		Platform string `json:"platform"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_PARAMS", "message": err.Error()})
		return
	}
	ctx := c.Request.Context()
	if err := h.smsSvc.VerifyCode(ctx, req.Phone, req.Code); err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidCode):
			c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_CODE"})
		case errors.Is(err, service.ErrCodeExpired):
			c.JSON(http.StatusBadRequest, gin.H{"code": "CODE_EXPIRED"})
		default:
			h.log.Error("verify code error", zap.Error(err))
			c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR"})
		}
		return
	}
	user, err := h.querier.UpsertUser(ctx, req.Phone)
	if err != nil {
		h.log.Error("upsert user failed", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR"})
		return
	}
	deviceID := req.DeviceID
	if deviceID == "" {
		deviceID = newUUID()
	}
	platform := req.Platform
	if platform == "" {
		platform = "unknown"
	}
	maxDevStr, _ := h.cfgSvc.Get(ctx, cfgMaxDevices)
	maxDev, _ := strconv.Atoi(maxDevStr)
	if maxDev <= 0 {
		maxDev = defaultMaxDev
	}
	devCount, _ := h.querier.CountUserDevices(ctx, user.ID)
	if int(devCount) >= maxDev {
		if oldest, err := h.querier.GetOldestDevice(ctx, user.ID); err == nil {
			_ = h.rdb.Del(ctx, rdb.KeyRT(oldest.DeviceID))
			_ = h.querier.DeleteDevice(ctx, oldest.DeviceID)
			_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(user.ID), wsEvent("device.kicked", `"max_devices"`))
			h.log.Info("kicked oldest device", zap.String("user_id", user.ID), zap.String("device_id", oldest.DeviceID))
		}
	}
	at, err := h.jwtSvc.SignUserAccessToken(ctx, user.ID, deviceID, string(user.Role))
	if err != nil {
		h.log.Error("sign AT failed", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR"})
		return
	}
	rt, rtHash := h.jwtSvc.IssueRefreshToken()
	rtTTL, _ := h.jwtSvc.RefreshTokenTTL(ctx)
	atTTL, _ := h.jwtSvc.AccessTokenTTL(ctx)
	_, _ = h.rdb.SetNX(ctx, rdb.KeyRT(deviceID), rtHash, time.Duration(rtTTL)*time.Second)
	if _, err := h.querier.UpsertDevice(ctx, repo.UpsertDeviceParams{UserID: user.ID, DeviceID: deviceID, Platform: platform, RtHash: rtHash}); err != nil {
		h.log.Warn("upsert device failed", zap.Error(err))
	}
	c.JSON(http.StatusOK, gin.H{"access_token": at, "refresh_token": rt, "expires_in": atTTL, "device_id": deviceID})
}

// Refresh handles POST /auth/refresh (D-C atomic lock).
func (h *AuthHandler) Refresh(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
		DeviceID     string `json:"device_id"     binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_PARAMS", "message": err.Error()})
		return
	}
	ctx := c.Request.Context()
	sum := sha256.Sum256([]byte(req.RefreshToken))
	rtHash := hex.EncodeToString(sum[:])
	storedHash, err := h.rdb.GetDel(ctx, rdb.KeyRT(req.DeviceID))
	if errors.Is(err, goredis.Nil) {
		h.log.Warn("RT not found", zap.String("device_id", req.DeviceID))
		c.JSON(http.StatusUnauthorized, gin.H{"code": "TOKEN_REUSED"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR"})
		return
	}
	if subtle.ConstantTimeCompare([]byte(storedHash), []byte(rtHash)) != 1 {
		h.log.Warn("RT hash mismatch", zap.String("device_id", req.DeviceID))
		c.JSON(http.StatusUnauthorized, gin.H{"code": "TOKEN_REUSED"})
		return
	}
	device, err := h.querier.GetDeviceWithUser(ctx, req.DeviceID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "DEVICE_REVOKED"})
		return
	}
	if device.UserDisabled {
		c.JSON(http.StatusForbidden, gin.H{"code": "USER_DISABLED"})
		return
	}
	at, err := h.jwtSvc.SignUserAccessToken(ctx, device.UserID, device.DeviceID, string(device.UserRole))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR"})
		return
	}
	newRT, newRTHash := h.jwtSvc.IssueRefreshToken()
	rtTTL, _ := h.jwtSvc.RefreshTokenTTL(ctx)
	atTTL, _ := h.jwtSvc.AccessTokenTTL(ctx)
	_, _ = h.rdb.SetNX(ctx, rdb.KeyRT(device.DeviceID), newRTHash, time.Duration(rtTTL)*time.Second)
	_ = h.querier.UpdateDeviceRT(ctx, repo.UpdateDeviceRTParams{DeviceID: device.DeviceID, RtHash: newRTHash})
	c.JSON(http.StatusOK, gin.H{"access_token": at, "refresh_token": newRT, "expires_in": atTTL})
}

// Logout handles POST /auth/logout.
func (h *AuthHandler) Logout(c *gin.Context) {
	claims := middleware.GetUserClaims(c)
	if claims == nil {
		c.Status(http.StatusNoContent)
		return
	}
	ctx := c.Request.Context()
	_ = h.rdb.Del(ctx, rdb.KeyRT(claims.DeviceID))
	_ = h.querier.DeleteDevice(ctx, claims.DeviceID)
	c.Status(http.StatusNoContent)
}

// ListDevices handles GET /auth/devices.
func (h *AuthHandler) ListDevices(c *gin.Context) {
	claims := middleware.GetUserClaims(c)
	devices, err := h.querier.ListUserDevices(c.Request.Context(), claims.Subject)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": devices})
}

// RevokeDevice handles DELETE /auth/devices/:deviceId.
func (h *AuthHandler) RevokeDevice(c *gin.Context) {
	targetID := c.Param("deviceId")
	claims := middleware.GetUserClaims(c)
	ctx := c.Request.Context()
	device, err := h.querier.GetDeviceByDeviceID(ctx, targetID)
	if err != nil || device.UserID != claims.Subject {
		c.JSON(http.StatusNotFound, gin.H{"code": "DEVICE_NOT_FOUND"})
		return
	}
	_ = h.rdb.Del(ctx, rdb.KeyRT(targetID))
	_ = h.querier.DeleteDevice(ctx, targetID)
	_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(claims.Subject), wsEvent("device.kicked", `"user_revoke"`))
	c.Status(http.StatusNoContent)
}

func isRateLimited(err error) bool {
	var rl service.ErrRateLimited
	return errors.As(err, &rl)
}

func wsEvent(event, reasonJSON string) string {
	return fmt.Sprintf(`{"event":%q,"payload":{"reason":%s},"ts":%q}`, event, reasonJSON, time.Now().UTC().Format(time.RFC3339))
}

func newUUID() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}
