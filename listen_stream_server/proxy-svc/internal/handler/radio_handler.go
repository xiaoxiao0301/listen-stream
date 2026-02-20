package handler

import (
	"github.com/gin-gonic/gin"
	pxcfg "listen-stream/proxy-svc/internal/config"
)

// RadioHandler serves /api/radio/* endpoints.
// /radio/songlist is intentionally uncached (TTL == 0).
type RadioHandler struct{ *ProxyHandler }

func NewRadioHandler(base *ProxyHandler) *RadioHandler { return &RadioHandler{base} }

func (h *RadioHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/category", h.category)
	rg.GET("/songlist",  h.songlist)
}

func (h *RadioHandler) category(c *gin.Context) {
	h.handle(c, "/radio/category", pxcfg.ProxyTTL["/radio/category"])
}
func (h *RadioHandler) songlist(c *gin.Context) {
	h.handle(c, "/radio/songlist", pxcfg.ProxyTTL["/radio/songlist"]) // TTL == 0
}
