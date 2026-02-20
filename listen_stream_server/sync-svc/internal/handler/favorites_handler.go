package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
	"listen-stream/shared/pkg/rdb"
	"listen-stream/sync-svc/internal/repo"
	"listen-stream/sync-svc/internal/ws"
	"go.uber.org/zap"
)

// FavoritesHandler manages user favourites (add/remove/list).
type FavoritesHandler struct{ *Base }

// NewFavoritesHandler creates a FavoritesHandler.
func NewFavoritesHandler(b *Base) *FavoritesHandler { return &FavoritesHandler{b} }

// Register mounts the favourites routes onto rg.
func (h *FavoritesHandler) Register(rg *gin.RouterGroup) {
	rg.GET("",        h.list)
	rg.POST("",       h.add)
	rg.DELETE("/:id", h.remove)
}

// list returns the user's favourites (paginated, optional ?type= filter).
func (h *FavoritesHandler) list(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "20"))
	if page < 1 {
		page = 1
	}
	if size < 1 || size > 100 {
		size = 20
	}
	items, err := h.q.ListFavorites(ctx, repo.ListFavoritesParams{
		UserID: userID,
		Type:   c.Query("type"),
		Limit:  int32(size),
		Offset: int32((page - 1) * size),
	})
	if err != nil {
		h.log.Error("list favorites", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	total, _ := h.q.CountFavorites(ctx, repo.CountFavoritesParams{
		UserID: userID,
		Type:   c.Query("type"),
	})
	c.JSON(http.StatusOK, gin.H{"items": items, "total": total, "page": page, "size": size})
}

// add adds a favourite (idempotent: reactivates if previously soft-deleted).
func (h *FavoritesHandler) add(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	var body struct {
		Type     string `json:"type"     binding:"required"`
		TargetID string `json:"target_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_BODY", "message": err.Error()})
		return
	}
	fav, err := h.q.CreateFavorite(ctx, repo.CreateFavoriteParams{
		UserID:   userID,
		Type:     body.Type,
		TargetID: body.TargetID,
	})
	if err != nil {
		h.log.Error("add favorite", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	// Pub/Sub: notify other devices of the change.
	_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(userID),
		mustJSON(ws.Message{Type: ws.EventFavoriteChange, Data: fav}))
	c.JSON(http.StatusCreated, fav)
}

// remove soft-deletes a favourite by its row ID.
func (h *FavoritesHandler) remove(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	favID := c.Param("id")
	fav, err := h.q.SoftDeleteFavorite(ctx, repo.SoftDeleteFavoriteParams{
		ID:     favID,
		UserID: userID,
	})
	if err != nil {
		h.log.Error("remove favorite", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(userID),
		mustJSON(ws.Message{Type: ws.EventFavoriteChange, Data: gin.H{"deleted_id": fav.ID}}))
	c.JSON(http.StatusOK, gin.H{"deleted_id": fav.ID})
}

func toTimestamptz(unixMs int64) pgtype.Timestamptz {
	return pgtype.Timestamptz{
		Time:  time.UnixMilli(unixMs).UTC(),
		Valid: true,
	}
}
