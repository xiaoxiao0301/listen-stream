package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"listen-stream/shared/pkg/rdb"
	"listen-stream/sync-svc/internal/repo"
	"listen-stream/sync-svc/internal/ws"
	"go.uber.org/zap"
)

// PlaylistHandler manages user playlists and their songs.
type PlaylistHandler struct{ *Base }

// NewPlaylistHandler creates a PlaylistHandler.
func NewPlaylistHandler(b *Base) *PlaylistHandler { return &PlaylistHandler{b} }

// Register mounts playlist routes.
func (h *PlaylistHandler) Register(rg *gin.RouterGroup) {
	rg.GET("",                    h.list)
	rg.POST("",                   h.create)
	rg.PUT("/:id",                h.update)
	rg.DELETE("/:id",             h.delete)
	rg.GET("/:id/songs",          h.listSongs)
	rg.POST("/:id/songs",         h.addSong)
	rg.DELETE("/:id/songs/:mid",  h.removeSong)
}

func (h *PlaylistHandler) list(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	items, err := h.q.ListUserPlaylists(ctx, userID)
	if err != nil {
		h.log.Error("list playlists", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *PlaylistHandler) create(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	var body struct {
		Name string `json:"name" binding:"required,max=100"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_BODY", "message": err.Error()})
		return
	}
	pl, err := h.q.CreatePlaylist(ctx, repo.CreatePlaylistParams{UserID: userID, Name: body.Name})
	if err != nil {
		h.log.Error("create playlist", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(userID),
		mustJSON(ws.Message{Type: ws.EventPlaylistChange, Data: pl}))
	c.JSON(http.StatusCreated, pl)
}

func (h *PlaylistHandler) update(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	plID := c.Param("id")
	var body struct {
		Name string `json:"name" binding:"required,max=100"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_BODY", "message": err.Error()})
		return
	}
	pl, err := h.q.UpdatePlaylistName(ctx, repo.UpdatePlaylistNameParams{
		ID:     plID,
		Name:   body.Name,
		UserID: userID,
	})
	if err != nil {
		h.log.Error("update playlist", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(userID),
		mustJSON(ws.Message{Type: ws.EventPlaylistChange, Data: pl}))
	c.JSON(http.StatusOK, pl)
}

func (h *PlaylistHandler) delete(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	plID := c.Param("id")
	if err := h.q.SoftDeletePlaylist(ctx, repo.SoftDeletePlaylistParams{ID: plID, UserID: userID}); err != nil {
		h.log.Error("delete playlist", zap.String("user", userID), zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(userID),
		mustJSON(ws.Message{Type: ws.EventPlaylistChange, Data: gin.H{"deleted_id": plID}}))
	c.Status(http.StatusNoContent)
}

func (h *PlaylistHandler) listSongs(c *gin.Context) {
	ctx := c.Request.Context()
	plID := c.Param("id")
	songs, err := h.q.ListPlaylistSongs(ctx, plID)
	if err != nil {
		h.log.Error("list playlist songs", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": songs})
}

func (h *PlaylistHandler) addSong(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	plID := c.Param("id")
	var body struct {
		SongMid string `json:"song_mid" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_BODY", "message": err.Error()})
		return
	}
	// Verify playlist belongs to user
	if _, err := h.q.GetPlaylistByID(ctx, repo.GetPlaylistByIDParams{ID: plID, UserID: userID}); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND"})
		return
	}
	// Get next sort order
	nextRaw, err := h.q.GetNextSortOrder(ctx, plID)
	if err != nil {
		h.log.Error("get next sort order", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	var sortOrder int32
	if v, ok := nextRaw.(int64); ok {
		sortOrder = int32(v)
	}
	song, err := h.q.AddSongToPlaylist(ctx, repo.AddSongToPlaylistParams{
		PlaylistID: plID,
		SongMid:    body.SongMid,
		SortOrder:  sortOrder,
	})
	if err != nil {
		h.log.Error("add song to playlist", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(userID),
		mustJSON(ws.Message{Type: ws.EventPlaylistChange,
			Data: gin.H{"playlist_id": plID, "added": song}}))
	c.JSON(http.StatusCreated, song)
}

func (h *PlaylistHandler) removeSong(c *gin.Context) {
	ctx := c.Request.Context()
	userID := c.GetString("user_id")
	plID := c.Param("id")
	songMid := c.Param("mid")
	// Verify ownership first
	if _, err := h.q.GetPlaylistByID(ctx, repo.GetPlaylistByIDParams{ID: plID, UserID: userID}); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND"})
		return
	}
	removedOrder, err := h.q.RemoveSongFromPlaylist(ctx, repo.RemoveSongFromPlaylistParams{
		PlaylistID: plID,
		SongMid:    songMid,
	})
	if err != nil {
		h.log.Error("remove song from playlist", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL"})
		return
	}
	// Compact sort order to fill the gap
	_ = h.q.CompactSortOrder(ctx, repo.CompactSortOrderParams{PlaylistID: plID, SortOrder: removedOrder})
	_ = h.rdb.Publish(ctx, rdb.KeyWSChannel(userID),
		mustJSON(ws.Message{Type: ws.EventPlaylistChange,
			Data: gin.H{"playlist_id": plID, "removed_mid": songMid}}))
	c.Status(http.StatusNoContent)
}
