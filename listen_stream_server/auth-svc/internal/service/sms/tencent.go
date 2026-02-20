package sms

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"listen-stream/shared/pkg/config"
)

// TencentAdapter sends SMS via Tencent Cloud SMS (TC3-HMAC-SHA256 V3 签名).
// Config keys consumed:
//
//	SMS_TENCENT_SECRET_ID   — SecretId
//	SMS_TENCENT_SECRET_KEY  — SecretKey
//	SMS_TENCENT_SDK_APP_ID  — SdkAppId
//	SMS_TENCENT_SIGN_NAME   — 短信签名内容
//	SMS_TENCENT_TEMPLATE_ID — 模板 ID (纯数字字符串)
type TencentAdapter struct {
	cfgSvc config.Service
	cli    *http.Client
}

func NewTencentAdapter(cfgSvc config.Service) *TencentAdapter {
	return &TencentAdapter{
		cfgSvc: cfgSvc,
		cli:    &http.Client{Timeout: 8 * time.Second},
	}
}

func (t *TencentAdapter) SendVerificationCode(ctx context.Context, phone, code string) error {
	keys, err := t.cfgSvc.GetMany(ctx, []string{
		"SMS_TENCENT_SECRET_ID",
		"SMS_TENCENT_SECRET_KEY",
		"SMS_TENCENT_SDK_APP_ID",
		"SMS_TENCENT_SIGN_NAME",
		"SMS_TENCENT_TEMPLATE_ID",
	})
	if err != nil {
		return fmt.Errorf("tencent: read config: %w", err)
	}

	// Request payload.
	payload, _ := json.Marshal(map[string]interface{}{
		"PhoneNumberSet":   []string{phone},
		"SmsSdkAppId":      keys["SMS_TENCENT_SDK_APP_ID"],
		"SignName":         keys["SMS_TENCENT_SIGN_NAME"],
		"TemplateId":       keys["SMS_TENCENT_TEMPLATE_ID"],
		"TemplateParamSet": []string{code},
	})

	// TC3-HMAC-SHA256 V3 signing.
	service := "sms"
	host := "sms.tencentcloudapi.com"
	now := time.Now().UTC()
	timestamp := strconv.FormatInt(now.Unix(), 10)
	date := now.Format("2006-01-02")

	canonicalHeaders := "content-type:application/json\nhost:" + host + "\nx-tc-action:sendsms\n"
	signedHeaders := "content-type;host;x-tc-action"
	hashedPayload := sha256hex(payload)

	canonicalRequest := strings.Join([]string{
		"POST", "/", "",
		canonicalHeaders,
		signedHeaders,
		hashedPayload,
	}, "\n")

	credentialScope := date + "/" + service + "/tc3_request"
	stringToSign := "TC3-HMAC-SHA256\n" + timestamp + "\n" + credentialScope + "\n" + sha256hexStr(canonicalRequest)

	dateKey := hmacSHA256([]byte("TC3"+keys["SMS_TENCENT_SECRET_KEY"]), date)
	serviceKey := hmacSHA256(dateKey, service)
	signingKey := hmacSHA256(serviceKey, "tc3_request")
	signature := hex.EncodeToString(hmacSHA256(signingKey, stringToSign))

	authHeader := fmt.Sprintf(
		"TC3-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s",
		keys["SMS_TENCENT_SECRET_ID"], credentialScope, signedHeaders, signature,
	)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://"+host, bytes.NewReader(payload))
	if err != nil {
		return fmt.Errorf("tencent: build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Host", host)
	req.Header.Set("X-TC-Action", "SendSms")
	req.Header.Set("X-TC-Version", "2021-01-11")
	req.Header.Set("X-TC-Timestamp", timestamp)
	req.Header.Set("X-TC-Region", "ap-guangzhou")
	req.Header.Set("Authorization", authHeader)

	resp, err := t.cli.Do(req)
	if err != nil {
		return fmt.Errorf("tencent: http: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 8192))
	var result struct {
		Response struct {
			SendStatusSet []struct {
				Code    string `json:"Code"`
				Message string `json:"Message"`
			} `json:"SendStatusSet"`
			Error struct {
				Code    string `json:"Code"`
				Message string `json:"Message"`
			} `json:"Error"`
		} `json:"Response"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return fmt.Errorf("tencent: parse response: %w", err)
	}
	if result.Response.Error.Code != "" {
		return fmt.Errorf("tencent: API error %s: %s",
			result.Response.Error.Code, result.Response.Error.Message)
	}
	if len(result.Response.SendStatusSet) > 0 && result.Response.SendStatusSet[0].Code != "Ok" {
		s := result.Response.SendStatusSet[0]
		return fmt.Errorf("tencent: send error %s: %s", s.Code, s.Message)
	}
	return nil
}

func sha256hex(b []byte) string {
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}

func sha256hexStr(s string) string {
	return sha256hex([]byte(s))
}

func hmacSHA256(key []byte, data string) []byte {
	h := hmac.New(sha256.New, key)
	h.Write([]byte(data))
	return h.Sum(nil)
}
