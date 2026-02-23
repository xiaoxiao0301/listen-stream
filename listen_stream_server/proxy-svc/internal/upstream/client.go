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
	cfgAPIBaseURL     = "API_BASE_URL"
	cfgAPIFallbackURL = "API_FALLBACK_URL"
	cfgAPIKey         = "API_KEY"
)

// Client forwards requests to the upstream music API.
// Base URL, Fallback URL and API Key are read from ConfigService on each call
// (30 s cache ensures freshness without per-request DB hits).
// If primary URL fails, automatically retries with fallback URL if configured.
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
// API key in Authorization Bearer header and returns the response body bytes.
// If primary URL fails and fallback URL is configured, retries with fallback.
func (c *Client) Do(ctx context.Context, path, rawQuery string) ([]byte, error) {
	keys, err := c.cfgSvc.GetMany(ctx, []string{cfgAPIBaseURL, cfgAPIFallbackURL, cfgAPIKey})
	if err != nil {
		return nil, fmt.Errorf("upstream: read config: %w", err)
	}

	// Try primary URL first
	body, err := c.doRequest(ctx, keys[cfgAPIBaseURL], keys[cfgAPIKey], path, rawQuery)
	if err != nil {
		// If primary fails and fallback is configured, try fallback
		if fallbackURL := keys[cfgAPIFallbackURL]; fallbackURL != "" {
			body, fallbackErr := c.doRequest(ctx, fallbackURL, keys[cfgAPIKey], path, rawQuery)
			if fallbackErr == nil {
				return body, nil
			}
			// Return original error if fallback also fails
		}
		return nil, err
	}
	return body, nil
}

// doRequest performs actual HTTP request with given base URL
func (c *Client) doRequest(ctx context.Context, baseURL, apiKey, path, rawQuery string) ([]byte, error) {
	if baseURL == "" {
		return nil, fmt.Errorf("upstream: base URL not configured")
	}
	u := baseURL + path
	if rawQuery != "" {
		u += "?" + rawQuery
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return nil, fmt.Errorf("upstream: build request: %w", err)
	}
	if apiKey != "" {
		req.Header.Set("Authorization", "Bearer "+apiKey)
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
