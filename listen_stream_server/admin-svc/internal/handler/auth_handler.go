// Package handler — auth_handler implements admin login and logout (Prompt B.1).
//
// Login flow:
//  1. Brute-force guard: KeyAdminFail counter in Redis (max 5, 15-min window)
//  2. GetAdminByUsername → row not found = INVALID_CREDENTIALS (don't leak info)
//  3. Argon2id password verification
//  4. TOTP verification (if TotpSecret set)
//  5. Clear fail counter
//  6. Sign Admin AT with ADMIN_JWT_SECRET
//  7. Write ADMIN_LOGIN operation log
//
// Admin sessions have NO Refresh Token; expiry requires re-login.
package handler

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/xlzd/gotp"
	"go.uber.org/zap"

	mw "listen-stream/admin-svc/internal/middleware"
	"listen-stream/admin-svc/internal/repo"
	svc "listen-stream/admin-svc/internal/service"
	"listen-stream/shared/pkg/rdb"
)

const (
	maxFailAttempts = 5
	lockDuration    = 15 * time.Minute
)

// AdminAuthHandler handles admin authentication endpoints.
type AdminAuthHandler struct{ *Base }

// NewAdminAuthHandler creates an AdminAuthHandler.
func NewAdminAuthHandler(b *Base) *AdminAuthHandler { return &AdminAuthHandler{b} }

// Register mounts auth routes on rg.
func (h *AdminAuthHandler) Register(rg *gin.RouterGroup) {
	rg.POST("/login", h.login)
	rg.POST("/logout", mw.RequireAdmin(h.jwtSvc), h.logout)
}

// login authenticates an admin and returns an Access Token.
func (h *AdminAuthHandler) login(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required"`
		Password string `json:"password" binding:"required"`
		TOTPCode string `json:"totp_code"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		jsonErr(c, http.StatusBadRequest, "INVALID_REQUEST", err.Error())
		return
	}
	ctx := c.Request.Context()

	// 1. Brute-force guard
	failKey := rdb.KeyAdminFail(req.Username)
	rawFail, _ := h.rdb.Get(ctx, failKey)
	failCount, _ := strconv.Atoi(rawFail)
	if failCount >= maxFailAttempts {
		ttl, _ := h.rdb.TTL(ctx, failKey)
		c.JSON(http.StatusTooManyRequests, gin.H{
			"code":      "ACCOUNT_LOCKED",
			"unlock_at": time.Now().Add(ttl).Unix(),
		})
		return
	}

	recordFail := func() {
		_ = h.rdb.Set(ctx, failKey, strconv.Itoa(failCount+1), lockDuration)
		jsonErr(c, http.StatusUnauthorized, "INVALID_CREDENTIALS", "invalid username or password")
	}

	// 2. Lookup admin
	admin, err := h.q.GetAdminByUsername(ctx, req.Username)
	if err != nil {
		recordFail()
		return
	}
	if admin.Disabled {
		jsonErr(c, http.StatusForbidden, "ACCOUNT_DISABLED", "account is disabled")
		return
	}

	// 3. Argon2id verification
	if !svc.VerifyPassword(req.Password, admin.PasswordHash) {
		recordFail()
		return
	}

	// 4. TOTP
	if admin.TotpSecret != nil {
		if req.TOTPCode == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"code": "TOTP_REQUIRED"})
			return
		}
		if !gotp.NewDefaultTOTP(*admin.TotpSecret).Verify(req.TOTPCode, time.Now().Unix()) {
			jsonErr(c, http.StatusUnauthorized, "INVALID_TOTP", "invalid TOTP code")
			return
		}
	}

	// 5. Clear fail counter
	h.rdb.Del(ctx, failKey)

	// 6. Sign AT
	at, err := h.jwtSvc.SignAdminAccessToken(ctx, admin.ID, admin.Username, string(admin.Role))
	if err != nil {
		h.log.Error("sign admin AT", zap.Error(err))
		jsonErr(c, http.StatusInternalServerError, "INTERNAL_ERROR", "failed to sign token")
		return
	}
	ttl, _ := h.jwtSvc.AccessTokenTTL(ctx)

	// 7. Audit log (fire-and-forget)
	go auditLog(context.Background(), h.q, admin.ID, "ADMIN_LOGIN", nil, nil, nil, c.ClientIP())

	c.JSON(http.StatusOK, gin.H{
		"access_token": at,
		"expires_in":   ttl,
	})
}

func (h *AdminAuthHandler) logout(c *gin.Context) {
	claims := mw.GetAdminClaims(c)
	if claims != nil {
		go auditLog(context.Background(), h.q, claims.Subject, "ADMIN_LOGOUT", nil, nil, nil, c.ClientIP())
	}
	c.JSON(http.StatusOK, gin.H{"message": "logged out"})
}

// auditLog writes an operation_log record asynchronously.
func auditLog(ctx context.Context, q repo.Querier, adminID, action string, targetID, before, after *string, ip string) {
	_, _ = q.CreateOperationLog(ctx, repo.CreateOperationLogParams{
		AdminID:   adminID,
		Action:    action,
		TargetID:  targetID,
		BeforeVal: before,
		AfterVal:  after,
		Ip:        ip,
	})
}
