package ws

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"go.uber.org/zap"

	"listen-stream/shared/pkg/config"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// CheckOrigin allows all origins; restrict in production via ALLOWED_ORIGINS config.
	CheckOrigin: func(r *http.Request) bool { return true },
}

// WSHandler exposes the WebSocket upgrade endpoint.
type WSHandler struct {
	hub    *Hub
	cfgSvc config.Service
	log    *zap.Logger
}

// NewWSHandler creates a WSHandler.
func NewWSHandler(hub *Hub, cfgSvc config.Service, log *zap.Logger) *WSHandler {
	return &WSHandler{hub: hub, cfgSvc: cfgSvc, log: log}
}

// Register mounts the WebSocket route to the router group.
// The route must be wrapped by the RequireUser middleware.
func (h *WSHandler) Register(rg *gin.RouterGroup) {
	rg.GET("/ws", h.connect)
}

// connect upgrades the HTTP connection to WebSocket.
//
// The browser WebSocket API does not support custom headers, so the JWT is
// passed as the ?token query parameter and validated by RequireUser middleware
// before this handler is called.
//
// Identity (user_id, device_id) is read from the Gin context — set by middleware.
func (h *WSHandler) connect(c *gin.Context) {
	userID, _ := c.Get("user_id")
	deviceID, _ := c.Get("device_id")
	uid, _ := userID.(string)
	did, _ := deviceID.(string)
	if uid == "" || did == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "UNAUTHORIZED"})
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		h.log.Warn("ws: upgrade failed", zap.Error(err))
		return
	}

	client := newClient(h.hub, conn, uid, did, h.log)
	h.hub.register(client)
	client.Start()
}
