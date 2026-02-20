package sms

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"time"

	"listen-stream/shared/pkg/config"
)

// AliyunAdapter sends SMS via Alibaba Cloud Dysms.
// Config keys consumed (all read from ConfigService, NOT env vars):
//
//	SMS_ALIYUN_ACCESS_KEY_ID     — RAM AccessKey ID
//	SMS_ALIYUN_ACCESS_KEY_SECRET — RAM AccessKey Secret
//	SMS_ALIYUN_SIGN_NAME         — 短信签名
//	SMS_ALIYUN_TEMPLATE_CODE     — 模板 Code (e.g. SMS_123456789)
type AliyunAdapter struct {
	cfgSvc config.Service
	cli    *http.Client
}

func NewAliyunAdapter(cfgSvc config.Service) *AliyunAdapter {
	return &AliyunAdapter{
		cfgSvc: cfgSvc,
		cli:    &http.Client{Timeout: 8 * time.Second},
	}
}

func (a *AliyunAdapter) SendVerificationCode(ctx context.Context, phone, code string) error {
	keys, err := a.cfgSvc.GetMany(ctx, []string{
		"SMS_ALIYUN_ACCESS_KEY_ID",
		"SMS_ALIYUN_ACCESS_KEY_SECRET",
		"SMS_ALIYUN_SIGN_NAME",
		"SMS_ALIYUN_TEMPLATE_CODE",
	})
	if err != nil {
		return fmt.Errorf("aliyun: read config: %w", err)
	}

	templateParam := fmt.Sprintf(`{"code":"%s"}`, code)

	// Build unsigned parameter map.
	params := map[string]string{
		"Action":           "SendSms",
		"Version":          "2017-05-25",
		"Format":           "JSON",
		"SignatureMethod":  "HMAC-SHA256",
		"SignatureVersion": "1.0",
		"SignatureNonce":   nonce(),
		"Timestamp":        time.Now().UTC().Format("2006-01-02T15:04:05Z"),
		"AccessKeyId":      keys["SMS_ALIYUN_ACCESS_KEY_ID"],
		"PhoneNumbers":     phone,
		"SignName":         keys["SMS_ALIYUN_SIGN_NAME"],
		"TemplateCode":     keys["SMS_ALIYUN_TEMPLATE_CODE"],
		"TemplateParam":    templateParam,
	}

	// Sort keys and build canonical query string.
	orderedKeys := make([]string, 0, len(params))
	for k := range params {
		orderedKeys = append(orderedKeys, k)
	}
	sort.Strings(orderedKeys)

	var parts []string
	for _, k := range orderedKeys {
		parts = append(parts, aliyunEncode(k)+"="+aliyunEncode(params[k]))
	}
	canonicalQS := strings.Join(parts, "&")

	// HMAC-SHA256 signature.
	stringToSign := "GET&%2F&" + aliyunEncode(canonicalQS)
	h := hmac.New(sha256.New, []byte(keys["SMS_ALIYUN_ACCESS_KEY_SECRET"]+"&"))
	h.Write([]byte(stringToSign))
	sig := base64.StdEncoding.EncodeToString(h.Sum(nil))

	reqURL := "https://dysmsapi.aliyuncs.com/?" + canonicalQS + "&Signature=" + aliyunEncode(sig)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return fmt.Errorf("aliyun: build request: %w", err)
	}

	resp, err := a.cli.Do(req)
	if err != nil {
		return fmt.Errorf("aliyun: http: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	var result struct {
		Code    string `json:"Code"`
		Message string `json:"Message"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return fmt.Errorf("aliyun: parse response: %w", err)
	}
	if result.Code != "OK" {
		return fmt.Errorf("aliyun: gateway error %s: %s", result.Code, result.Message)
	}
	return nil
}

// aliyunEncode implements the Aliyun percent-encoding variant.
func aliyunEncode(s string) string {
	return strings.ReplaceAll(
		strings.ReplaceAll(
			strings.ReplaceAll(url.QueryEscape(s), "+", "%20"),
			"*", "%2A"),
		"%7E", "~")
}

func nonce() string {
	b := make([]byte, 16)
	rand.Read(b) //nolint:errcheck
	return fmt.Sprintf("%x", b)
}
