package ws

import (
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = 25 * time.Second // must be < pongWait
	maxMessageSize = 512
)

// Client represents a live WebSocket connection from one device.
type Client struct {
	hub      *Hub
	conn     *websocket.Conn
	send     chan []byte
	userID   string
	deviceID string
	log      *zap.Logger
}

// newClient allocates a Client and registers it with the hub.
func newClient(hub *Hub, conn *websocket.Conn, userID, deviceID string, log *zap.Logger) *Client {
	return &Client{
		hub:      hub,
		conn:     conn,
		send:     make(chan []byte, 64),
		userID:   userID,
		deviceID: deviceID,
		log:      log,
	}
}

// Start launches the read/write pumps in separate goroutines.
func (c *Client) Start() {
	go c.writePump()
	go c.readPump()
}

// readPump keeps the connection alive by handling control frames and enforces
// the pong deadline. Client-to-server data is discarded (server-push only).
func (c *Client) readPump() {
	defer func() {
		c.hub.unregister(c)
		c.conn.Close()
	}()
	c.conn.SetReadLimit(maxMessageSize)
	_ = c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		return c.conn.SetReadDeadline(time.Now().Add(pongWait))
	})
	for {
		_, _, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err,
				websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				c.log.Warn("ws: unexpected close", zap.String("user", c.userID), zap.Error(err))
			}
			break
		}
	}
}

// writePump drains the send channel and periodically pings the client.
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()
	for {
		select {
		case msg, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				c.log.Warn("ws: write error", zap.String("user", c.userID), zap.Error(err))
				return
			}
		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
