-- ============================================================
-- devices 查询
-- 使用服务：auth-svc, admin-svc
-- ============================================================

-- name: GetDeviceByDeviceID :one
SELECT * FROM devices WHERE device_id = $1;

-- name: GetDeviceWithUser :one
-- auth/refresh 时同时取用户 role
SELECT d.*, u.role AS user_role, u.disabled AS user_disabled
FROM devices d
JOIN users u ON u.id = d.user_id
WHERE d.device_id = $1;

-- name: UpsertDevice :one
-- 登录时写入或更新设备信息（rt_hash, platform, last_active_at）
INSERT INTO devices (user_id, device_id, platform, rt_hash)
VALUES ($1, $2, $3, $4)
ON CONFLICT (device_id) DO UPDATE
  SET rt_hash        = EXCLUDED.rt_hash,
      platform       = EXCLUDED.platform,
      last_active_at = NOW()
RETURNING *;

-- name: UpdateDeviceRT :exec
-- RT 轮换后更新 hash 和活跃时间
UPDATE devices
SET rt_hash        = $2,
    last_active_at = NOW()
WHERE device_id = $1;

-- name: UpdateDeviceLastActive :exec
UPDATE devices
SET last_active_at = NOW()
WHERE device_id = $1;

-- name: CountUserDevices :one
SELECT COUNT(*) FROM devices WHERE user_id = $1;

-- name: ListUserDevices :many
SELECT * FROM devices WHERE user_id = $1 ORDER BY last_active_at DESC;

-- name: GetOldestDevice :one
-- MAX_DEVICES 超限时踢出最老设备
SELECT * FROM devices
WHERE user_id = $1
ORDER BY last_active_at ASC
LIMIT 1;

-- name: DeleteDevice :exec
DELETE FROM devices WHERE device_id = $1;

-- name: DeleteAllUserDevices :exec
-- 禁用用户时吊销全部设备
DELETE FROM devices WHERE user_id = $1;

-- name: CountTotalDevices :one
SELECT COUNT(*) FROM devices;
