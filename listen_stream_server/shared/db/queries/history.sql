-- ============================================================
-- history 查询
-- 使用服务：sync-svc
-- ============================================================

-- name: CreateHistory :one
INSERT INTO history (user_id, song_mid, progress)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetSongProgress :one
-- 查询指定歌曲的最近一次播放进度
SELECT progress, played_at
FROM history
WHERE user_id = $1 AND song_mid = $2
ORDER BY played_at DESC
LIMIT 1;

-- name: UpdateSongProgress :one
-- 插入新记录（历史追加，不 upsert，让 TrimHistory 负责裁剪）
INSERT INTO history (user_id, song_mid, progress)
VALUES ($1, $2, $3)
RETURNING *;

-- name: ListHistory :many
SELECT * FROM history
WHERE user_id = $1
ORDER BY played_at DESC
LIMIT $2 OFFSET $3;

-- name: CountHistory :one
SELECT COUNT(*) FROM history WHERE user_id = $1;

-- name: ListHistorySince :many
-- /user/sync?since= 拉取新历史
SELECT * FROM history
WHERE user_id = $1 AND played_at > $2
ORDER BY played_at DESC;

-- name: TrimHistory :exec
-- Delete all but the $2 most recent records for user $1.
DELETE FROM history AS h1
WHERE h1.id IN (
  SELECT h2.id FROM history AS h2
  WHERE h2.user_id = $1
  ORDER BY h2.played_at DESC
  OFFSET $2
);
