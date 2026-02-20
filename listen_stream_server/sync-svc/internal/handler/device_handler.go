package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"listen-stream/shared/pkg/rdb"
	"listen-stream/sync-svc/internal/ws"
	"go.uber.org/zap"
)

// DeviceHandler exposes device list and revoke endpoints for the end user.
type DeviceHandler struct{ *Base }

// NewDeviceHandler creates a DeviceHandler.
func NewDeviceHandler(b *Base) *DeviceHandler { return &DeviceHandler{b} }

// Register mounts device routes.
func (h *DeviceHandler) Register(rg *gin.RouterGroup) {
	rg.GET("",     h.list)
	rg.DELETE("/:deviceId", h.revoke)
}

// list returns all devices for the current user, newest first.
func (h *DeviceHandler) list(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	devices, err := h.q.ListUserDevices(ctx, userID)
	if err != nil {
		h.log.Error("list devices", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"devices": devices})
}

// revoke deletes a device and sends a device.kicked event to it.
func (h *DeviceHandler) revoke(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	currentDevice := c.GetString("device_id")
	targetDevice := c.Param("deviceId")
	if targetDevice == currentDevice {
		c.JSON(http.StatusBadRequest, gin.H{"code": "CANNOT_REVOKE_CURRENT", "message": "use logout to revoke current device"})
		return
	}
	// Verify device belongs to user
	device, err := h.q.GetDeviceByDeviceID(ctx, targetDevice)
	if err != nil || device.UserID != userID {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND"})
		return
	}
	// Delete RT from Redis
	_ = h.rdb.Del(ctx, rdb.KeyRT(targetDevice))
	// Delete device row
	if err := h.q.DeleteDevice(ctx, targetDevice); err != nil {
		h.log.Error("revoke device", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	// Push kicked event to the target device's WebSocket connection
	h.hub.PushToUser(userID, ws.Message{
		Type: ws.EventDeviceKicked,
		Data: gin.H{"device_id": targetDevice},
	})
	c.JSON(http.StatusOK, gin.H{"revoked": targetDevice})
}
