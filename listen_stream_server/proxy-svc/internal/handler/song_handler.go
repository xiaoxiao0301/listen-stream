package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"

	pxcfg "listen-stream/proxy-svc/internal/config"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// SongHandler serves /api/song endpoints.
type SongHandler struct{ *ProxyHandler }

// NewSongHandler creates a SongHandler.
func NewSongHandler(base *ProxyHandler) *SongHandler { return &SongHandler{base} }

// Register mounts routes under /api/song
func (h *SongHandler) Register(rg *gin.RouterGroup) {
    rg.GET("/detail", h.detail) // GET /api/song/detail?id=...
    rg.GET("/url", h.url)        // GET /api/song/url?id=...&name=...
}

// detail requires id param and forwards to upstream /song/detail.
func (h *SongHandler) detail(c *gin.Context) {
    if c.Query("id") == "" {
        c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "id is required"})
        return
    }
    h.handle(c, "/song/detail", pxcfg.ProxyTTL["/song/detail"])
}

// url fetches song playback URL with QQ → Joox fallback.
// Query params: id (required, song mid), name (optional, used for Joox search).
// Returns unified response:
//   Success: {"code": 1, "message": "Success", "url": "...", "source": "qq|joox", "songmid": "..."}
//   Failure: {"code": 0, "message": "暂无播放权限", "url": null}
func (h *SongHandler) url(c *gin.Context) {
    id := c.Query("id")
    name := c.Query("name")
    if id == "" {
        c.JSON(http.StatusBadRequest, gin.H{"code": "MISSING_PARAM", "message": "id is required"})
        return
    }

    ctx := c.Request.Context()

    // ── 1. Try primary source (QQ Music) ─────────────────────────────────────
    qqURL, err := h.tryQQMusic(ctx, id)
    if err == nil && qqURL != "" {
        c.JSON(http.StatusOK, gin.H{
            "code":    1,
            "message": "Success",
            "url":     qqURL,
            "source":  "qq",
            "songmid": id,
        })
        return
    }

    h.log.Info("QQ Music failed, trying Joox fallback", zap.String("id", id), zap.Error(err))

    // ── 2. Fallback to Joox ──────────────────────────────────────────────────
    if name == "" {
        // If no name provided, cannot search Joox
        c.JSON(http.StatusOK, gin.H{
            "code":    0,
            "message": "暂无播放权限",
            "url":     nil,
        })
        return
    }

    jooxURL, err := h.tryJooxFallback(ctx, name)
    if err == nil && jooxURL != "" {
        c.JSON(http.StatusOK, gin.H{
            "code":    1,
            "message": "Success",
            "url":     jooxURL,
            "source":  "joox",
            "songmid": id,
        })
        return
    }

    h.log.Info("Joox fallback failed", zap.String("id", id), zap.String("name", name), zap.Error(err))

    // ── 3. No playback available ─────────────────────────────────────────────
    c.JSON(http.StatusOK, gin.H{
        "code":    0,
        "message": "暂无播放权限",
        "url":     nil,
    })
}

// tryQQMusic requests /song/url?id={id} from primary upstream.
// Returns URL if code=1, empty string otherwise.
func (h *SongHandler) tryQQMusic(ctx context.Context, id string) (string, error) {
    body, err := h.client.Do(ctx, "/song/url", fmt.Sprintf("id=%s", id))
    if err != nil {
        return "", fmt.Errorf("qq music request failed: %w", err)
    }

    var resp struct {
        Code int    `json:"code"`
        Data struct {
            URL string `json:"url"`
        } `json:"data"`
    }
    if err := json.Unmarshal(body, &resp); err != nil {
        return "", fmt.Errorf("qq music parse failed: %w", err)
    }

    if resp.Code == 1 && resp.Data.URL != "" {
        return resp.Data.URL, nil
    }
    return "", fmt.Errorf("qq music returned code=%d", resp.Code)
}

// tryJooxFallback uses fallback API to search and get playback URL from Joox.
// Step a: Search by song name → get Joox id
// Step b: Get URL by Joox id
func (h *SongHandler) tryJooxFallback(ctx context.Context, songName string) (string, error) {
    // Step a: Search
    searchQuery := fmt.Sprintf("types=search&source=joox&name=%s", url.QueryEscape(songName))
    searchBody, err := h.client.DoFallback(ctx, "", searchQuery)
    if err != nil {
        return "", fmt.Errorf("joox search failed: %w", err)
    }

    var searchResp []struct {
        ID   string `json:"id"`
        Name string `json:"name"`
    }
    if err := json.Unmarshal(searchBody, &searchResp); err != nil {
        return "", fmt.Errorf("joox search parse failed: %w", err)
    }
    if len(searchResp) == 0 {
        return "", fmt.Errorf("joox search returned no results")
    }

    jooxID := searchResp[0].ID

    // Step b: Get URL
    urlQuery := fmt.Sprintf("types=url&source=joox&id=%s", url.QueryEscape(jooxID))
    urlBody, err := h.client.DoFallback(ctx, "", urlQuery)
    if err != nil {
        return "", fmt.Errorf("joox url request failed: %w", err)
    }

    var urlResp struct {
        URL string `json:"url"`
    }
    if err := json.Unmarshal(urlBody, &urlResp); err != nil {
        return "", fmt.Errorf("joox url parse failed: %w", err)
    }

    if urlResp.URL == "" {
        return "", fmt.Errorf("joox returned empty url")
    }
    return urlResp.URL, nil
}
