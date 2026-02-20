-- ============================================================
-- Listen Stream — 初始化迁移
-- 执行：golang-migrate -path shared/db/migrations -database $DATABASE_URL up
-- ============================================================

CREATE TYPE user_role AS ENUM ('USER', 'ADMIN', 'SUPER_ADMIN');

-- ── 用户表 ──────────────────────────────────────────────────
CREATE TABLE users (
  id          TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  phone       TEXT        UNIQUE NOT NULL,
  role        user_role   NOT NULL DEFAULT 'USER',
  disabled    BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 设备表 ──────────────────────────────────────────────────
-- device_id 由客户端生成 UUID，不变；rt_hash 存 Refresh Token 的 SHA-256 hash
CREATE TABLE devices (
  id             TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id        TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id      TEXT        UNIQUE NOT NULL,
  platform       TEXT        NOT NULL,  -- 'android'|'ios'|'desktop'|'tv'
  rt_hash        TEXT        NOT NULL,
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX devices_user_id_idx ON devices (user_id);
CREATE INDEX devices_last_active_idx ON devices (user_id, last_active_at ASC);

-- ── 系统配置表（加密存储）──────────────────────────────────
CREATE TABLE system_configs (
  key        TEXT        PRIMARY KEY,
  value      TEXT        NOT NULL,  -- AES-256-GCM 密文（base64 JSON）
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by TEXT        NOT NULL
);

-- ── 管理员账号表 ────────────────────────────────────────────
CREATE TABLE admin_users (
  id            TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  username      TEXT        UNIQUE NOT NULL,
  password_hash TEXT        NOT NULL,  -- Argon2id hash
  role          user_role   NOT NULL DEFAULT 'ADMIN',
  totp_secret   TEXT,                  -- NULL 表示未开启 TOTP
  disabled      BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 收藏表（软删除）────────────────────────────────────────
-- 只存第三方 ID（D-B 决策），不存元数据
CREATE TABLE favorites (
  id         TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id    TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       TEXT        NOT NULL,       -- 'song'|'album'|'singer'
  target_id  TEXT        NOT NULL,       -- 第三方 song_mid / album_mid / singer_mid
  deleted_at TIMESTAMPTZ,               -- NULL = 有效，非 NULL = 已删除
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, type, target_id)
);
CREATE INDEX favorites_user_type_idx   ON favorites (user_id, type) WHERE deleted_at IS NULL;
CREATE INDEX favorites_user_time_idx   ON favorites (user_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX favorites_user_del_idx    ON favorites (user_id, deleted_at) WHERE deleted_at IS NOT NULL;

-- ── 播放历史表 ──────────────────────────────────────────────
-- 每用户最多保留 500 条（TrimHistory query 负责清理）
CREATE TABLE history (
  id        TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id   TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  song_mid  TEXT        NOT NULL,
  progress  INT         NOT NULL DEFAULT 0,  -- 播放进度（秒）
  played_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX history_user_time_idx ON history (user_id, played_at DESC);

-- ── 用户歌单表（软删除）──────────────────────────────────────
CREATE TABLE user_playlists (
  id         TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id    TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  deleted_at TIMESTAMPTZ,               -- NULL = 有效
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX playlists_user_idx ON user_playlists (user_id) WHERE deleted_at IS NULL;

-- ── 歌单歌曲关联表 ──────────────────────────────────────────
-- 只存 song_mid（D-B 决策），sort_order 从 0 开始
CREATE TABLE playlist_songs (
  id          TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  playlist_id TEXT        NOT NULL REFERENCES user_playlists(id) ON DELETE CASCADE,
  song_mid    TEXT        NOT NULL,
  sort_order  INT         NOT NULL,
  added_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (playlist_id, song_mid)
);
CREATE INDEX playlist_songs_order_idx ON playlist_songs (playlist_id, sort_order ASC);

-- ── 操作审计日志表 ──────────────────────────────────────────
CREATE TABLE operation_logs (
  id         TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::text,
  admin_id   TEXT        NOT NULL,   -- admin_users.id（不 FK，允许账号删除后日志保留）
  action     TEXT        NOT NULL,   -- 'ADMIN_LOGIN'|'USER_DISABLED'|'JWT_ROTATED' 等
  target_id  TEXT,                   -- 被操作对象 ID（可为 NULL）
  before_val TEXT,                   -- 操作前值（敏感字段用 "[已脱敏]"）
  after_val  TEXT,                   -- 操作后值
  ip         TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX operation_logs_time_idx   ON operation_logs (created_at DESC);
CREATE INDEX operation_logs_action_idx ON operation_logs (action, created_at DESC);
