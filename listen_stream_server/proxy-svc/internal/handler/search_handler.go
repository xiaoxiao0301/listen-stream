package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	pxcfg "listen-stream/proxy-svc/internal/config"
)

// SearchHandler serves /api/search/* endpoints.
type SearchHandler struct{ *ProxyHandler }

func NewSearchHandler(base *ProxyHandler) *SearchHandler { return &SearchHandler{base} }

func (h *SearchHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/hotkey", h.hotkey)
	rg.GET("",        h.search)  // GET /api/search?keyword=...
}

func (h *SearchHandler) hotkey(c *gin.Context) {
	h.handle(c, "/search/hotkey", pxcfg.ProxyTTL["/search/hotkey"])
}

// search validates the required keyword param.
func (h *SearchHandler) search(c *gin.Context) {
	if c.Query("keyword") == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "keyword is required"})
		return
	}
	h.handle(c, "/search", pxcfg.ProxyTTL["/search"])
}
