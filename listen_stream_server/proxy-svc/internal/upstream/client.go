// Package upstream provides an HTTP client for the third-party music API.
package upstream

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"time"

	"listen-stream/shared/pkg/config"
)

const (
	cfgAPIBaseURL = "API_BASE_URL"
	cfgAPIKey     = "API_KEY"
	cfgCookie     = "COOKIE"
)

// Client forwards requests to the upstream music API.
// Base URL and Cookie header are read from ConfigService on each call
// (30 s cache ensures freshness without per-request DB hits).
type Client struct {
	cfgSvc config.Service
	cli    *http.Client
}

// New creates an upstream Client.
func New(cfgSvc config.Service) *Client {
	return &Client{
		cfgSvc: cfgSvc,
		cli:    &http.Client{Timeout: 10 * time.Second},
	}
}

// Do sends a GET request to {baseURL}{path}?{rawQuery} with the configured
// Cookie header and returns the response body bytes.
func (c *Client) Do(ctx context.Context, path, rawQuery string) ([]byte, error) {
	keys, err := c.cfgSvc.GetMany(ctx, []string{cfgAPIBaseURL, cfgAPIKey, cfgCookie})
	if err != nil {
		return nil, fmt.Errorf("upstream: read config: %w", err)
	}
	u := keys[cfgAPIBaseURL] + path
	if rawQuery != "" {
		u += "?" + rawQuery
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return nil, fmt.Errorf("upstream: build request: %w", err)
	}
	if cookie := keys[cfgCookie]; cookie != "" {
		req.Header.Set("Cookie", cookie)
	}
	if apiKey := keys[cfgAPIKey]; apiKey != "" {
		req.Header.Set("X-Api-Key", apiKey)
	}
	req.Header.Set("User-Agent", "listen-stream/1.0")
	resp, err := c.cli.Do(req)
	if err != nil {
		return nil, fmt.Errorf("upstream: http: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("upstream: status %d for %s", resp.StatusCode, path)
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20)) // 4 MB cap
	if err != nil {
		return nil, fmt.Errorf("upstream: read body: %w", err)
	}
	return body, nil
}
