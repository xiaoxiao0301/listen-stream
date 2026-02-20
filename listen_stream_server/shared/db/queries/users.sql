-- ============================================================
-- users 查询
-- 使用服务：auth-svc, sync-svc, admin-svc, proxy-svc（disabled 检查）
-- ============================================================

-- name: GetUserByPhone :one
SELECT * FROM users WHERE phone = $1;

-- name: GetUserByID :one
SELECT * FROM users WHERE id = $1;

-- name: UpsertUser :one
-- 幂等创建/更新（SMS 验证通过后调用）
INSERT INTO users (phone)
VALUES ($1)
ON CONFLICT (phone) DO UPDATE
  SET updated_at = NOW()
RETURNING *;

-- name: SetUserDisabled :exec
UPDATE users
SET disabled = $2, updated_at = NOW()
WHERE id = $1;

-- name: SetUserRole :exec
UPDATE users
SET role = $2, updated_at = NOW()
WHERE id = $1;

-- name: ListUsers :many
-- Admin 分页查询，支持手机号前缀搜索
SELECT
  u.*,
  COUNT(d.id) AS device_count
FROM users u
LEFT JOIN devices d ON d.user_id = u.id
WHERE (@phone::text = '' OR u.phone LIKE @phone || '%')
GROUP BY u.id
ORDER BY u.created_at DESC
LIMIT $1 OFFSET $2;

-- name: CountUsers :one
SELECT COUNT(*) FROM users;

-- name: CountActiveUsersSince :one
-- 统计概览：7 天内有设备活跃的用户数
SELECT COUNT(DISTINCT d.user_id)
FROM devices d
WHERE d.last_active_at >= $1;
