package ws

import (
	"context"
	"encoding/json"
	"sync"

	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
	"listen-stream/shared/pkg/rdb"
)

// Hub manages all live WebSocket clients and distributes Redis Pub/Sub events.
//
// Layout:
//
//	clients[userID][deviceID] → *Client
type Hub struct {
	mu      sync.RWMutex
	clients map[string]map[string]*Client
	rdb     *rdb.Client
	log     *zap.Logger
}

// New creates an uninitialised Hub. Call Start to begin Pub/Sub processing.
func New(rdbClient *rdb.Client, log *zap.Logger) *Hub {
	return &Hub{
		clients: make(map[string]map[string]*Client),
		rdb:     rdbClient,
		log:     log,
	}
}

// register adds a client.
func (h *Hub) register(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.clients[c.userID] == nil {
		h.clients[c.userID] = make(map[string]*Client)
	}
	h.clients[c.userID][c.deviceID] = c
}

// unregister removes a client and closes its send channel.
func (h *Hub) unregister(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	devices, ok := h.clients[c.userID]
	if !ok {
		return
	}
	if _, ok := devices[c.deviceID]; ok {
		delete(devices, c.deviceID)
		close(c.send)
	}
	if len(devices) == 0 {
		delete(h.clients, c.userID)
	}
}

// PushToUser serialises msg and delivers it to all of userID's connected clients.
// Clients whose send channel is full are silently skipped.
func (h *Hub) PushToUser(userID string, msg Message) {
	data, err := json.Marshal(msg)
	if err != nil {
		h.log.Error("hub: marshal message", zap.Error(err))
		return
	}
	h.mu.RLock()
	devices := h.clients[userID]
	h.mu.RUnlock()
	for _, c := range devices {
		select {
		case c.send <- data:
		default:
			h.log.Warn("hub: slow consumer, dropping message",
				zap.String("user", userID), zap.String("device", c.deviceID))
		}
	}
}

// Start subscribes to "ws:user:*" on Redis and fans out arriving messages
// to locally connected clients. Blocks until ctx is cancelled.
func (h *Hub) Start(ctx context.Context) {
	pubsub := h.rdb.PSubscribe(ctx, "ws:user:*")
	defer pubsub.Close()
	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-pubsub.Channel():
			if !ok {
				return
			}
			h.dispatch(msg)
		}
	}
}

func (h *Hub) dispatch(msg *redis.Message) {
	const prefix = "ws:user:"
	if len(msg.Channel) <= len(prefix) {
		return
	}
	userID := msg.Channel[len(prefix):]
	var m Message
	if err := json.Unmarshal([]byte(msg.Payload), &m); err != nil {
		h.log.Warn("hub: invalid pubsub payload",
			zap.String("channel", msg.Channel), zap.Error(err))
		return
	}
	h.PushToUser(userID, m)
}
