package handler

import (
	"github.com/gin-gonic/gin"
	pxcfg "listen-stream/proxy-svc/internal/config"
)

// MVHandler serves /api/mv/* endpoints.
// /mv/detail is uncached (TTL == 0) because it contains short-lived sign URLs.
type MVHandler struct{ *ProxyHandler }

func NewMVHandler(base *ProxyHandler) *MVHandler { return &MVHandler{base} }

func (h *MVHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/category", h.category)
	rg.GET("/list",     h.list)
	rg.GET("/detail",   h.detail)
}

func (h *MVHandler) category(c *gin.Context) {
	h.handle(c, "/mv/category", pxcfg.ProxyTTL["/mv/category"])
}
func (h *MVHandler) list(c *gin.Context) {
	h.handle(c, "/mv/list", pxcfg.ProxyTTL["/mv/list"])
}
func (h *MVHandler) detail(c *gin.Context) {
	h.handle(c, "/mv/detail", pxcfg.ProxyTTL["/mv/detail"]) // TTL == 0
}
