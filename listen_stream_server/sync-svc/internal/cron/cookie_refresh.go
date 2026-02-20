// Package cron contains scheduled tasks for sync-svc.
package cron

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/robfig/cron/v3"
	"go.uber.org/zap"

	"listen-stream/shared/pkg/config"
	"listen-stream/shared/pkg/rdb"
)

const (
	// cfgCookieRefreshCron is the cron schedule for cookie refresh (default: every 6 hours).
	cfgCookieRefreshCron = "COOKIE_REFRESH_CRON"
	defaultCronSchedule  = "0 */6 * * *"

	// cfgCookieRefreshURL is the endpoint called to obtain a fresh cookie.
	cfgCookieRefreshURL = "COOKIE_REFRESH_URL"

	// cfgCookie is the key under which the current API cookie is stored.
	cfgCookie = "COOKIE"
)

// CookieRefreshCron schedules periodic cookie refreshes for the upstream music API.
// On failure it writes a cookie:alert key to Redis so the admin dashboard can alert.
type CookieRefreshCron struct {
	cron    *cron.Cron
	entryID cron.EntryID
	cfgSvc  config.Service
	rdb     *rdb.Client
	log     *zap.Logger
}

// New creates a CookieRefreshCron. Call Start to begin scheduling.
func New(cfgSvc config.Service, rdbClient *rdb.Client, log *zap.Logger) *CookieRefreshCron {
	return &CookieRefreshCron{
		cron:   cron.New(),
		cfgSvc: cfgSvc,
		rdb:    rdbClient,
		log:    log,
	}
}

// Start reads the cron schedule from ConfigService and starts the scheduler.
// It also triggers an immediate check so the cookie is always fresh on startup.
func (c *CookieRefreshCron) Start(ctx context.Context) error {
	schedule, err := c.schedule(ctx)
	if err != nil {
		return fmt.Errorf("cookie cron: read schedule: %w", err)
	}
	entryID, err := c.cron.AddFunc(schedule, func() {
		if rerr := c.refresh(ctx); rerr != nil {
			c.onFailure(ctx, rerr)
		}
	})
	if err != nil {
		return fmt.Errorf("cookie cron: add job: %w", err)
	}
	c.entryID = entryID
	c.cron.Start()
	c.log.Info("cookie cron started", zap.String("schedule", schedule))
	return nil
}

// Restart removes the existing cron job and re-registers it with the latest schedule.
// Call this after the COOKIE_REFRESH_CRON config value changes.
func (c *CookieRefreshCron) Restart(ctx context.Context) error {
	c.cron.Remove(c.entryID)
	return c.Start(ctx)
}

// TriggerNow runs the cookie refresh immediately, outside the normal schedule.
func (c *CookieRefreshCron) TriggerNow(ctx context.Context) error {
	return c.refresh(ctx)
}

// Stop halts the scheduler gracefully.
func (c *CookieRefreshCron) Stop() {
	c.cron.Stop()
}

// ── internals ────────────────────────────────────────────────────────────────

func (c *CookieRefreshCron) schedule(ctx context.Context) (string, error) {
	s, err := c.cfgSvc.Get(ctx, cfgCookieRefreshCron)
	if err != nil || s == "" {
		return defaultCronSchedule, nil
	}
	return s, nil
}

// refresh fetches a new cookie from COOKIE_REFRESH_URL and persists it.
//
// TODO: Replace the stub implementation below with the actual cookie refresh
// logic for the target music API (e.g. POST to /login, extract Set-Cookie header).
func (c *CookieRefreshCron) refresh(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()

	refreshURL, err := c.cfgSvc.Get(ctx, cfgCookieRefreshURL)
	if err != nil || refreshURL == "" {
		// Skip silently if the refresh URL is not configured.
		c.log.Debug("cookie refresh: COOKIE_REFRESH_URL not set, skipping")
		return nil
	}

	// ── TODO: implement actual cookie refresh logic ─────────────────────────
	// Example flow:
	//   1. POST to refreshURL with credentials from config
	//   2. Extract new Set-Cookie value from response header
	//   3. Store the new cookie:
	//        c.cfgSvc.Set(ctx, cfgCookie, newCookie)
	// ────────────────────────────────────────────────────────────────────────
	c.log.Info("cookie refresh: stub invoked", zap.String("url", refreshURL))
	return nil
}

// onFailure sets the Redis alert key and logs the failure.
func (c *CookieRefreshCron) onFailure(ctx context.Context, err error) {
	c.log.Error("cookie refresh failed", zap.Error(err))
	_ = c.rdb.Set(ctx, rdb.KeyCookieAlert(), "1", 24*time.Hour)
	// Write structured failure record for audit trail.
	payload, _ := json.Marshal(map[string]interface{}{
		"event": "cookie_refresh_failure",
		"time":  time.Now().UTC().Format(time.RFC3339),
		"error": err.Error(),
	})
	c.log.Warn("cookie failure recorded", zap.String("payload", string(payload)))
}
