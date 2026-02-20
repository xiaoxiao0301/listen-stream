# Listen Stream — 实现阶段 Prompt 文档

> 生成日期：2026-02-20  
> 本文档基于三项架构决策展开，每个 Prompt 可直接交给开发者或 AI 编码 Agent 执行。

---

## 已确认的三项架构决策

### D-A：Admin / User 使用独立 JWT 密钥

- `USER_JWT_SECRET`：存于 `SystemConfig` 表，键名 `USER_JWT_SECRET`，AES-256-GCM 加密，Admin 可在 JWT 配置页修改；修改后**仅使所有普通用户 Token 失效**，Admin 会话不受影响。
- `ADMIN_JWT_SECRET`：存于 `SystemConfig` 表，键名 `ADMIN_JWT_SECRET`，同样加密；仅 `super_admin` 可修改，修改后仅使所有管理员 Token 失效。
- 两套密钥签发的 JWT Claims 中须包含 `aud` 字段（`"user"` / `"admin"`），服务端验证时先校验 `aud` 再选择对应密钥。

### D-B：歌曲相关资源不建表，只存第三方 ID

- `Favorite`、`History`、`UserPlaylist` 中只存 `targetId`（第三方 `song_mid` / `album_mid` / `singer_mid`）和 `type` 字符串。
- 不存储歌曲名、封面 URL、时长等元数据，所有展示字段通过代理层按需拉取并由客户端缓存。
- 这意味着 `UserPlaylist.songs` 改为独立的 `PlaylistSong` 关联表，只存 `playlistId` + `songMid` + `sortOrder`，无需 Json 列。

### D-C：Refresh Token 轮换使用 Redis 原子锁

- RT 使用 Redis Whitelist 管理：登录时将 `RT_hash` 以 `SETNX rt:{device_id}` 写入 Redis，TTL = REFRESH_TOKEN_TTL。
- 使用 RT 换新 AT 时，用 Redis `GETDEL rt:{device_id}` 原子读取并删除：
  - 若返回值与请求中 RT hash 匹配 → 颁发新 AT + 新 RT，写入新 RT hash。
  - 若返回 `nil`（已被使用或过期）→ 视为 RT 重放攻击，返回 `401`，强制该设备重新登录。
- 并发请求抢同一 RT：第一个请求 `GETDEL` 成功，第二个收到 `nil`，直接拒绝，不产生竞争条件。

---

## Phase 1 — 接口契约

### Prompt 1.1 — OpenAPI 规范（后端全路由定义）

**目标**：生成完整的 `openapi.yaml`，覆盖所有后端路由，作为 Track A/B/C 并行开发的唯一契约基准。

**技术栈**：OpenAPI 3.1，YAML 格式，存放于 `listen_stream_server/docs/openapi.yaml`。

**必须包含的路由组及要求**：

```
/auth/*
  POST /auth/sms/send
    Body: { phone: string (E.164格式) }
    Response 200: { message: "ok" }
    Response 429: { code: "RATE_LIMITED", retryAfter: number }

  POST /auth/sms/verify
    Body: { phone: string, code: string }
    Response 200: { accessToken: string, refreshToken: string, expiresIn: number, deviceId: string }
    Response 400: { code: "INVALID_CODE" | "CODE_EXPIRED" }

  POST /auth/refresh
    Body: { refreshToken: string, deviceId: string }
    Response 200: { accessToken: string, refreshToken: string, expiresIn: number }
    Response 401: { code: "TOKEN_REUSED" | "TOKEN_EXPIRED" }

  POST /auth/logout
    Header: Authorization Bearer
    Body: { deviceId: string }
    Response 204

/proxy/*  (均需 Authorization Bearer，aud="user")
  GET /proxy/recommend/banner
  GET /proxy/recommend/daily
  GET /proxy/recommend/playlist
  GET /proxy/recommend/new/songs?type=
  GET /proxy/recommend/new/albums?type=
  GET /proxy/playlist/category
  GET /proxy/playlist/information?number=&size=&sort=&id=
  GET /proxy/playlist/detail?dissid=
  GET /proxy/artist/category
  GET /proxy/artist/list?area=&sex=&genre=&index=&page=&size=
  GET /proxy/artist/detail?id=&page=
  GET /proxy/artist/albums?id=&page=&size=
  GET /proxy/artist/mvs?id=&page=&size=
  GET /proxy/artist/songs?id=&page=&size=
  GET /proxy/rankings/list
  GET /proxy/rankings/detail?id=&page=&size=&period=
  GET /proxy/radio/category
  GET /proxy/radio/songlist?id=
  GET /proxy/mv/category
  GET /proxy/mv/list?area=&version=&page=&size=
  GET /proxy/mv/detail?id=
  GET /proxy/album/detail?id=
  GET /proxy/album/songs?id=
  GET /proxy/search/hotkey
  GET /proxy/search?keyword=&type=&page=&size=
  GET /proxy/lyric?id=
  全部响应头须包含 ETag，支持 If-None-Match → 304

/user/*  (均需 Authorization Bearer，aud="user")
  GET  /user/favorites?type=&page=&size=
  POST /user/favorites          Body: { type: "song"|"album"|"singer", targetId: string }
  DELETE /user/favorites/:id
  GET  /user/history?page=&size=
  POST /user/history            Body: { songMid: string, progress: number }
  GET  /user/playlists
  POST /user/playlists          Body: { name: string }
  GET  /user/playlists/:id
  PUT  /user/playlists/:id      Body: { name?: string }
  DELETE /user/playlists/:id
  POST /user/playlists/:id/songs    Body: { songMid: string, sortOrder?: number }
  DELETE /user/playlists/:id/songs/:songMid
  GET  /user/progress?songMid=
  POST /user/progress           Body: { songMid: string, progress: number }
  GET  /user/sync?since=        Body: — , Response: { favorites: [], history: [], playlists: [], updatedAt: string }
  GET  /user/devices
  DELETE /user/devices/:deviceId

/admin/*  (均需 Authorization Bearer，aud="admin")
  POST /admin/auth/login        Body: { username, password, totpCode? }
  POST /admin/auth/logout
  GET  /admin/setup/status      无鉴权，返回 { initialized: boolean }
  POST /admin/setup/init        无鉴权，Body: { username, password, smsSetting: {...} }
  GET/PUT /admin/config/api
  GET/PUT /admin/config/jwt     PUT 需 super_admin，返回 { affectedSessions: number }
  GET/PUT /admin/config/sms
  POST /admin/config/api/test   触发连通性测试
  GET /admin/users?page=&size=&phone=
  PUT /admin/users/:id/role     需 super_admin
  PUT /admin/users/:id/status
  DELETE /admin/devices/:deviceId
  GET /admin/logs/operations?page=&size=&type=
  GET /admin/logs/proxy?page=&size=&status=
  GET /admin/stats/overview
```

**每个路由须定义**：
- 完整的 requestBody schema（含字段类型、校验规则、是否必填）
- 所有可能的 response schema（含错误码枚举）
- 需要鉴权的路由标注 `securitySchemes: BearerAuth`
- 所有列表接口统一分页响应格式：`{ data: [], total: number, page: number, size: number }`

**验收标准**：`openapi.yaml` 能通过 `swagger-parser` 校验无错误，可直接导入 Postman 生成完整 Collection。

---

### Prompt 1.2 — WebSocket 事件协议规范

**目标**：生成 `listen_stream_server/docs/ws-protocol.md`，定义 WebSocket 双向通信的全部事件类型。

**连接鉴权**：
- 客户端升级 WS 时，在 query string 携带 `?token=<accessToken>`，服务端握手阶段验证 `aud="user"`，验证失败直接关闭连接（code 4001）。

**必须定义的事件（服务端 → 客户端推送）**：

```
event: "favorite.added"
payload: { type: "song"|"album"|"singer", targetId: string, createdAt: string }

event: "favorite.removed"
payload: { id: string, type: string, targetId: string }

event: "playlist.created"
payload: { id: string, name: string, createdAt: string }

event: "playlist.updated"
payload: { id: string, name?: string, updatedAt: string }

event: "playlist.deleted"
payload: { id: string }

event: "playlist.songs_changed"
payload: { playlistId: string, action: "add"|"remove", songMid: string, sortOrder?: number }

event: "progress.updated"
payload: { songMid: string, progress: number, updatedAt: string }

event: "device.kicked"
payload: { reason: "max_devices"|"admin_force"|"jwt_rotated" }

event: "config.jwt_rotated"
payload: { message: "re-login required" }
```

**客户端 → 服务端**（仅保活，所有写操作走 HTTP）：

```
event: "ping"
payload: {}

服务端响应：
event: "pong"
payload: { serverTime: string }
```

**消息格式（统一）**：

```json
{ "event": "<event_type>", "payload": { ... }, "ts": "<ISO8601>" }
```

**须定义**：重连策略（指数退避，最大 30s，前台 30s 无消息自动发 ping），以及客户端收到 `device.kicked` 后的行为（清除本地 Token，跳转登录页）。

---

## Phase 2 — 后端基础层（Go）

> 所有 4 个服务共享同一 PostgreSQL 实例和 Redis 实例，通过 `DATABASE_URL` / `REDIS_URL` 环境变量注入。

### Prompt 2.1 — SQL 迁移与 sqlc 配置

**目标**：在 `listen_stream_server/shared/db/` 目录下创建完整的 SQL 迁移文件和 sqlc 配置，所有服务通过 sqlc 生成的类型安全代码访问数据库。不使用 ORM。

**技术栈**：PostgreSQL 15、golang-migrate、sqlc v2。

**结构**：

```
shared/db/
├── migrations/
│   ├── 001_init.up.sql
│   └── 001_init.down.sql
├── queries/
│   ├── users.sql
│   ├── devices.sql
│   ├── favorites.sql
│   ├── history.sql
│   ├── playlists.sql
│   ├── system_configs.sql
│   ├── admin_users.sql
│   └── operation_logs.sql
└── sqlc.yaml
```

**`001_init.up.sql` 完整内容**：

```sql
CREATE TYPE role AS ENUM ('USER', 'ADMIN', 'SUPER_ADMIN');

CREATE TABLE users (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  phone       TEXT UNIQUE NOT NULL,
  role        role NOT NULL DEFAULT 'USER',
  disabled    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE devices (
  id             TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id      TEXT UNIQUE NOT NULL,
  platform       TEXT NOT NULL,
  rt_hash        TEXT NOT NULL,
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ON devices (user_id);

CREATE TABLE system_configs (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by TEXT NOT NULL
);

CREATE TABLE admin_users (
  id            TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  username      TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role          role NOT NULL DEFAULT 'ADMIN',
  totp_secret   TEXT,
  disabled      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE favorites (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL,
  target_id  TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, type, target_id)
);
CREATE INDEX ON favorites (user_id, type);
CREATE INDEX ON favorites (user_id, created_at DESC);

CREATE TABLE history (
  id        TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  song_mid  TEXT NOT NULL,
  progress  INT NOT NULL DEFAULT 0,
  played_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ON history (user_id, played_at DESC);

CREATE TABLE user_playlists (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE playlist_songs (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  playlist_id TEXT NOT NULL REFERENCES user_playlists(id) ON DELETE CASCADE,
  song_mid    TEXT NOT NULL,
  sort_order  INT NOT NULL,
  added_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (playlist_id, song_mid)
);
CREATE INDEX ON playlist_songs (playlist_id, sort_order);

CREATE TABLE operation_logs (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  admin_id   TEXT NOT NULL,
  action     TEXT NOT NULL,
  target_id  TEXT,
  before_val TEXT,
  after_val  TEXT,
  ip         TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ON operation_logs (created_at DESC);
```

**`sqlc.yaml`**（每个服务各有一份，指向同一 queries 目录中属于自己的文件）：

```yaml
version: "2"
sql:
  - engine: "postgresql"
    queries: "../../shared/db/queries/users.sql"
    schema: "../../shared/db/migrations/"
    gen:
      go:
        package: "repo"
        out: "internal/repo"
        emit_json_tags: true
        emit_pointers_for_null_types: true
```

**`queries/users.sql` 示例**（其余文件类似）：

```sql
-- name: GetUserByPhone :one
SELECT * FROM users WHERE phone = $1;

-- name: GetUserByID :one
SELECT * FROM users WHERE id = $1;

-- name: UpsertUser :one
INSERT INTO users (phone) VALUES ($1)
ON CONFLICT (phone) DO UPDATE SET updated_at = NOW()
RETURNING *;

-- name: SetUserDisabled :exec
UPDATE users SET disabled = $2, updated_at = NOW() WHERE id = $1;

-- name: SetUserRole :exec
UPDATE users SET role = $2, updated_at = NOW() WHERE id = $1;
```

**验收标准**：
1. `golang-migrate -path shared/db/migrations -database $DATABASE_URL up` 执行无错误
2. `sqlc generate` 在每个服务的 `internal/repo/` 目录生成 `.go` 文件，且 `go build ./...` 通过
3. 所有生成的 Go 结构体字段类型与 SQL 列类型严格对应，无 `interface{}`

---

### Prompt 2.2 — Redis Client + ConfigService（Go）

**目标**：在 4 个服务中各自实现 `internal/config/config_service.go` 和 `pkg/rdb/redis.go`，提供加密配置读写和 Redis 操作封装。

**加密规范（AES-256-GCM，标准库实现）**：

```go
// pkg/crypto/aes.go
// KEY 从环境变量 CONFIG_ENCRYPTION_KEY 读取，必须为 64 位 hex 字符串（32 字节）
// 进程启动时验证，不合法则 log.Fatal

// 加密输出格式（base64 编码的 JSON）：
// { "iv": "<hex>", "tag": "<hex>", "data": "<hex>" }

func Encrypt(key []byte, plaintext string) (string, error)
func Decrypt(key []byte, ciphertext string) (string, error)
```

**ConfigService 接口**：

```go
type ConfigService interface {
    // 从 system_configs 表读取并解密，带 30s 内存缓存（sync.Map + 时间戳）
    Get(ctx context.Context, key string) (string, error)

    // 加密后写入，清除对应内存缓存
    Set(ctx context.Context, key, value, updatedBy string) error

    // 批量读取，减少 DB 往返
    GetMany(ctx context.Context, keys []string) (map[string]string, error)

    // 启动时预热所有配置到内存
    Preload(ctx context.Context) error
}
```

**Redis Key 规范（`pkg/rdb/keys.go`，4 个服务共用）**：

```go
package rdb

import "fmt"

func KeyRT(deviceID string) string          { return fmt.Sprintf("rt:%s", deviceID) }
func KeySMSCode(phone string) string        { return fmt.Sprintf("sms:%s", phone) }
func KeySMSLimit(phone string) string       { return fmt.Sprintf("sms:limit:%s", phone) }
func KeyProxyCache(path, qHash string) string { return fmt.Sprintf("proxy:%s:%s", path, qHash) }
func KeyWSChannel(userID string) string     { return fmt.Sprintf("ws:user:%s", userID) }
func KeyAdminFail(username string) string   { return fmt.Sprintf("admin:fail:%s", username) }
func KeyCookieAlert() string               { return "cookie:alert" }
```

**RedisClient 封装（`pkg/rdb/client.go`）**：

```go
type Client struct { rdb *redis.Client }

func (c *Client) Get(ctx context.Context, key string) (string, error)
func (c *Client) Set(ctx context.Context, key, value string, ttl time.Duration) error
func (c *Client) SetNX(ctx context.Context, key, value string, ttl time.Duration) (bool, error)
func (c *Client) GetDel(ctx context.Context, key string) (string, error)  // D-C 原子操作
func (c *Client) Del(ctx context.Context, keys ...string) error
func (c *Client) Publish(ctx context.Context, channel, msg string) error
func (c *Client) Subscribe(ctx context.Context, channel string) *redis.PubSub
func (c *Client) TTL(ctx context.Context, key string) (time.Duration, error)
```

注意：`GetDel` 使用 `redis.NewScript("return redis.call('GETDEL', KEYS[1])")` 确保原子性（go-redis v9 原生支持 `GetDel` 命令，直接调用即可）。

**验收标准**：
1. `CONFIG_ENCRYPTION_KEY` 长度不为 64 时，进程启动输出明确错误并 `os.Exit(1)`
2. 相同 key 在 30s 内多次 `Get` 只查询一次数据库
3. `GetDel` 对不存在的 key 返回 `("", redis.Nil)` 而非 error

---

### Prompt 2.3 — JWT Service（Go，双密钥）

**目标**：在 `auth-svc` 中实现 `internal/service/jwt_service.go`，支持 D-A 决策的双密钥独立签发与验证。

**依赖**：`github.com/golang-jwt/jwt/v5`，以及上一步的 `ConfigService`。

**Claims 结构**：

```go
// internal/service/jwt_service.go

type UserClaims struct {
    jwt.RegisteredClaims
    DeviceID string `json:"device_id"`
    Role     string `json:"role"`
    // aud 通过 RegisteredClaims.Audience 设置为 []string{"user"}
}

type AdminClaims struct {
    jwt.RegisteredClaims
    Username string `json:"username"`
    Role     string `json:"role"`
    // aud 通过 RegisteredClaims.Audience 设置为 []string{"admin"}
}
```

**JWTService 接口**：

```go
type JWTService interface {
    // 每次签发前从 ConfigService 实时读取 USER_JWT_SECRET（30s 缓存）
    SignUserAccessToken(ctx context.Context, userID, deviceID, role string) (string, error)

    // 生成 Refresh Token：uuid v4 明文 + SHA-256 hash
    // 调用方负责将 hash 写入 Redis 和 Device.rt_hash
    IssueRefreshToken() (rt string, rtHash string)

    // 验证用户 AT，返回 Claims 或 error（不返回 nil + nil）
    VerifyUserToken(ctx context.Context, tokenStr string) (*UserClaims, error)

    // 签发 Admin AT（使用 ADMIN_JWT_SECRET）
    SignAdminAccessToken(ctx context.Context, adminID, username, role string) (string, error)

    // 验证 Admin AT
    VerifyAdminToken(ctx context.Context, tokenStr string) (*AdminClaims, error)

    // 读取配置的 TTL（秒）
    AccessTokenTTL(ctx context.Context) (int64, error)
    RefreshTokenTTL(ctx context.Context) (int64, error)
}
```

**密钥轮换行为**：
- `SignUserAccessToken` 每次通过 `ConfigService.Get("USER_JWT_SECRET")` 获取密钥（利用 30s 内存缓存），Admin 修改密钥后旧 AT 的 `VerifyUserToken` 因 HMAC 不匹配直接返回 error，无需额外失效逻辑。
- `ADMIN_JWT_SECRET` 完全独立，修改其中一个不影响另一个。

**`IssueRefreshToken` 实现**：

```go
func (s *jwtService) IssueRefreshToken() (string, string) {
    rt := uuid.NewString()             // github.com/google/uuid
    h := sha256.Sum256([]byte(rt))
    return rt, hex.EncodeToString(h[:])
}
```

**验收标准**：
1. 用 `USER_JWT_SECRET` 签发的 AT，调用 `VerifyAdminToken` 返回 `jwt.ErrTokenInvalidAudience`
2. 修改 `USER_JWT_SECRET` 后，旧 AT 调用 `VerifyUserToken` 返回 `jwt.ErrTokenSignatureInvalid`
3. 所有签发操作的密钥均来自 `ConfigService`，不得硬编码

---

### Prompt 2.4 — RBAC 中间件（Go Gin）

**目标**：实现 `internal/middleware/auth.go`，通过 Gin 中间件提供可组合的鉴权守卫，供 auth-svc、sync-svc、admin-svc 使用（以 shared 包或各自独立实现）。

**中间件实现**：

```go
// RequireUser 验证 Bearer Token（aud="user"），注入 UserClaims 到 gin.Context
func RequireUser(jwtSvc service.JWTService) gin.HandlerFunc {
    return func(c *gin.Context) {
        token := extractBearerToken(c)
        if token == "" {
            c.AbortWithStatusJSON(401, gin.H{"code": "MISSING_TOKEN"})
            return
        }
        claims, err := jwtSvc.VerifyUserToken(c.Request.Context(), token)
        if err != nil {
            c.AbortWithStatusJSON(401, gin.H{"code": "INVALID_TOKEN"})
            return
        }
        // D-A：校验 aud 防止 Admin Token 访问用户接口
        if !claims.Audience.Contains("user") {
            c.AbortWithStatusJSON(403, gin.H{"code": "WRONG_AUDIENCE"})
            return
        }
        // 查询 DB 确认用户未被禁用（每次请求查，利用 DB 连接池，延迟可接受）
        user, err := userRepo.GetUserByID(c.Request.Context(), claims.Subject)
        if err != nil || user.Disabled {
            c.AbortWithStatusJSON(403, gin.H{"code": "USER_DISABLED"})
            return
        }
        c.Set("user_claims", claims)
        c.Next()
    }
}

// RequireAdmin 验证 Bearer Token（aud="admin"）
func RequireAdmin(jwtSvc service.JWTService) gin.HandlerFunc { ... }

// RequireRole 角色守卫，在 RequireUser 或 RequireAdmin 之后链式使用
func RequireRole(minRole string) gin.HandlerFunc {
    return func(c *gin.Context) {
        role := getClaimsRole(c)   // 从 context 读取已注入的 claims
        if !hasPermission(role, minRole) {
            c.AbortWithStatusJSON(403, gin.H{"code": "INSUFFICIENT_ROLE"})
            return
        }
        c.Next()
    }
}
```

**Context helpers**：

```go
func GetUserClaims(c *gin.Context) *service.UserClaims
func GetAdminClaims(c *gin.Context) *service.AdminClaims
```

**路由注册示例**（须写入注释）：

```go
// 普通用户接口
userGroup := r.Group("/user", middleware.RequireUser(jwtSvc))

// Admin 接口
adminGroup := r.Group("/admin", middleware.RequireAdmin(jwtSvc))

// 仅 super_admin 可访问
adminGroup.PUT("/config/jwt", middleware.RequireRole("SUPER_ADMIN"), handler.UpdateJWTConfig)
```

**验收标准**：
1. 携带 `aud=admin` 的 Token 访问 `/user/*` 路由，返回 `403 WRONG_AUDIENCE`
2. `ADMIN` 角色访问 `RequireRole("SUPER_ADMIN")` 路由，返回 `403 INSUFFICIENT_ROLE`
3. 被禁用的用户使用未过期的 AT，返回 `403 USER_DISABLED`

---

## Track A — 后端业务层（Go）

### Prompt A.1 — SMS 适配器（auth-svc）

**目标**：实现 `auth-svc/internal/service/sms/` 目录，提供可在阿里云和腾讯云之间切换的短信发送抽象。

**接口与适配器**：

```go
// internal/service/sms/adapter.go
type Adapter interface {
    SendVerificationCode(ctx context.Context, phone, code string) error
}

// internal/service/sms/aliyun.go
type AliyunAdapter struct { /* AccessKeyID, AccessKeySecret, SignName, TemplateCode 来自 ConfigService */ }
func (a *AliyunAdapter) SendVerificationCode(ctx context.Context, phone, code string) error {
    // 调用阿里云 OpenAPI (dysmsapi.aliyuncs.com)
    // 使用 net/http + 阿里云 HMAC-SHA256 签名（避免引入 SDK，减少依赖）
}

// internal/service/sms/tencent.go
type TencentAdapter struct { /* SDKAppID, SecretID, SecretKey, SignName, TemplateID 来自 ConfigService */ }
func (a *TencentAdapter) SendVerificationCode(ctx context.Context, phone, code string) error { ... }

// 工厂：从 ConfigService 读取 SMS_PROVIDER 决定实例
func NewAdapter(ctx context.Context, cfg config.ConfigService) (Adapter, error)
```

**限流与验证码管理（`internal/service/sms_service.go`）**：

```go
type SMSService struct {
    adapter Adapter
    rdb     *rdb.Client
}

// SendCode：
// 1. CheckSMSLimit：redis.Get(KeySMSLimit(phone))，若存在返回 ErrRateLimited{RetryAfter}
// 2. 生成 6 位随机数字验证码（crypto/rand）
// 3. redis.Set(KeySMSCode(phone), code, 5*time.Minute)
// 4. redis.Set(KeySMSLimit(phone), "1", 60*time.Second)
// 5. 调用 adapter.SendVerificationCode
// 6. 若 5 失败：redis.Del(KeySMSCode(phone))，返回 ErrSMSDelivery

// VerifyCode：
// 1. redis.Get(KeySMSCode(phone))，若为 redis.Nil 返回 ErrCodeExpired
// 2. subtle.ConstantTimeCompare([]byte(stored), []byte(input)) != 1 → ErrInvalidCode
// 3. 验证通过：redis.Del(KeySMSCode(phone))（一次性）
func (s *SMSService) SendCode(ctx context.Context, phone string) error
func (s *SMSService) VerifyCode(ctx context.Context, phone, code string) error
```

**验收标准**：
1. 同一手机号 60s 内第二次 `SendCode` 返回 `ErrRateLimited`，不调用 SMS 网关
2. 验证码验证成功后，再次使用同一验证码返回 `ErrCodeExpired`
3. 切换 `SMS_PROVIDER` 只需修改 DB 配置，无需重新编译

---

### Prompt A.2 — Auth 路由（auth-svc，含 RT 原子锁）

**目标**：实现 `auth-svc/internal/handler/auth_handler.go`，核心是 `POST /auth/refresh` 的 D-C 原子锁逻辑。

**依赖注入结构**：

```go
type AuthHandler struct {
    jwtSvc  service.JWTService
    smsSvc  service.SMSService
    userRepo repo.Querier
    rdb     *rdb.Client
    cfgSvc  config.ConfigService
}
```

**`POST /auth/sms/send` 要点**：
- 用 Go 正则校验 E.164 格式（`^\+[1-9]\d{6,14}$`）
- 调用 `smsSvc.SendCode(ctx, phone)`
- 任何情况下 HTTP 200，不泄露验证码存在与否

**`POST /auth/sms/verify` 实现**：

```go
func (h *AuthHandler) VerifySMS(c *gin.Context) {
    // 1. 绑定请求体，校验 phone、code 非空
    // 2. smsSvc.VerifyCode(ctx, phone, code) — 失败 400 INVALID_CODE
    // 3. userRepo.UpsertUser(ctx, phone) — 幂等，返回 User 行
    // 4. 从 body 获取 deviceID（可选），未传则 uuid.NewString()
    // 5. 查询该 userID 的设备数量，与 ConfigService.Get("MAX_DEVICES") 比较
    //    若超出：按 last_active_at ASC 查出最老设备，Del(KeyRT(oldestDeviceID))，
    //            删除 Device DB 记录，通过 Redis Pub/Sub 发送 device.kicked 事件
    // 6. jwtSvc.SignUserAccessToken(ctx, user.ID, deviceID, user.Role)
    // 7. jwtSvc.IssueRefreshToken() → rt, rtHash
    // 8. rdb.SetNX(KeyRT(deviceID), rtHash, ttl)
    // 9. userRepo.UpsertDevice(ctx, UpsertDeviceParams{...rtHash...})
    // 10. 返回 { access_token, refresh_token, expires_in, device_id }
}
```

**`POST /auth/refresh` 原子锁实现（D-C 核心）**：

```go
func (h *AuthHandler) Refresh(c *gin.Context) {
    var req struct {
        RefreshToken string `json:"refresh_token" binding:"required"`
        DeviceID     string `json:"device_id" binding:"required"`
    }
    c.ShouldBindJSON(&req)

    // 1. 计算 rtHash
    sum := sha256.Sum256([]byte(req.RefreshToken))
    rtHash := hex.EncodeToString(sum[:])

    // 2. GETDEL — 原子读取并删除
    storedHash, err := h.rdb.GetDel(ctx, rdb.KeyRT(req.DeviceID))
    if errors.Is(err, redis.Nil) {
        // RT 不存在：可能已被使用（重放攻击）或已过期
        h.logger.Warn("RT_REUSED_OR_EXPIRED", ...)
        c.AbortWithStatusJSON(401, gin.H{"code": "TOKEN_REUSED"})
        return
    }

    // 3. 验证 hash 匹配
    if subtle.ConstantTimeCompare([]byte(storedHash), []byte(rtHash)) != 1 {
        c.AbortWithStatusJSON(401, gin.H{"code": "TOKEN_MISMATCH"})
        return
    }

    // 4. 确认 Device 仍存在
    device, err := h.deviceRepo.GetDeviceByDeviceID(ctx, req.DeviceID)
    if err != nil {
        c.AbortWithStatusJSON(401, gin.H{"code": "DEVICE_REVOKED"})
        return
    }

    // 5. 签发新 AT + 新 RT
    at, _ := h.jwtSvc.SignUserAccessToken(ctx, device.UserID, device.DeviceID, device.Role)
    newRT, newRTHash := h.jwtSvc.IssueRefreshToken()
    ttl := time.Duration(rtTTL) * time.Second
    h.rdb.SetNX(ctx, rdb.KeyRT(device.DeviceID), newRTHash, ttl)
    h.deviceRepo.UpdateDeviceRT(ctx, device.DeviceID, newRTHash)

    c.JSON(200, gin.H{"access_token": at, "refresh_token": newRT, "expires_in": atTTL})
}
```

**验收标准**：
1. 并发两次 `POST /auth/refresh` 使用同一 RT，只有一次返回 200，另一次返回 `401 TOKEN_REUSED`
2. 超出 `MAX_DEVICES` 时被踢出设备收到 Redis Pub/Sub 的 `device.kicked` 消息
3. 所有 401 在日志中记录完整原因，响应体只返回通用 code

---

### Prompt A.3 — API 代理层（proxy-svc，含 ETag）

**目标**：实现 `proxy-svc/` 完整服务，包含第三方 API 转发和 SHA-256 ETag 机制。

**核心结构**：

```go
// internal/upstream/client.go
type UpstreamClient struct {
    baseURL string      // 从 ConfigService 读取，每次请求前刷新（利用 30s 缓存）
    cookie  string
    httpCli *http.Client
}

func (u *UpstreamClient) Do(ctx context.Context, path, rawQuery string) ([]byte, error)

// internal/cache/proxy_cache.go
type ProxyCache struct { rdb *rdb.Client }

type CacheEntry struct {
    Body []byte
    ETag string
}

func (c *ProxyCache) Get(ctx context.Context, key string) (*CacheEntry, error)
func (c *ProxyCache) Set(ctx context.Context, key string, entry CacheEntry, ttl time.Duration) error
```

**handler 通用逻辑（`internal/handler/proxy_handler.go`）**：

```go
func (h *ProxyHandler) handle(c *gin.Context, upstreamPath string, ttl time.Duration) {
    query := c.Request.URL.RawQuery
    sortedQuery := sortQueryParams(query)
    qHash := sha256sum(sortedQuery)
    cacheKey := rdb.KeyProxyCache(upstreamPath, qHash)

    // 1. 从 Redis 读取缓存
    entry, err := h.cache.Get(c.Request.Context(), cacheKey)
    if err == nil {
        // 命中缓存
        c.Header("ETag", entry.ETag)
        c.Header("X-Cache", "HIT")
        // 支持 If-None-Match → 304
        if c.GetHeader("If-None-Match") == entry.ETag {
            c.Status(304)
            return
        }
        c.Data(200, "application/json", entry.Body)
        return
    }

    // 2. 未命中，调用上游
    if ttl == 0 {
        // TTL=0 的接口（播放URL/MV详情）直接透传，不写缓存
        body, err := h.upstream.Do(c.Request.Context(), upstreamPath, sortedQuery)
        if err != nil { c.JSON(502, gin.H{"code": "UPSTREAM_ERROR"}); return }
        c.Data(200, "application/json", body)
        return
    }

    body, err := h.upstream.Do(c.Request.Context(), upstreamPath, sortedQuery)
    if err != nil {
        c.Header("X-Cache", "STALE")
        // 尝试返回过期缓存（降级）
        ...
        c.JSON(502, gin.H{"code": "UPSTREAM_ERROR"})
        return
    }

    // 3. 计算 ETag，写入 Redis
    sum := sha256.Sum256(body)
    etag := fmt.Sprintf(`W/"%s"`, hex.EncodeToString(sum[:16]))
    h.cache.Set(c.Request.Context(), cacheKey, CacheEntry{Body: body, ETag: etag}, ttl)

    c.Header("ETag", etag)
    c.Header("X-Cache", "MISS")
    c.Data(200, "application/json", body)
}
```

**TTL 配置（`internal/config/ttl.go`）**：

```go
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
    "/radio/songlist":       0,              // 不缓存
    "/mv/category":          6 * time.Hour,
    "/mv/list":              1 * time.Hour,
    "/mv/detail":            0,              // 不缓存
    "/album/detail":         12 * time.Hour,
    "/album/songs":          12 * time.Hour,
    "/search/hotkey":        15 * time.Minute,
    "/search":               5 * time.Minute,
    "/lyric":                7 * 24 * time.Hour,
}
```

**路由注册（`cmd/server/main.go`）**：每个代理接口调用 `handler.handle(c, path, ProxyTTL[path])`，所有路由均加 `RequireUser` 中间件（auth-svc 和 proxy-svc 共享 JWT 验证逻辑，proxy-svc 自己实现轻量版中间件，只验证 aud + 签名，不查 DB）。

**验收标准**：
1. 首次请求响应头 `X-Cache: MISS`，ETag 非空
2. 第二次相同路径响应头 `X-Cache: HIT`，无上游调用
3. 携带正确 `If-None-Match` 返回 304，body 为空
4. `/mv/detail` 每次触发上游调用，Redis 中无对应 key

---

### Prompt A.4 — 代理层全模块补全（proxy-svc）

**目标**：在 A.3 完成的框架上，为所有剩余模块注册 Gin 路由。

每个模块在 `internal/handler/` 下创建独立文件，示例：

```go
// internal/handler/singer_handler.go
func (h *ProxyHandler) RegisterSingerRoutes(rg *gin.RouterGroup) {
    rg.GET("/artist/category", func(c *gin.Context) {
        h.handle(c, "/artist/category", ProxyTTL["/artist/category"])
    })
    rg.GET("/artist/list", func(c *gin.Context) {
        // 校验 query params（area, sex, genre, index, page, size 均有默认值）
        if err := validateArtistListParams(c); err != nil {
            c.AbortWithStatusJSON(400, gin.H{"code": "INVALID_PARAMS", "detail": err.Error()})
            return
        }
        h.handle(c, "/artist/list", ProxyTTL["/artist/list"])
    })
    // ... artist/detail, artist/albums, artist/mvs, artist/songs
}
```

需注册的文件：`recommend_handler.go`、`playlist_handler.go`、`singer_handler.go`、`ranking_handler.go`、`radio_handler.go`、`mv_handler.go`、`album_handler.go`、`search_handler.go`、`lyric_handler.go`。

**参数校验规则**：
- 所有分页参数 `page` 默认 1，`size` 默认 20，`size` 上限 100
- 缺少必填参数时返回 `400 INVALID_PARAMS`，不触发上游请求

**验收标准**：所有路由可通过 openapi.yaml 生成的 Postman Collection 冒烟测试。

---

### Prompt A.5 — 用户数据同步服务（sync-svc）

**目标**：实现 `sync-svc/internal/` 的收藏、历史、歌单 CRUD，以及 `/user/sync` 离线拉取接口。

**历史写入防溢出（`internal/repo` SQL 查询中执行）**：

```sql
-- name: TrimHistory :exec
-- 写入新记录后调用，保留最新 500 条
DELETE FROM history
WHERE user_id = $1
  AND id NOT IN (
    SELECT id FROM history
    WHERE user_id = $1
    ORDER BY played_at DESC
    LIMIT 500
  );
```

**收藏写入逻辑**：

```go
func (h *SyncHandler) AddFavorite(c *gin.Context) {
    // 1. 绑定请求体 { type, target_id }
    // 2. 写入 DB（INSERT ... ON CONFLICT DO NOTHING）
    // 3. 通过 Redis Pub/Sub 推送 WS 事件（排除当前 deviceID）
    //    rdb.Publish(ctx, rdb.KeyWSChannel(userID),
    //       json.Marshal(WsMsg{Event: "favorite.added", Payload: ..., Ts: time.Now()}))
    // 4. 200 返回
}
```

**`GET /user/sync?since=` 实现**：

```go
// since 为 RFC3339 时间戳
SELECT * FROM favorites WHERE user_id = $1 AND created_at > $2;
SELECT * FROM favorites WHERE user_id = $1 AND deleted_at > $2 AND deleted_at IS NOT NULL;
SELECT * FROM history WHERE user_id = $1 AND played_at > $2;
SELECT * FROM user_playlists WHERE user_id = $1 AND updated_at > $2;
-- ... 组合返回

// 响应：
// { favorites: [...], deleted_favorites: ["id1",...],
//   history: [...], playlists: [...], deleted_playlists: ["id1",...],
//   server_time: "2026-..." }
```

**歌单歌曲排序维护**：删除 `PlaylistSong` 后，在同一事务内执行 `UPDATE playlist_songs SET sort_order = sort_order - 1 WHERE playlist_id = $1 AND sort_order > $2` 重新编排顺序。

**验收标准**：
1. 第 501 条历史写入后，`SELECT COUNT(*) FROM history WHERE user_id = ?` 返回 500
2. `GET /user/sync?since=2026-01-01T00:00:00Z` 返回指定时间后的所有变更，含软删除项目
3. 单次收藏操作触发 Redis Pub/Sub 消息

---

### Prompt A.6 — WebSocket 实时推送网关（sync-svc）

**目标**：实现 `sync-svc/internal/ws/hub.go`，使用 gorilla/websocket 管理多设备连接，通过 Redis Pub/Sub 支持未来水平扩展。

**Hub 结构**：

```go
type Hub struct {
    // 内存连接表：userID → map[deviceID]*Client
    mu      sync.RWMutex
    clients map[string]map[string]*Client
    rdb     *rdb.Client
    logger  *zap.Logger
}

type Client struct {
    conn      *websocket.Conn
    userID    string
    deviceID  string
    send      chan []byte   // 发送缓冲 channel
}
```

**连接升级（Gin handler）**：

```go
func (h *WsHandler) Upgrade(c *gin.Context) {
    // 1. 从 query 取 token，调用 jwtSvc.VerifyUserToken
    // 2. 失败：ws.CloseMessage(4001, "UNAUTHORIZED")
    // 3. 升级为 WebSocket
    // 4. hub.Register(userID, deviceID, conn)
    // 5. 启动 readPump（处理 ping 消息）和 writePump（从 client.send 发送）goroutine
}
```

**事件广播**：

```go
// 本地广播（排除发起操作的 deviceID）
func (h *Hub) PushToUser(userID, excludeDeviceID string, msg []byte) {
    h.mu.RLock()
    defer h.mu.RUnlock()
    for devID, client := range h.clients[userID] {
        if devID != excludeDeviceID {
            select {
            case client.send <- msg:
            default:
                go h.unregister(userID, devID)  // 发送缓冲满，断开
            }
        }
    }
    // Redis Pub/Sub 广播（覆盖多实例场景）
    h.rdb.Publish(ctx, rdb.KeyWSChannel(userID), string(msg))
}
```

**Redis Pub/Sub 订阅**（启动时在 goroutine 中运行）：

```go
func (h *Hub) startPubSub(ctx context.Context) {
    pubsub := h.rdb.Subscribe(ctx, "ws:user:*") // 使用 psubscribe 模式订阅
    for msg := range pubsub.Channel() {
        userID := extractUserID(msg.Channel)
        h.localBroadcast(userID, []byte(msg.Payload))
    }
}
```

**保活**：服务端每 25s 遍历所有连接，发送 `{"event":"ping","ts":"..."}` ping frame，客户端 30s 无响应则关闭连接。

**验收标准**：
1. 用户设备 A 触发收藏，设备 B 的 WS 连接在 500ms 内收到 `favorite.added` 事件
2. 携带无效 Token 的升级请求被关闭，code 4001
3. 连接断开后 hub 内存中对应 entry 被清除，无 goroutine 泄漏

---

### Prompt A.7 — Cookie 自动刷新 Cron（sync-svc）

**目标**：实现 `sync-svc/internal/cron/cookie_refresh.go`，基于 `github.com/robfig/cron/v3` 动态注册 Cookie 刷新任务。

```go
type CookieRefreshCron struct {
    cron   *cron.Cron
    entryID cron.EntryID
    cfgSvc config.ConfigService
    rdb    *rdb.Client
    logger *zap.Logger
}

// Start：从 ConfigService 读取 COOKIE_REFRESH_CRON，注册任务
func (c *CookieRefreshCron) Start(ctx context.Context) error

// Restart：停止旧 entryID 对应任务，重新注册（Admin 修改表达式后调用）
func (c *CookieRefreshCron) Restart(ctx context.Context) error

// TriggerNow：手动立即执行（Admin 控制台"立即刷新"调用）
func (c *CookieRefreshCron) TriggerNow(ctx context.Context) error

// 任务执行逻辑：
// 1. ConfigService.Get(ctx, "COOKIE") — 读取当前 Cookie
// 2. 调用第三方刷新接口（从 API_BASE_URL 推导）
// 3. 成功：ConfigService.Set(ctx, "COOKIE", newCookie, "cron")
// 4. 失败：
//    rdb.Set(ctx, rdb.KeyCookieAlert(), "1", 24*time.Hour)
//    写入 operation_logs（action = "COOKIE_REFRESH_FAILED"）
//    logger.Error("cookie refresh failed", ...)
```

**验收标准**：
1. Cron 执行失败后，`redis.Get("cookie:alert")` 返回 `"1"`
2. Admin 修改 Cron 表达式并调用 `Restart` 后，新表达式生效，旧任务不再运行
3. `TriggerNow` 可在无 HTTP 请求时通过单元测试直接调用验证

---

## Track B — Admin 控制台（Go + Next.js）

### Prompt B.1 — Admin 认证路由（admin-svc）

**目标**：实现 `admin-svc/internal/handler/auth_handler.go`，使用独立 `ADMIN_JWT_SECRET`（D-A 决策）。

**`POST /admin/auth/login` 实现**：

```go
func (h *AdminAuthHandler) Login(c *gin.Context) {
    var req struct {
        Username string `json:"username" binding:"required"`
        Password string `json:"password" binding:"required"`
        TOTPCode string `json:"totp_code"`
    }
    c.ShouldBindJSON(&req)

    // 1. 登录失败次数限制
    failKey := rdb.KeyAdminFail(req.Username)
    failCount, _ := h.rdb.Get(ctx, failKey)
    if toInt(failCount) >= 5 {
        ttl, _ := h.rdb.TTL(ctx, failKey)
        c.JSON(429, gin.H{"code": "ACCOUNT_LOCKED", "unlock_at": time.Now().Add(ttl)})
        return
    }

    // 2. 查询 AdminUser
    admin, err := h.adminRepo.GetAdminByUsername(ctx, req.Username)
    if err != nil {
        h.rdb.Set(ctx, failKey, strconv.Itoa(toInt(failCount)+1), 15*time.Minute)
        c.JSON(401, gin.H{"code": "INVALID_CREDENTIALS"})
        return
    }

    // 3. Argon2id 验证（golang.org/x/crypto/argon2）
    if !argon2id.Verify(req.Password, admin.PasswordHash) {
        h.rdb.Set(ctx, failKey, strconv.Itoa(toInt(failCount)+1), 15*time.Minute)
        c.JSON(401, gin.H{"code": "INVALID_CREDENTIALS"})
        return
    }

    // 4. TOTP 验证（admin.TotpSecret != nil 时必须传 totp_code）
    if admin.TotpSecret != nil {
        if req.TOTPCode == "" {
            c.JSON(401, gin.H{"code": "TOTP_REQUIRED"})
            return
        }
        if !totp.Validate(req.TOTPCode, *admin.TotpSecret) {  // github.com/xlzd/gotp
            c.JSON(401, gin.H{"code": "INVALID_TOTP"})
            return
        }
    }

    // 5. 清除登录失败计数
    h.rdb.Del(ctx, failKey)

    // 6. 签发 Admin AT（ADMIN_JWT_SECRET，不签 RT）
    adminTTL, _ := h.cfgSvc.Get(ctx, "ADMIN_TOKEN_TTL")
    at, _ := h.jwtSvc.SignAdminAccessToken(ctx, admin.ID, admin.Username, string(admin.Role))

    // 7. 记录操作日志
    h.auditLog(ctx, admin.ID, "ADMIN_LOGIN", nil, c.ClientIP())

    c.JSON(200, gin.H{"access_token": at, "expires_in": toInt64(adminTTL)})
}
```

**验收标准**：
1. 连续 5 次错误密码后，第 6 次返回 `429 ACCOUNT_LOCKED`，携带 `unlock_at` 时间戳
2. 开启 TOTP 的账户，不传 `totp_code` 返回 `401 TOTP_REQUIRED`
3. Admin AT 无法通过 proxy-svc / sync-svc 的 `RequireUser` 中间件（aud 不匹配）

---

### Prompt B.2 — 系统初始化向导（admin-svc）

**目标**：实现 `admin-svc/internal/handler/setup_handler.go`，提供无鉴权的初始化接口，以及 CLI 应急重置工具。

**`GET /admin/setup/status`**（无鉴权）：

```go
func (h *SetupHandler) Status(c *gin.Context) {
    count, _ := h.adminRepo.CountAdminUsers(ctx)
    c.JSON(200, gin.H{"initialized": count > 0})
}
```

**`POST /admin/setup/init`**（无鉴权，但检查未初始化）：

```go
func (h *SetupHandler) Init(c *gin.Context) {
    // 0. 再次检查未初始化（并发防护）
    // 1. 绑定请求体：username / password / site_name / sms_provider / sms 相关字段
    // 2. 密码格式校验（正则：≥12位，含大小写+数字+特殊字符）
    // 3. 在 DB 事务中：
    //    a. 生成 USER_JWT_SECRET（crypto/rand 64字节 → hex）
    //    b. 生成 ADMIN_JWT_SECRET（独立，同上）
    //    c. cfgSvc.Set(ctx, "USER_JWT_SECRET", secret, "setup")...批量写入所有配置
    //    d. admin_users 插 super_admin（passwordHash = argon2id.Hash(password)）
    //    e. 提交事务
    // 4. cfgSvc.Preload(ctx) — 刷新内存缓存
    c.JSON(201, gin.H{"message": "initialized"})
}
```

**CLI 应急重置工具（`admin-svc/cmd/reset_admin/main.go`）**：

```go
// 用法：./reset_admin --username=xxx --password=xxx
// 直接访问 DB（不经过 HTTP），用于 super_admin 全部失效时的应急恢复
// 要求 DATABASE_URL 和 CONFIG_ENCRYPTION_KEY 环境变量正确
// 执行后打印"已重置超级管理员账号，请立即登录并修改密码"
func main() {
    // 解析 flag，连接 DB，argon2id hash 密码，upsert admin_user（role=SUPER_ADMIN）
}
```

**验收标准**：
1. `initialized=true` 时调用 `POST /admin/setup/init` 返回 `403 ALREADY_INITIALIZED`
2. 初始化完成后 `GET /admin/setup/status` 返回 `{ "initialized": true }`
3. CLI 工具在无 Fastify/Gin 服务运行时可独立执行（`go run ./cmd/reset_admin`）

---

### Prompt B.3 — Admin 配置管理接口（admin-svc）

**目标**：实现 `admin-svc/internal/handler/config_handler.go`，提供 API 配置、JWT 配置、SMS 配置管理。

**脱敏函数（`internal/util/mask.go`）**：

```go
// maskSecret("abcdefghij1234") → "abcdef***1234"
func MaskSecret(s string) string {
    if len(s) <= 10 { return "***" }
    return s[:6] + "***" + s[len(s)-4:]
}
```

**`PUT /admin/config/jwt`（super_admin 专用）**：

```go
func (h *ConfigHandler) UpdateJWTConfig(c *gin.Context) {
    // 1. 绑定可选字段：user_jwt_secret / admin_jwt_secret / access_token_ttl / refresh_token_ttl / max_devices
    // 2. 若包含 user_jwt_secret：
    //    a. cfgSvc.Set(ctx, "USER_JWT_SECRET", newSecret, adminUsername)
    //    b. 批量 DEL rt:* —— go-redis Scan 遍历 rt: 前缀的 key，分批 DEL
    //    c. 统计删除数量 affectedSessions
    //    d. 通过 Redis Pub/Sub 向所有用户广播：
    //       遍历 all user_ids（DB 查）→ Publish(KeyWSChannel(uid), json.Marshal(configRotatedMsg))
    //    e. 写 OperationLog（before/after 均为 "[密钥已更换]"）
    //    f. 响应中返回 { affected_sessions: N }
    // 3. 若包含 admin_jwt_secret：仅更新配置，无 WS 推送
}
```

**`POST /admin/config/api/test`**：

```go
func (h *ConfigHandler) TestAPIConnection(c *gin.Context) {
    start := time.Now()
    baseURL, _ := h.cfgSvc.Get(ctx, "API_BASE_URL")
    cookie, _ := h.cfgSvc.Get(ctx, "COOKIE")
    // 发起 GET {baseURL}/recommend/banner，附加 Cookie 头，超时 5s
    // 返回 { success, status_code, latency_ms, error? }
}
```

**验收标准**：
1. GET 响应中 `APP_SECRET` / `COOKIE` 字段被 `MaskSecret` 处理，不出现完整值
2. 修改 `USER_JWT_SECRET` 后，旧用户 AT 验证失败，在线 WS 客户端收到 `config.jwt_rotated`
3. 所有 PUT 操作在 `operation_logs` 表中有对应记录（含 ip、admin_id、action）

---

### Prompt B.4 — Admin 用户管理接口（admin-svc）

**目标**：实现 `admin-svc/internal/handler/user_handler.go`，提供用户列表、状态变更和设备吊销。

**`GET /admin/users` 分页查询**：

```go
// SQL（sqlc 生成）：
-- name: ListUsers :many
SELECT u.*, COUNT(d.id) as device_count
FROM users u
LEFT JOIN devices d ON d.user_id = u.id
WHERE ($1::text = '' OR u.phone LIKE $1 || '%')
GROUP BY u.id
ORDER BY u.created_at DESC
LIMIT $2 OFFSET $3;
```

**`PUT /admin/users/:id/status`**：

```go
func (h *UserHandler) SetStatus(c *gin.Context) {
    // 1. 获取 claims，验证 super_admin 才能禁用其他 admin
    // 2. 若 disabled=true：
    //    a. UPDATE users SET disabled=true
    //    b. 查出该用户所有 device_id
    //    c. 批量 DEL rt:{deviceID}
    //    d. 向该用户所有在线 WS 连接推送 device.kicked{reason:"admin_force"}
    // 3. 写 OperationLog
}
```

**`DELETE /admin/devices/:deviceId`**：

```go
// 1. 验证 deviceID 存在（可属于任意用户）
// 2. rdb.Del(KeyRT(deviceID))
// 3. DELETE FROM devices WHERE device_id = $1
// 4. Redis Pub/Sub 推送 device.kicked{reason:"admin_force"} 给该设备
// 5. 写 OperationLog
```

**RequireUser 中间件补充**：在 JWT 验证通过后，查一次 `users.disabled`，若为 `true` 返回 `403 USER_DISABLED`（此步骤在 Prompt 2.4 的中间件中已包含，此处是提醒确认实现）。

**验收标准**：
1. 禁用用户后，该用户的在线 WS 连接立即收到 `device.kicked` 事件
2. `super_admin` 禁用自己返回 `403 CANNOT_DISABLE_SELF`
3. 分页查询返回 `device_count`，无数据时返回 `{ data: [], total: 0, page: 1, size: 20 }`

---

### Prompt B.5 — Admin Web 前端

**目标**：实现 `listen_stream_admin/` Vite + React 项目，完成所有 Admin 控制台页面。

**技术栈**：Vite 5、React 19、React Router v7（SPA 模式）、shadcn/ui、Tailwind CSS v4、Zustand、TanStack Query v5、Recharts、Axios。

**项目结构**：
```
listen_stream_admin/
├── src/
│   ├── api/          # axios 实例 + 各模块请求函数
│   ├── components/   # 共享 UI 组件（含 shadcn/ui 组件）
│   ├── hooks/        # 自定义 hooks（useAuth、useApiQuery 等）
│   ├── pages/        # 页面组件（对应路由）
│   ├── stores/       # Zustand store（authStore）
│   ├── router.tsx    # React Router 路由配置 + 守卫
│   └── main.tsx      # 入口
├── vite.config.ts
├── tailwind.config.ts
└── index.html
```

**路由守卫**：在 `router.tsx` 中使用 `<ProtectedRoute>` 组件检查 `authStore.token`；未初始化时通过 loader 检测 `/admin/setup/status` 并重定向。

**页面及交互要求**：

**`/setup` — 初始化向导（4步骤）**：
- 步骤一：自动检测 `/admin/setup/status`，`initialized=true` 时跳转 `/login`
- 步骤二：超级管理员账号设置，密码强度实时检测（正则 + 视觉反馈）
- 步骤三：SMS 配置，含"发送测试短信"按钮验证
- 步骤四：完成，3s 倒计时跳转 `/login`

**`/login` — 管理员登录**：
- 用户名 + 密码表单
- 提交成功后若响应为 `{ code: "TOTP_REQUIRED" }`，展示 TOTP 输入框（6位数字）
- 错误状态明确区分：账号不存在 / 密码错误 / TOTP 错误 / 账号锁定（展示解锁倒计时）
- 登录成功后 `authStore.setToken(token)` 并通过 `useNavigate` 跳转 `/dashboard`

**`/dashboard` — 仪表盘**：
- 使用 TanStack Query `useQuery` + `refetchInterval: 30_000` 轮询 `/admin/stats/overview`
- Cookie 告警红点通过响应字段 `cookie_alert: boolean` 驱动，无需额外接口

**`/api-config` — API 配置页**：
- 表单展示当前配置（脱敏）
- 编辑模式下显示完整输入框（密文字段有"显示/隐藏"切换）
- "连通性测试"按钮，实时展示延迟和状态码
- Cookie 刷新时间表达式可视化（Cron 表达式解析为人类可读文字）

**`/jwt-config` — JWT 配置页**：
- 修改 `USER_JWT_SECRET` 时展示确认对话框：**"此操作将立即注销所有已登录用户（约 X 个在线设备）"**，需要手动输入 "CONFIRM" 才能提交

**`/users` — 用户管理页**：
- 表格含搜索（手机号前缀）、禁用/启用按钮、在线设备数量
- 点击用户展开设备列表，每个设备可单独吊销

**`/logs` — 日志页**：
- 操作日志和代理日志 Tab 切换
- 操作日志展示 before/after diff（脱敏）

**API Client 封装（`src/api/client.ts`）**：

```ts
// axios 实例，baseURL 从 import.meta.env.VITE_API_BASE_URL 读取
// 请求拦截器：附加 Authorization: Bearer <token>（从 authStore 读取）
// 响应拦截器：401 时 authStore.clearToken() + navigate('/login')
```

**验收标准**：
1. 首次访问任意 Admin 页面，若未初始化自动跳转 `/setup`
2. 未登录访问 `/dashboard` 等受保护页面，跳转 `/login`
3. 修改 JWT 密钥的确认对话框，不输入 "CONFIRM" 无法点击提交
4. `vite build` 产物可直接通过 `nginx` 静态托管，所有路由 fallback 到 `index.html`

---

## Track C — Flutter 客户端

### Prompt C.1 — 网络层封装

**目标**：实现 `lib/core/network/` 目录，提供支持 JWT 自动刷新、ETag、重试的 Dio 实例和 WebSocket 客户端。

**Dio 实例配置（`network_client.dart`）**：

```dart
// 全局单实例（通过 Riverpod Provider 管理）
class NetworkClient {
  late final Dio _dio;

  // 拦截器链（顺序重要）：
  // 1. AuthInterceptor：在请求头注入 "Authorization: Bearer <accessToken>"
  // 2. ETagInterceptor：请求时附加 "If-None-Match"（从 ETag 缓存读取），
  //                     响应时存储新 ETag，304 响应时返回本地缓存数据（透明处理，让上层只看到 200）
  // 3. RetryInterceptor：网络错误时指数退避重试（最多3次，间隔 1s/2s/4s）
  // 4. LogInterceptor：DEBUG 模式下打印请求/响应
}
```

**AuthInterceptor 的 Token 刷新逻辑（重点）**：

```dart
// 收到 401 时：
// 1. 取消当前请求
// 2. 检查是否已有刷新请求在进行中（用 Completer 防并发，多个 401 只触发一次刷新）
// 3. 调用 POST /auth/refresh，传入 { refreshToken, deviceId }
// 4a. 刷新成功：存储新 AT 和 RT，重试原请求
// 4b. 刷新失败（401 TOKEN_REUSED 等）：调用 AuthNotifier.logout()，导航到登录页
// 全程使用单例 Completer，避免并发多次刷新
```

**ETagInterceptor 实现要求**：
- ETag 存储于 Isar（`ETagCache` 集合：`{ url: String, etag: String, updatedAt: DateTime }`）
- `If-None-Match` 仅在有缓存数据时附加（无缓存时不发送，避免意外 304）
- 收到 304 时，从 Isar 中读取对应请求的缓存响应体，构造一个等效的 200 响应返回上层

**验收标准**：
1. AT 过期后，下一个请求自动触发刷新，原请求在刷新后无感重试
2. 同时发出 3 个请求全部 401，只有 1 次 `/auth/refresh` 调用（Completer 机制）
3. 服务端返回 304 时，UI 层收到的是数据（非空），网络监控工具可见 304 无 body

---

### Prompt C.2 — Auth 核心（Token 存储与状态管理）

**目标**：实现 `lib/core/auth/` 目录，提供登录状态的持久化和全局监听。

**flutter_secure_storage 使用规范**：

```dart
// 存储键定义（constants/storage_keys.dart）
class StorageKeys {
  static const accessToken  = 'access_token';
  static const refreshToken = 'refresh_token';   // 加密存储
  static const deviceId     = 'device_id';        // 登录时由服务端返回，永久不变
  static const userId       = 'user_id';
}

// TokenStore（纯存储层）
class TokenStore {
  Future<void> saveTokens({required String at, required String rt, required String deviceId, required String userId})
  Future<String?> getAccessToken()
  Future<String?> getRefreshToken()
  Future<String?> getDeviceId()
  Future<void> clearAll()    // 登出时调用
}
```

**AuthNotifier（Riverpod AsyncNotifier）**：

```dart
// State 类型：AuthState = authenticated(userId) | unauthenticated | loading
class AuthNotifier extends AsyncNotifier<AuthState> {
  Future<void> loginWithSms(String phone, String code)
    // 调用 POST /auth/sms/verify
    // 成功：TokenStore.saveTokens()，emit authenticated

  Future<void> logout()
    // 调用 POST /auth/logout（fire-and-forget，不等待结果）
    // TokenStore.clearAll()
    // 断开 WebSocket
    // emit unauthenticated
    // 清空 Isar 中属于当前用户的缓存（收藏/历史/歌单，但保留代理缓存）

  Future<void> checkAuthState()    // App 启动时调用，读取本地 Token 决定初始 State
}
```

**验收标准**：
1. App 冷启动时若 AT 和 RT 均存在，`AuthState` 直接为 `authenticated`（不请求网络）
2. RT 过期后 `logout()` 被调用，`AuthState` 变为 `unauthenticated`，路由自动跳转登录页
3. 多个 Widget 监听 `AuthNotifier`，只在 `AuthState` 变化时重建

---

### Prompt C.3 — 客户端缓存层（L1/L2/L3）

**目标**：实现 `lib/core/cache/` 目录，提供统一的缓存抽象接口。

**L2 Isar Schema（`lib/data/local/` 目录）**：

```dart
@collection
class CachedResponse {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String cacheKey;   // 由 URL + 排序后参数 hash 生成

  late String body;       // JSON 字符串
  late String etag;
  late DateTime cachedAt;
  late int ttlSeconds;

  @ignore
  bool get isExpired => DateTime.now().isAfter(cachedAt.add(Duration(seconds: ttlSeconds)));
}
```

**CachePolicy 抽象**：

```dart
abstract class CachePolicy<T> {
  // 标准 stale-while-revalidate 策略：
  // 1. 返回 L2 缓存数据（即使过期，快速展示）
  // 2. 若缓存过期或不存在，后台发起网络请求
  // 3. 网络返回后更新 L2，通过 Riverpod 通知 UI 刷新
  Stream<CacheResult<T>> fetch({
    required String cacheKey,
    required int ttlSeconds,
    required Future<T> Function() networkFetch,
    required T Function(Map<String, dynamic>) fromJson,
  });

  // 强制刷新（用户下拉刷新时调用）
  Future<T> forceRefresh({ ... });

  // 使指定 key 的缓存立即失效
  Future<void> invalidate(String cacheKey);
}
```

**TTL 映射表（`cache/ttl_constants.dart`）**：与 `proxy-ttl.ts` 保持一致，集中维护。

**L3 图片缓存**：仅配置 `cached_network_image` 的 `CacheManager`，最大 200MB，LRU 淘汰，不需要额外代码。

**验收标准**：
1. 首次进入歌手详情页，展示 L2 缓存数据（如有）同时后台刷新
2. 缓存过期时，页面不闪白屏（先展示旧数据，刷新后无缝替换）
3. 用户下拉刷新后，L2 缓存被更新，ETag 被更新

---

### Prompt C.4 — 手机号登录 UI

**目标**：实现 `lib/features/auth/` 目录的登录页。

**UI 要求**：
- 手机号输入框（数字键盘，自动格式化，限制11位）
- "获取验证码"按钮：点击后调用 `POST /auth/sms/send`，成功后变为 60s 倒计时（文字："重新获取(59s)"），倒计时结束恢复
- 验证码输入框：6位独立格子样式（类似银行 OTP 输入），自动聚焦，填满后自动提交
- 错误展示：
  - `RATE_LIMITED`：在按钮下方显示"请 X 秒后再试"（从 `retryAfter` 字段读取）
  - `INVALID_CODE`：验证码格子变红，文字"验证码错误"
  - 网络错误：Toast 提示

**平台适配**：
- Desktop：居中卡片布局，宽度限 400px
- Mobile：全屏布局，键盘弹出时内容上移

**验收标准**：
1. 网络错误时，倒计时不启动（需在按钮点击处先请求，成功才开始计时）
2. 填完第6位验证码后，自动调用 `AuthNotifier.loginWithSms()`
3. 登录成功后，`AuthNotifier` 状态变为 `authenticated`，`go_router` 的 redirect 逻辑自动导航至首页

---

### Prompt C.5 — WebSocket 同步客户端

**目标**：实现 `lib/core/ws/ws_client.dart`，处理 WS 连接生命周期，将服务端事件分发给对应的 Riverpod Provider。

**连接生命周期管理**：

```dart
class WsClient {
  // 连接：在 AUTH 成功后调用
  // URL：wss://<host>/ws?token=<accessToken>
  Future<void> connect()

  // 断开：App 进入后台超过 30s，或 logout 时调用
  void disconnect()

  // 重连策略：指数退避（1s, 2s, 4s, 8s, ... 最大 30s）
  // App 切换回前台时立即重连，然后调用 _fetchMissedEvents()

  // 拉取离线变更（重连后调用）
  Future<void> _fetchMissedEvents()
    // GET /user/sync?since=<last_sync_time>
    // 将结果注入对应 Provider

  // 事件路由
  void _handleMessage(String raw) {
    final msg = WsMessage.fromJson(jsonDecode(raw));
    switch (msg.event) {
      case "favorite.added":    _favoriteNotifier.onRemoteAdd(msg.payload);
      case "favorite.removed":  _favoriteNotifier.onRemoteRemove(msg.payload);
      case "playlist.*":        _playlistNotifier.onRemoteChange(msg.payload);
      case "progress.updated":  _playerNotifier.onRemoteProgress(msg.payload);
      case "device.kicked":     _authNotifier.logout();
      case "config.jwt_rotated": _authNotifier.logout();
    }
  }
}
```

**验收标准**：
1. 设备 A 收藏歌曲，设备 B 的收藏列表在 2s 内自动更新
2. App 后台 60s 后切回前台，WS 自动重连并拉取离线变更，页面数据与服务端一致
3. 收到 `device.kicked` 后，`AuthState` 变为 `unauthenticated`，显示"您已在另一台设备上登录"Toast

---

### Prompt C.6 — 全局播放器核心

**目标**：实现 `lib/core/player/playback_service.dart`，管理播放队列、进度上报、跨端续播。

**PlaybackService 职责**：

```dart
class PlaybackService {
  // 外部状态（通过 Riverpod 暴露）
  PlayQueue get queue       // 当前播放队列
  Song? get currentSong    // 当前歌曲（含第三方 ID，展示字段来自外部传入）
  PlaybackState get state   // playing / paused / loading / error

  // 播放指定歌曲（songMid）
  // 注意：播放前须从代理层实时获取播放 URL（不使用缓存）
  Future<void> playSong(Song song)

  // 队列操作
  void addToQueue(Song song, {bool playNow = false})
  void removeFromQueue(String songMid)
  void playNext()
  void playPrevious()
  void setPlayMode(PlayMode mode)    // sequence / shuffle / repeat

  // 进度上报（内部定时器，每 10s 调用一次 POST /user/progress）
  // App 进入后台或切歌时立即补报剩余进度
  void _scheduleProgressReport()

  // 跨端续播：登录后检查 GET /user/progress?songMid=<lastSong>，若有进度则 seek
  Future<void> resumeFromLastProgress()
}
```

**just_audio + audio_service 集成要点**：
- `AudioHandler` 实现系统媒体控件（iOS 锁屏、Android 通知栏、桌面媒体键）
- TV 端：`audio_service` 支持桌面 Media Keys 即可，无需媒体通知

**验收标准**：
1. 切换应用后锁屏，媒体控件可见且可操作
2. 播放 URL 每次切歌前实时获取，打印日志可见无 Cache Hit
3. 播放 30s 后，`GET /user/progress?songMid=xxx` 返回约 30（秒）

---

### Prompt C.7 — 功能页面（按优先级实现）

**目标**：实现 `lib/features/` 下各功能页面，每个页面独立 Prompt，此处定义通用规范和各模块特殊要求。

**通用规范**：
- 每个 feature 目录结构：`page.dart` / `provider.dart` / `widget/`
- provider 使用 `AsyncNotifierProvider`，调用 `CachePolicy.fetch()` 加载数据
- 列表页均使用 `ListView.builder` + `ScrollController`，滚动到底触发下一页
- 错误状态展示 `ErrorWidget`（含重试按钮），加载状态展示 shimmer skeleton

**各模块特殊要求**：

`home`：
- Banner 使用 `PageView` + 自动轮播（3s，循环）
- 推荐歌单 Section 立即加载，新歌/新专辑 Section 使用 `VisibilityDetector` 延迟加载

`singer`（D-B 决策相关）：
- 歌手详情页的"专辑"和"MV"Tab 使用 `IndexedStack` + 懒初始化（仅在首次点击时触发 Provider 请求）
- 关注歌手只存 `singer_mid` 到收藏（type = "singer"），不存名称、头像等元数据

`library`（收藏/历史）：
- 收藏列表只有 `targetId` 和 `type`，展示时需通过 `ProxyService` 批量查询详情（按需加载，每页 20 条，分批请求）
- 历史页同上，按 `playedAt` 倒序展示

**验收标准**：
- 首屏加载时间（冷启动，缓存命中）< 500ms
- 列表滚动帧率 ≥ 55fps（Profile 模式下测量）

---

### Prompt C.8 — Android TV 适配

**目标**：实现 `lib/shared/platform/tv/` 目录的 TV 焦点导航框架，并适配所有主要页面。

**焦点框架要求**：

```dart
// TV 全局布局：侧边导航 + 内容区
class TvScaffold extends StatelessWidget {
  // 侧边导航默认收起，左键呼出
  // 使用 FocusTraversalGroup + 自定义 FocusTraversalPolicy
  // 内容区焦点从第一个可聚焦元素开始
}

// TV 焦点卡片（所有列表 Item 的包装）
class TvFocusCard extends StatefulWidget {
  // 聚焦时：scale 1.1x + BoxShadow glow
  // 使用 AnimatedScale + AnimatedContainer，动画时长 150ms
  // 确保 focusNode 在 dispose 时正确释放
}
```

**D-pad 按键映射（`tv_key_handler.dart`）**：

```dart
// 全局 RawKeyboardListener
// DPAD_CENTER / ENTER → 确认/播放
// DPAD_BACK / ESCAPE  → 返回上级
// MEDIA_PLAY_PAUSE    → 播放/暂停
// MEDIA_NEXT          → 下一首
// MEDIA_PREVIOUS      → 上一首
```

**TV 专属布局规则**：
- 基础字体 20sp（非 TV 为 14sp），使用 `PlatformUtil.isTV` 判断
- 行高、卡片内边距均 1.5x 放大
- 不显示浮层 FAB、BottomSheet（改用全屏对话框）
- 搜索页：焦点先落在虚拟键盘，使用 `GridFocusTraversal`

**验收标准**：
1. 所有可交互元素均可通过 D-pad 导航到达
2. 焦点切出当前 `FocusTraversalGroup` 时不丢失（不跳回屏幕顶部）
3. 播放页的全屏播放器中，方向键左右可 seek 10s，上下调音量
