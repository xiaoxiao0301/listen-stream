package handler

import (
    "net/http"

    "github.com/gin-gonic/gin"
    pxcfg "listen-stream/proxy-svc/internal/config"
)

// SongHandler serves /api/song endpoints.
type SongHandler struct{ *ProxyHandler }

// NewSongHandler creates a SongHandler.
func NewSongHandler(base *ProxyHandler) *SongHandler { return &SongHandler{base} }

// Register mounts routes under /api/song
func (h *SongHandler) Register(rg *gin.RouterGroup) {
    rg.GET("/detail", h.detail) // GET /api/song/detail?id=...
}

// detail requires id param and forwards to upstream /song/detail.
func (h *SongHandler) detail(c *gin.Context) {
    if c.Query("id") == "" {
        c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "id is required"})
        return
    }
    h.handle(c, "/song/detail", pxcfg.ProxyTTL["/song/detail"])
}
