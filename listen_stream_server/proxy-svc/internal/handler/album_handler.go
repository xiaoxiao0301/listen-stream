package handler

import (
	"github.com/gin-gonic/gin"
	pxcfg "listen-stream/proxy-svc/internal/config"
)

// AlbumHandler serves /api/album/* endpoints.
type AlbumHandler struct{ *ProxyHandler }

func NewAlbumHandler(base *ProxyHandler) *AlbumHandler { return &AlbumHandler{base} }

func (h *AlbumHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/detail", h.detail)
	rg.GET("/songs",  h.songs)
}

func (h *AlbumHandler) detail(c *gin.Context) {
	h.handle(c, "/album/detail", pxcfg.ProxyTTL["/album/detail"])
}
func (h *AlbumHandler) songs(c *gin.Context) {
	h.handle(c, "/album/songs", pxcfg.ProxyTTL["/album/songs"])
}
