package handler

import (
	"encoding/json"
	"time"

	"go.uber.org/zap"
)

// mustJSON serialises v to a JSON string. Errors are logged and return "{}".
func mustJSON(v interface{}) string {
	b, err := json.Marshal(v)
	if err != nil {
		return "{}"
	}
	return string(b)
}

// unixMsToTime converts a Unix millisecond timestamp to a UTC time.Time.
func unixMsToTime(ms int64) time.Time {
	return time.UnixMilli(ms).UTC()
}

// zap is imported via "go.uber.org/zap" but we re-export the field helpers
// so individual handler files can use zap.String / zap.Error directly.
var _ = zap.String
