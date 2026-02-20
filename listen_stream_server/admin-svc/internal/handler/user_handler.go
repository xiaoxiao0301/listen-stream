// Package handler — user_handler manages user/device administration (Prompt B.4).
package handler

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	mw "listen-stream/admin-svc/internal/middleware"
	"listen-stream/admin-svc/internal/repo"
	"listen-stream/shared/pkg/rdb"
)

// UserHandler manages user and device endpoints.
type UserHandler struct{ *Base }

// NewUserHandler creates a UserHandler.
func NewUserHandler(b *Base) *UserHandler { return &UserHandler{b} }

// Register mounts user/device routes; all require RequireAdmin.
func (h *UserHandler) Register(rg *gin.RouterGroup) {
	auth := mw.RequireAdmin(h.jwtSvc)
	rg.GET("", auth, h.listUsers)
	rg.PUT("/:id/role", auth, mw.RequireRole("SUPER_ADMIN"), h.setUserRole)
	rg.PUT("/:id/status", auth, h.setUserStatus)
}

// listUsers returns a paginated, phone-filterable user list.
//
//	GET /admin/users?page=&size=&phone=
func (h *UserHandler) listUsers(c *gin.Context) {
	page, size := intPage(c)
	phone := c.Query("phone")

	ctx := c.Request.Context()
	total, err := h.q.CountUsers(ctx)
	if err != nil {
		h.log.Error("count users", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	users, err := h.q.ListUsers(ctx, repo.ListUsersParams{
		Limit:  size,
		Offset: (page - 1) * size,
		Phone:  phone,
	})
	if err != nil {
		h.log.Error("list users", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": users, "total": total, "page": page, "size": size})
}

// setUserRole changes a user's app role (SUPER_ADMIN only).
//
//	PUT /admin/users/:id/role   body: { role: "USER"|"ADMIN"|"VIP" }
func (h *UserHandler) setUserRole(c *gin.Context) {
	userID := c.Param("id")
	var req struct {
		Role repo.UserRole `json:"role" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		jsonErr(c, http.StatusBadRequest, "INVALID_REQUEST", err.Error())
		return
	}
	ctx := c.Request.Context()
	claims := mw.GetAdminClaims(c)
	if err := h.q.SetUserRole(ctx, repo.SetUserRoleParams{ID: userID, Role: req.Role}); err != nil {
		h.log.Error("set user role", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	go auditLog(context.Background(), h.q, claims.Subject, "USER_ROLE_CHANGED",
		ptrStr(userID), nil, ptrStr(string(req.Role)), c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"user_id": userID, "role": req.Role})
}

// setUserStatus enables or disables a user account.
// When disabling: active RTs are revoked and each device gets a kicked WS message.
//
//	PUT /admin/users/:id/status   body: { disabled: true|false }
func (h *UserHandler) setUserStatus(c *gin.Context) {
	userID := c.Param("id")
	var req struct {
		Disabled bool `json:"disabled"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		jsonErr(c, http.StatusBadRequest, "INVALID_REQUEST", err.Error())
		return
	}

	ctx := c.Request.Context()
	claims := mw.GetAdminClaims(c)

	// Guard: super admin cannot disable themselves
	if claims.Subject == userID && req.Disabled {
		jsonErr(c, http.StatusForbidden, "CANNOT_DISABLE_SELF", "cannot disable your own account")
		return
	}

	if err := h.q.SetUserDisabled(ctx, repo.SetUserDisabledParams{ID: userID, Disabled: req.Disabled}); err != nil {
		h.log.Error("set user disabled", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}

	// If disabling: revoke all device sessions and notify via WS
	if req.Disabled {
		devices, err := h.q.ListUserDevices(ctx, userID)
		if err != nil {
			h.log.Warn("list user devices for revoke", zap.String("user", userID), zap.Error(err))
		} else {
			for _, d := range devices {
				h.rdb.Del(ctx, rdb.KeyRT(d.DeviceID))
				msg, _ := json.Marshal(map[string]interface{}{
					"event": "device.kicked",
					"data":  map[string]string{"device_id": d.DeviceID, "reason": "admin_disabled"},
				})
				if err := h.rdb.Publish(ctx, rdb.KeyWSChannel(userID), string(msg)); err != nil {
					h.log.Warn("publish kicked", zap.String("device", d.DeviceID), zap.Error(err))
				}
			}
		}
	}

	action := "USER_ENABLED"
	if req.Disabled {
		action = "USER_DISABLED"
	}
	go auditLog(context.Background(), h.q, claims.Subject, action, ptrStr(userID), nil, nil, c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"user_id": userID, "disabled": req.Disabled})
}
