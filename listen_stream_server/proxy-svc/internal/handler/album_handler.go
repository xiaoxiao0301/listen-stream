package handler

import (
	pxcfg "listen-stream/proxy-svc/internal/config"

	"github.com/gin-gonic/gin"
)

// AlbumHandler serves /api/album/* endpoints.
type AlbumHandler struct{ *ProxyHandler }

func NewAlbumHandler(base *ProxyHandler) *AlbumHandler { return &AlbumHandler{base} }

func (h *AlbumHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/detail", h.detail)
	rg.GET("/songs",  h.songs)
}

func (h *AlbumHandler) detail(c *gin.Context) {
	// Client sends 'mid', upstream expects 'id'
	h.handleWithParamMap(c, "/album/detail", pxcfg.ProxyTTL["/album/detail"], map[string]string{"mid": "id"})
}
func (h *AlbumHandler) songs(c *gin.Context) {
	// Client sends 'mid', upstream expects 'id'
	h.handleWithParamMap(c, "/album/songs", pxcfg.ProxyTTL["/album/songs"], map[string]string{"mid": "id"})
}
