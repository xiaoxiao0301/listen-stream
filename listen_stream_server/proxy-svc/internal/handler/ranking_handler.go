package handler

import (
	pxcfg "listen-stream/proxy-svc/internal/config"

	"github.com/gin-gonic/gin"
)

// RankingHandler serves /api/rankings/* endpoints.
type RankingHandler struct{ *ProxyHandler }

func NewRankingHandler(base *ProxyHandler) *RankingHandler { return &RankingHandler{base} }

func (h *RankingHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/list",   h.list)
	rg.GET("/detail", h.detail)
}

func (h *RankingHandler) list(c *gin.Context) {
	h.handle(c, "/rankings/list", pxcfg.ProxyTTL["/rankings/list"])
}
func (h *RankingHandler) detail(c *gin.Context) {
	h.handleWithParamMap(c, "/rankings/detail", pxcfg.ProxyTTL["/rankings/detail"], map[string]string{"id": "id"})
}
