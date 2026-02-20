-- ============================================================
-- admin_users 查询
-- 使用服务：admin-svc
-- ============================================================

-- name: GetAdminByUsername :one
SELECT * FROM admin_users WHERE username = $1;

-- name: GetAdminByID :one
SELECT * FROM admin_users WHERE id = $1;

-- name: CreateAdmin :one
INSERT INTO admin_users (username, password_hash, role, totp_secret)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: UpsertAdmin :one
-- CLI reset-admin 工具使用：若用户名已存在则更新密码和角色
INSERT INTO admin_users (username, password_hash, role)
VALUES ($1, $2, $3)
ON CONFLICT (username) DO UPDATE
  SET password_hash = EXCLUDED.password_hash,
      role          = EXCLUDED.role,
      disabled      = FALSE
RETURNING *;

-- name: CountAdminUsers :one
-- 初始化检查：count > 0 表示已初始化
SELECT COUNT(*) FROM admin_users;

-- name: ListAdmins :many
SELECT * FROM admin_users ORDER BY created_at ASC;

-- name: SetAdminDisabled :exec
UPDATE admin_users SET disabled = $2 WHERE id = $1;
