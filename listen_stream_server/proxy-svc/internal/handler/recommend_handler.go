package handler

import (
	"github.com/gin-gonic/gin"
	pxcfg "listen-stream/proxy-svc/internal/config"
)

// RecommendHandler serves all /api/recommend/* endpoints.
type RecommendHandler struct{ *ProxyHandler }

// NewRecommendHandler creates a RecommendHandler.
func NewRecommendHandler(base *ProxyHandler) *RecommendHandler {
	return &RecommendHandler{base}
}

// Register mounts the routes onto the provided router group.
func (h *RecommendHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/banner",     h.banner)
	rg.GET("/daily",      h.daily)
	rg.GET("/playlist",   h.playlist)
	rg.GET("/new/songs",  h.newSongs)
	rg.GET("/new/albums", h.newAlbums)
}

func (h *RecommendHandler) banner(c *gin.Context) {
	h.handle(c, "/recommend/banner", pxcfg.ProxyTTL["/recommend/banner"])
}
func (h *RecommendHandler) daily(c *gin.Context) {
	h.handle(c, "/recommend/daily", pxcfg.ProxyTTL["/recommend/daily"])
}
func (h *RecommendHandler) playlist(c *gin.Context) {
	h.handle(c, "/recommend/playlist", pxcfg.ProxyTTL["/recommend/playlist"])
}
func (h *RecommendHandler) newSongs(c *gin.Context) {
	h.handle(c, "/recommend/new/songs", pxcfg.ProxyTTL["/recommend/new/songs"])
}
func (h *RecommendHandler) newAlbums(c *gin.Context) {
	h.handle(c, "/recommend/new/albums", pxcfg.ProxyTTL["/recommend/new/albums"])
}
