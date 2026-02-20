# Phase 2 Summary — Go Backend Foundation

> **Status:** Complete  
> **Output directory:** `listen_stream_server/`

---

## 1. Module Boundaries

| Module | Path | Responsibility |
|--------|------|----------------|
| **shared/go** | `shared/go/` | AES-256-GCM crypto, Redis client + key naming, encrypted ConfigService |
| **auth-svc** | `auth-svc/` | Phone+SMS login, JWT issuance/refresh, device management, RBAC middleware |
| **proxy-svc** | `proxy-svc/` | Token-authenticated reverse-proxy to upstream music API; Redis response cache |
| **sync-svc** | `sync-svc/` | Favorites, history, playlist REST; WebSocket hub for push notifications |
| **admin-svc** | `admin-svc/` | Admin login (Argon2id + TOTP), user management, config CRUD, operation logs |

The four services share **SQL files** (`shared/db/`) and the **shared Go module** but have independent `go.mod` files and `sqlc.yaml` configs. The Go workspace (`go.work`) links everything for local development.

---

## 2. Interface Definitions

### `config.Service` (`shared/go/pkg/config/config_service.go`)

```go
type Service interface {
    Get(ctx context.Context, key string) (string, error)
    GetMany(ctx context.Context, keys []string) (map[string]string, error)
    Set(ctx context.Context, key, value, updatedBy string) error
    Preload(ctx context.Context) error
    Invalidate(key string)
}
```

- All values stored AES-256-GCM encrypted; decrypted in memory only.
- 30 s TTL cache via `sync.RWMutex` + `map[string]cacheEntry`.
- `Preload` is called at startup and is fatal on decryption failure.

### `service.JWTService` (`auth-svc/internal/service/jwt_service.go`)

```go
type JWTService interface {
    SignUserAccessToken(ctx, userID, deviceID, role string) (string, error)
    VerifyUserToken(ctx, tokenStr string) (*UserClaims, error)
    SignAdminAccessToken(ctx, adminID, username, role string) (string, error)
    VerifyAdminToken(ctx, tokenStr string) (*AdminClaims, error)
    IssueRefreshToken() (rt, rtHash string)
    AccessTokenTTL(ctx) (int64, error)
    RefreshTokenTTL(ctx) (int64, error)
}
```

- Keys loaded from `ConfigService` at runtime; 30 s cache handles load.
- `aud=["user"]` / `aud=["admin"]` enforced at parse time.
- `IssueRefreshToken` returns UUID v4 plaintext + hex(SHA-256(rt)); only the hash is persisted.

### `rdb.Client` (`shared/go/pkg/rdb/client.go`)

Key methods for architecture decisions:

| Method | Decision |
|--------|----------|
| `SetNX(ctx, key, value, ttl)` | RT write-on-login (D-C) |
| `GetDel(ctx, key)` | RT atomic claim — first wins (D-C) |
| `ScanDel(ctx, pattern)` | JWT rotation — purge all `rt:*` |
| `PSubscribe(ctx, patterns...)` | WS Hub fan-out via `ws:user:*` |

### Middleware (`auth-svc/internal/middleware/auth.go`)

```go
func RequireUser(jwtSvc JWTService, userQuerier repo.Querier) gin.HandlerFunc
func RequireAdmin(jwtSvc JWTService) gin.HandlerFunc
func RequireRole(minRole string) gin.HandlerFunc
func GetUserClaims(c *gin.Context) *service.UserClaims
func GetAdminClaims(c *gin.Context) *service.AdminClaims
```

Role rank: `USER(0) < ADMIN(1) < SUPER_ADMIN(2)`

---

## 3. Architecture Decisions (Recap)

### D-A: Dual JWT keys

- `USER_JWT_SECRET` and `ADMIN_JWT_SECRET` stored encrypted in `system_configs`.
- `aud` claim distinguishes token type; cross-audience verification fails immediately.
- Rotating one key invalidates only that audience's tokens.

### D-B: No song metadata tables

- `favorites.target_id`, `history.target_id`, `playlist_songs.target_id` store the upstream third-party `mid` (music ID) only.
- No local artist/album/song metadata tables; all song details are fetched through proxy-svc and cached in Redis.
- Reduces schema complexity and prevents stale metadata.

### D-C: Atomic RT lock via `GETDEL`

- On login: `SETNX rt:{device_id} {rtHash}` (TTL = REFRESH_TOKEN_TTL).
- On refresh: `GETDEL rt:{device_id}` — atomically reads and deletes.
  - First call gets the stored hash → validate → write new hash.
  - Second concurrent call gets `nil` → 401 TOKEN_REUSED.
- Prevents parallel RT reuse without optimistic locking in the DB.

---

## 4. Data Flow Diagrams

### Login flow (auth-svc)

```
Client → POST /auth/verify-code
  → auth-svc validates SMS code (Redis GETDEL sms:{phone})
  → UpsertUser (DB)
  → UpsertDevice (DB)
  → IssueRefreshToken() → (rt plaintext, rtHash)
  → SETNX rt:{device_id} rtHash  (Redis, TTL = RTL)
  → UpdateDeviceRT(rtHash) (DB, for audit)
  → SignUserAccessToken() → atStr
  → response: { access_token, refresh_token, expires_in }
```

### Token refresh flow (auth-svc)

```
Client → POST /auth/refresh (body: refresh_token)
  → hash rt → rtHash
  → GETDEL rt:{device_id}       ← D-C atomic lock
  → if nil → 401 TOKEN_REUSED
  → compare stored == rtHash
  → if mismatch → 401 TOKEN_REUSED
  → GetDeviceWithUser (DB) — check user not disabled
  → IssueRefreshToken() → new (rt, rtHash)
  → SETNX rt:{device_id} newRtHash
  → SignUserAccessToken() → atStr
  → response: { access_token, refresh_token, expires_in }
```

### Config read flow

```
Service handler
  → cfgSvc.Get("USER_JWT_SECRET")
  → cache hit (TTL < 30s)? → return plaintext
  → cache miss → SELECT system_configs WHERE key=?
  → AES-256-GCM Decrypt(encKey, encrypted_value)
  → store in cache with timestamp
  → return plaintext
```

---

## 5. File Manifest

### Migrations & queries

```
shared/db/migrations/001_init.up.sql     9 tables + ENUMs + indexes
shared/db/migrations/001_init.down.sql   DROP in reverse dependency order
shared/db/queries/users.sql              8 named queries
shared/db/queries/devices.sql            10 named queries
shared/db/queries/favorites.sql          7 named queries (soft-delete + reactivate)
shared/db/queries/history.sql            6 named queries (TrimHistory keeps latest 500)
shared/db/queries/playlists.sql          8 named queries (CompactSortOrder)
shared/db/queries/system_configs.sql     3 named queries
shared/db/queries/admin_users.sql        7 named queries (UpsertAdmin for CLI reset)
shared/db/queries/operation_logs.sql     3 named queries
```

### Go workspace

```
go.work                                  workspace linking all 5 modules
shared/go/go.mod                         module listen-stream/shared
auth-svc/go.mod  proxy-svc/go.mod
sync-svc/go.mod  admin-svc/go.mod        4 service modules
```

### Shared packages

```
shared/go/pkg/crypto/aes.go              ParseKey / Encrypt / Decrypt (AES-256-GCM)
shared/go/pkg/rdb/keys.go                Typed Redis key constructors
shared/go/pkg/rdb/client.go              go-redis/v9 wrapper (GetDel, ScanDel, PSubscribe)
shared/go/pkg/config/config_service.go   ConfigService with 30 s cache
```

### auth-svc

```
auth-svc/internal/service/jwt_service.go JWTService (dual-key, D-A)
auth-svc/internal/middleware/auth.go     RequireUser / RequireAdmin / RequireRole
auth-svc/cmd/server/main.go              Service entry point
auth-svc/sqlc.yaml                       sqlc config (users, devices, system_configs)
auth-svc/Dockerfile                      Multi-stage build
```

### proxy-svc / sync-svc / admin-svc

```
{svc}/cmd/server/main.go    Service entry point (startup + health endpoint)
{svc}/sqlc.yaml             sqlc config (service-specific query subset)
{svc}/Dockerfile            Multi-stage build
```

### Infrastructure

```
docker-compose.yml          postgres:15 + redis:7 + 4 service containers
.env.example                All environment variable documentation
```

---

## 6. Pre-conditions for Track A

Before implementing Track A handlers, the following must be satisfied:

### A. Run `sqlc generate`

```bash
cd listen_stream_server
sqlc generate -f auth-svc/sqlc.yaml
sqlc generate -f proxy-svc/sqlc.yaml
sqlc generate -f sync-svc/sqlc.yaml
sqlc generate -f admin-svc/sqlc.yaml
```

Generated files land in `{svc}/internal/repo/`. Add `internal/repo/` to each service's `.gitignore` OR commit the generated files (choose one policy and document it).

> **Note:** `emit_interface: true` in every `sqlc.yaml` generates a `Querier` interface. The `RequireUser` middleware and service unit tests depend on this interface — do **not** remove it.

### B. Seed required config keys

The system **will start** without these, but SMS login and JWT issuance will fail at runtime. Seed before first test:

```sql
-- Generate secrets first: openssl rand -hex 32
INSERT INTO system_configs (key, encrypted_value, updated_by)
VALUES
  ('USER_JWT_SECRET',    '<aes_encrypted_secret>',   'seed'),
  ('ADMIN_JWT_SECRET',   '<aes_encrypted_secret>',   'seed'),
  ('ACCESS_TOKEN_TTL',   '<aes_encrypted_7200>',     'seed'),
  ('REFRESH_TOKEN_TTL',  '<aes_encrypted_2592000>',  'seed');
```

Or implement the `init-config` CLI tool (planned for Track A, admin-svc).

### C. Run database migrations

```bash
migrate -path shared/db/migrations \
        -database "$DATABASE_URL" \
        up
```

### D. proxy-svc token verification is lightweight

`proxy-svc` verifies user JWTs **without** a DB lookup (no device or disabled check). This is intentional: the proxy is a high-throughput path. If a user is disabled, the next auth-svc request returns 403; the proxy still serves cached content until the AT expires (max 2 h). Track B implementors should be aware of this trade-off.

---

## 7. Track A Pre-Conditions Checklist

| # | Condition | Who validates |
|---|-----------|---------------|
| 1 | `sqlc generate` run for all 4 services | Developer setup / CI |
| 2 | Migrations applied to target DB | `make migrate-up` |
| 3 | `CONFIG_ENCRYPTION_KEY` set and valid (64 hex chars) | Ops / `.env` |
| 4 | `USER_JWT_SECRET` + `ADMIN_JWT_SECRET` seeded in DB | `make seed-config` |
| 5 | `go work sync` passes (all go.sum hashes match) | CI |
| 6 | `go build ./...` succeeds from workspace root | CI |

---

## 8. Track B / Track C Notes

### Track B (proxy-svc)

- Upstream API base URL must be in `.env` as `UPSTREAM_API_BASE_URL`.
- Cache invalidation: `ScanDel(ctx, "proxy:*")` when upstream data changes.
- JWT verification in proxy-svc uses `JWTService.VerifyUserToken` — same shared package, no DB.

### Track C (sync-svc WebSocket)

- WS Hub subscribes to Redis pattern `ws:user:*` via `rdb.PSubscribe`.
- Other services push notifications via `rdb.Publish("ws:user:{userID}", payload)`.
- Multi-instance safe: each sync-svc pod has its own hub; Redis Pub/Sub fans out across pods.
- Key: `rdb.KeyWSChannel(userID)` → `ws:user:{userID}`.
- Cron (robfig/cron/v3) schedules periodic delta-sync pushes for offline clients reconnecting.

---

*Generated at end of Phase 2 execution.*
