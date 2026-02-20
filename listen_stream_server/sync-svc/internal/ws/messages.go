// Package ws implements the WebSocket hub and per-client connection management
// for sync-svc real-time push notifications.
package ws

// Event type constants.  The client SDK switches on these to dispatch events.
const (
	// EventFavoriteChange is published when a user adds or removes a favourite.
	EventFavoriteChange = "favorite.change"
	// EventHistoryUpdate is published when a listening record or progress is saved.
	EventHistoryUpdate = "history.update"
	// EventPlaylistChange is published when a playlist is created, updated, or deleted.
	EventPlaylistChange = "playlist.change"
	// EventDeviceKicked is published when the user's device is evicted by a new login.
	EventDeviceKicked = "device.kicked"
	// EventCookieAlert is published when the scheduled cookie refresh fails.
	EventCookieAlert = "cookie.alert"
)

// Message is the envelope sent over WebSocket to connected clients.
type Message struct {
	// Type is one of the Event* constants above.
	Type string `json:"type"`
	// Data is the event-specific payload (arbitrary JSON-serialisable value).
	Data interface{} `json:"data,omitempty"`
}
