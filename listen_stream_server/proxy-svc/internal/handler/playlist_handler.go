package handler

import (
	"github.com/gin-gonic/gin"
	pxcfg "listen-stream/proxy-svc/internal/config"
)

// PlaylistHandler serves /api/playlist/* endpoints.
type PlaylistHandler struct{ *ProxyHandler }

func NewPlaylistHandler(base *ProxyHandler) *PlaylistHandler { return &PlaylistHandler{base} }

func (h *PlaylistHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/category",    h.category)
	rg.GET("/information", h.information)
	rg.GET("/detail",      h.detail)
}

func (h *PlaylistHandler) category(c *gin.Context) {
	h.handle(c, "/playlist/category", pxcfg.ProxyTTL["/playlist/category"])
}
func (h *PlaylistHandler) information(c *gin.Context) {
	h.handle(c, "/playlist/information", pxcfg.ProxyTTL["/playlist/information"])
}
func (h *PlaylistHandler) detail(c *gin.Context) {
	h.handle(c, "/playlist/detail", pxcfg.ProxyTTL["/playlist/detail"])
}
