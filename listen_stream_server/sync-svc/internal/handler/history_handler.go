package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"listen-stream/sync-svc/internal/repo"
	"listen-stream/sync-svc/internal/ws"
	"listen-stream/shared/pkg/rdb"
	"go.uber.org/zap"
)

// HistoryHandler manages listening history.
type HistoryHandler struct{ *Base }

// NewHistoryHandler creates a HistoryHandler.
func NewHistoryHandler(b *Base) *HistoryHandler { return &HistoryHandler{b} }

// Register mounts history routes.
func (h *HistoryHandler) Register(rg *gin.RouterGroup) {
	rg.GET("",                h.list)
	rg.POST("",               h.add)
	rg.GET("/progress",       h.getProgress)
	rg.POST("/progress",      h.updateProgress)
}

func (h *HistoryHandler) list(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "20"))
	if page < 1 { page = 1 }
	if size < 1 || size > 100 { size = 20 }
	items, err := h.q.ListHistory(ctx, repo.ListHistoryParams{
		UserID: userID,
		Limit:  int32(size),
		Offset: int32((page - 1) * size),
	})
	if err != nil {
		h.log.Error("list history", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	total, _ := h.q.CountHistory(ctx, userID)
	c.JSON(http.StatusOK, gin.H{"items": items, "total": total, "page": page, "size": size})
}

func (h *HistoryHandler) add(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	var body struct {
		SongMid  string `json:"song_mid"  binding:"required"`
		Progress int    `json:"progress"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_BODY", "message": err.Error()})
		return
	}
	rec, err := h.q.CreateHistory(ctx, repo.CreateHistoryParams{
		UserID:   userID,
		SongMid:  body.SongMid,
		Progress: int32(body.Progress),
	})
	if err != nil {
		h.log.Error("add history", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	// Trim to keep newest 500 records (best effort; errors are non-fatal)
	_ = h.q.TrimHistory(ctx, repo.TrimHistoryParams{UserID: userID, Offset: 500})
	_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(userID),
		mustJSON(ws.Message{Type: ws.EventHistoryUpdate, Data: rec}))
	c.JSON(http.StatusCreated, rec)
}

func (h *HistoryHandler) getProgress(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	songMid := c.Query("song_mid")
	if songMid == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "song_mid required"})
		return
	}
	row, err := h.q.GetSongProgress(ctx, repo.GetSongProgressParams{
		UserID:  userID,
		SongMid: songMid,
	})
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"progress": row.Progress, "played_at": row.PlayedAt.Time.Unix()})
}

func (h *HistoryHandler) updateProgress(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	var body struct {
		SongMid  string `json:"song_mid"  binding:"required"`
		Progress int    `json:"progress"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_BODY", "message": err.Error()})
		return
	}
	rec, err := h.q.UpdateSongProgress(ctx, repo.UpdateSongProgressParams{
		UserID:   userID,
		SongMid:  body.SongMid,
		Progress: int32(body.Progress),
	})
	if err != nil {
		h.log.Error("update progress", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	c.JSON(http.StatusOK, rec)
}
