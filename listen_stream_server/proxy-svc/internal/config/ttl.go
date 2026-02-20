// Package config defines proxy-specific configuration constants.
package config

import "time"

// ProxyTTL maps upstream path prefixes to Redis cache TTLs.
// TTL == 0 means the response is NOT cached (always forwarded to upstream).
var ProxyTTL = map[string]time.Duration{
	"/recommend/banner":     30 * time.Minute,
	"/recommend/daily":      1 * time.Hour,
	"/recommend/playlist":   1 * time.Hour,
	"/recommend/new/songs":  30 * time.Minute,
	"/recommend/new/albums": 30 * time.Minute,
	"/playlist/category":    6 * time.Hour,
	"/playlist/information": 1 * time.Hour,
	"/playlist/detail":      6 * time.Hour,
	"/artist/category":      6 * time.Hour,
	"/artist/list":          2 * time.Hour,
	"/artist/detail":        12 * time.Hour,
	"/artist/albums":        12 * time.Hour,
	"/artist/mvs":           12 * time.Hour,
	"/artist/songs":         12 * time.Hour,
	"/rankings/list":        1 * time.Hour,
	"/rankings/detail":      1 * time.Hour,
	"/radio/category":       6 * time.Hour,
	"/radio/songlist":       0,              // not cached
	"/mv/category":          6 * time.Hour,
	"/mv/list":              1 * time.Hour,
	"/mv/detail":            0,              // not cached
	"/album/detail":         12 * time.Hour,
	"/album/songs":          12 * time.Hour,
	"/search/hotkey":        15 * time.Minute,
	"/search":               5 * time.Minute,
	"/lyric":                7 * 24 * time.Hour,
}
