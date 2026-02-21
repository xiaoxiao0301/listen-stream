package handler

import (
	"net/http"

	pxcfg "listen-stream/proxy-svc/internal/config"

	"github.com/gin-gonic/gin"
)

// SingerHandler serves /api/artist/* endpoints.
type SingerHandler struct{ *ProxyHandler }

func NewSingerHandler(base *ProxyHandler) *SingerHandler { return &SingerHandler{base} }

func (h *SingerHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/category", h.category)
	rg.GET("/list",     h.list)
	rg.GET("/detail",   h.detail)
	rg.GET("/albums",   h.albums)
	rg.GET("/mvs",      h.mvs)
	rg.GET("/songs",    h.songs)
}

func (h *SingerHandler) category(c *gin.Context) {
	h.handle(c, "/artist/category", pxcfg.ProxyTTL["/artist/category"])
}

// list validates the required area/sex/genre/index query params.
func (h *SingerHandler) list(c *gin.Context) {
	if c.Query("area") == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "area is required"})
		return
	}
	h.handle(c, "/artist/list", pxcfg.ProxyTTL["/artist/list"])
}
func (h *SingerHandler) detail(c *gin.Context) {
	// Client sends 'mid', upstream expects 'id'
	h.handleWithParamMap(c, "/artist/detail", pxcfg.ProxyTTL["/artist/detail"], map[string]string{"mid": "id"})
}
func (h *SingerHandler) albums(c *gin.Context) {
	// Client sends 'mid', upstream expects 'id'
	h.handleWithParamMap(c, "/artist/albums", pxcfg.ProxyTTL["/artist/albums"], map[string]string{"mid": "id"})
}
func (h *SingerHandler) mvs(c *gin.Context) {
	// Client sends 'mid', upstream expects 'id'
	h.handleWithParamMap(c, "/artist/mvs", pxcfg.ProxyTTL["/artist/mvs"], map[string]string{"mid": "id"})
}
func (h *SingerHandler) songs(c *gin.Context) {
	// Client sends 'mid', upstream expects 'id'
	h.handleWithParamMap(c, "/artist/songs", pxcfg.ProxyTTL["/artist/songs"], map[string]string{"mid": "id"})
}
