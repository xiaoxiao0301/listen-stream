-- ============================================================
-- system_configs 查询（加密配置）
-- 使用服务：全部 4 个服务（通过 ConfigService 访问）
-- ============================================================

-- name: GetConfig :one
SELECT * FROM system_configs WHERE key = $1;

-- name: UpsertConfig :one
INSERT INTO system_configs (key, value, updated_by)
VALUES ($1, $2, $3)
ON CONFLICT (key) DO UPDATE
  SET value      = EXCLUDED.value,
      updated_at = NOW(),
      updated_by = EXCLUDED.updated_by
RETURNING *;

-- name: ListAllConfigs :many
-- ConfigService.Preload 启动时预热所有配置
SELECT * FROM system_configs;
