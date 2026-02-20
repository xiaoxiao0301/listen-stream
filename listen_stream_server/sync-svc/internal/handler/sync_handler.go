package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
	"listen-stream/sync-svc/internal/repo"
)

// SyncHandler provides the /user/sync endpoint for incremental state sync.
type SyncHandler struct{ *Base }

// NewSyncHandler creates a SyncHandler.
func NewSyncHandler(b *Base) *SyncHandler { return &SyncHandler{b} }

// Register mounts the sync route.
func (h *SyncHandler) Register(rg *gin.RouterGroup) {
	rg.GET("", h.sync)
}

// sync returns all changes since the given Unix-millisecond timestamp.
//
// ?since=<unix_ms>  — required; returns empty datasets if omitted.
//
// Response shape:
//
//	{
//	  "favorites":         [...],
//	  "deleted_favorites": [...],
//	  "history":           [...],
//	  "playlists":         [...],
//	  "deleted_playlists": [...],
//	}
func (h *SyncHandler) sync(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")

	sinceMs, err := strconv.ParseInt(c.Query("since"), 10, 64)
	if err != nil || sinceMs <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "since (unix ms) required"})
		return
	}
	ts := pgtype.Timestamptz{Time: unixMsToTime(sinceMs), Valid: true}

	favs, _ := h.q.ListFavoritesSince(ctx, repo.ListFavoritesSinceParams{UserID: userID, CreatedAt: ts})
	deletedFavIDs, _ := h.q.ListDeletedFavoritesSince(ctx, repo.ListDeletedFavoritesSinceParams{
		UserID:    userID,
		DeletedAt: ts,
	})
	huist, _ := h.q.ListHistorySince(ctx, repo.ListHistorySinceParams{UserID: userID, PlayedAt: ts})
	playlists, _ := h.q.ListPlaylistsSince(ctx, repo.ListPlaylistsSinceParams{
		UserID:    userID,
		UpdatedAt: ts,
	})
	deletedPLIDs, _ := h.q.ListDeletedPlaylistsSince(ctx, repo.ListDeletedPlaylistsSinceParams{
		UserID:    userID,
		DeletedAt: ts,
	})

	c.JSON(http.StatusOK, gin.H{
		"favorites":         nilSlice(favs),
		"deleted_favorites": nilSlice(deletedFavIDs),
		"history":           nilSlice(huist),
		"playlists":         nilSlice(playlists),
		"deleted_playlists": nilSlice(deletedPLIDs),
	})
}

// nilSlice converts a nil slice to an empty slice so JSON returns [] not null.
func nilSlice[T any](s []T) []T {
	if s == nil {
		return []T{}
	}
	return s
}
