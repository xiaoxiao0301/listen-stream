package handler

import (
	"net/http"

	pxcfg "listen-stream/proxy-svc/internal/config"

	"github.com/gin-gonic/gin"
)

// SearchHandler serves /api/search/* endpoints.
type SearchHandler struct{ *ProxyHandler }

func NewSearchHandler(base *ProxyHandler) *SearchHandler { return &SearchHandler{base} }

func (h *SearchHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/hotkey", h.hotkey)
	rg.GET("/songs",   h.searchSongs)
	rg.GET("/singers", h.searchSingers)
	rg.GET("/albums",  h.searchAlbums)
	rg.GET("/mvs",     h.searchMvs)
	rg.GET("",         h.search)  // GET /api/search?keyword=...
}

func (h *SearchHandler) hotkey(c *gin.Context) {
	h.handle(c, "/search/hotkey", pxcfg.ProxyTTL["/search/hotkey"])
}

func (h *SearchHandler) searchSongs(c *gin.Context) {
	if c.Query("keyword") == "" && c.Query("q") == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "keyword or q is required"})
		return
	}
	// Upstream API: /search/?keyword=xxx&type=0
	c.Request.URL.RawQuery += "&type=0"
	h.handle(c, "/search/", pxcfg.ProxyTTL["/search/"])
}

func (h *SearchHandler) searchSingers(c *gin.Context) {
	if c.Query("keyword") == "" && c.Query("q") == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "keyword or q is required"})
		return
	}
	// Upstream API: /search/?keyword=xxx&type=9
	c.Request.URL.RawQuery += "&type=9"
	h.handle(c, "/search/", pxcfg.ProxyTTL["/search/"])
}

func (h *SearchHandler) searchAlbums(c *gin.Context) {
	if c.Query("keyword") == "" && c.Query("q") == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "keyword or q is required"})
		return
	}
	// Upstream API: /search/?keyword=xxx&type=8
	c.Request.URL.RawQuery += "&type=8"
	h.handle(c, "/search/", pxcfg.ProxyTTL["/search/"])
}

func (h *SearchHandler) searchMvs(c *gin.Context) {
	if c.Query("keyword") == "" && c.Query("q") == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "keyword or q is required"})
		return
	}
	// Upstream API: /search/?keyword=xxx&type=12
	c.Request.URL.RawQuery += "&type=12"
	h.handle(c, "/search/", pxcfg.ProxyTTL["/search/"])
}

// search validates the required keyword param.
func (h *SearchHandler) search(c *gin.Context) {
	if c.Query("keyword") == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "keyword is required"})
		return
	}
	h.handle(c, "/search/", pxcfg.ProxyTTL["/search/"])
}
