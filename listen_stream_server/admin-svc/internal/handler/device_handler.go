// Package handler — device_handler provides device-level admin control.
package handler

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	mw "listen-stream/admin-svc/internal/middleware"
	"listen-stream/shared/pkg/rdb"
)

// DeviceHandler manages device admin endpoints.
type DeviceHandler struct{ *Base }

// NewDeviceHandler creates a DeviceHandler.
func NewDeviceHandler(b *Base) *DeviceHandler { return &DeviceHandler{b} }

// Register mounts device routes; all require RequireAdmin.
func (h *DeviceHandler) Register(rg *gin.RouterGroup) {
	rg.DELETE("/:deviceId", mw.RequireAdmin(h.jwtSvc), h.deleteDevice)
}

// deleteDevice force-kicks a device: revokes RT, removes from DB, sends WS push.
//
//	DELETE /admin/devices/:deviceId
func (h *DeviceHandler) deleteDevice(c *gin.Context) {
	deviceID := c.Param("deviceId")
	ctx := c.Request.Context()
	claims := mw.GetAdminClaims(c)

	device, err := h.q.GetDeviceByDeviceID(ctx, deviceID)
	if err != nil {
		h.log.Error("get device", zap.String("id", deviceID), zap.Error(err))
		jsonErr(c, http.StatusNotFound, "DEVICE_NOT_FOUND", "device not found")
		return
	}

	// 1. Revoke refresh token
	h.rdb.Del(ctx, rdb.KeyRT(deviceID))

	// 2. Remove from DB
	if err := h.q.DeleteDevice(ctx, deviceID); err != nil {
		h.log.Error("delete device", zap.String("id", deviceID), zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}

	// 3. Notify user via WS
	msg, _ := json.Marshal(map[string]interface{}{
		"event": "device.kicked",
		"data":  map[string]string{"device_id": deviceID, "reason": "admin_force"},
	})
	if err := h.rdb.Publish(ctx, rdb.KeyWSChannel(device.UserID), string(msg)); err != nil {
		h.log.Warn("publish device kicked", zap.String("device", deviceID), zap.Error(err))
	}

	go auditLog(context.Background(), h.q, claims.Subject, "DEVICE_DELETED",
		ptrStr(deviceID), ptrStr(device.UserID), nil, c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"device_id": deviceID})
}
