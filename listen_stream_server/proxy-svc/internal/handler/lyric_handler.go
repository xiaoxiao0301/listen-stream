package handler

import (
	"net/http"

	pxcfg "listen-stream/proxy-svc/internal/config"

	"github.com/gin-gonic/gin"
)

// LyricHandler serves /api/lyric endpoint.
// Lyrics are cached for 7 days since they rarely change.
type LyricHandler struct{ *ProxyHandler }

func NewLyricHandler(base *ProxyHandler) *LyricHandler { return &LyricHandler{base} }

func (h *LyricHandler) Register(rg *gin.RouterGroup) {
	rg.GET("", h.lyric)  // GET /api/lyric?id=...
}

// lyric requires the song id query param.
func (h *LyricHandler) lyric(c *gin.Context) {
	if c.Query("id") == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "id is required"})
		return
	}
	h.handle(c, "/lyric/", pxcfg.ProxyTTL["/lyric"])
}
