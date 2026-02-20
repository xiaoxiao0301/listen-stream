-- ============================================================
-- favorites 查询（软删除模型）
-- 使用服务：sync-svc
-- ============================================================

-- name: CreateFavorite :one
-- ON CONFLICT DO NOTHING 保证幂等（重复添加不报错）
INSERT INTO favorites (user_id, type, target_id)
VALUES ($1, $2, $3)
ON CONFLICT (user_id, type, target_id) DO UPDATE
  SET deleted_at = NULL  -- 若之前软删除过，重新激活
RETURNING *;

-- name: GetFavoriteByID :one
SELECT * FROM favorites WHERE id = $1 AND user_id = $2;

-- name: GetFavoriteByTarget :one
SELECT * FROM favorites
WHERE user_id = $1 AND type = $2 AND target_id = $3 AND deleted_at IS NULL;

-- name: SoftDeleteFavorite :one
UPDATE favorites
SET deleted_at = NOW()
WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
RETURNING *;

-- name: ListFavorites :many
-- 分页；type 为空字符串时查全部类型
SELECT * FROM favorites
WHERE user_id = $1
  AND deleted_at IS NULL
  AND (@type::text = '' OR type = @type)
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: CountFavorites :one
SELECT COUNT(*) FROM favorites
WHERE user_id = $1
  AND deleted_at IS NULL
  AND (@type::text = '' OR type = @type);

-- name: ListFavoritesSince :many
-- /user/sync?since= 拉取新增收藏
SELECT * FROM favorites
WHERE user_id = $1
  AND deleted_at IS NULL
  AND created_at > $2;

-- name: ListDeletedFavoritesSince :many
-- /user/sync?since= 拉取软删除的收藏 ID
SELECT id FROM favorites
WHERE user_id = $1
  AND deleted_at IS NOT NULL
  AND deleted_at > $2;
