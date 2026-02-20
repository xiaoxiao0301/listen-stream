-- ============================================================
-- playlists + playlist_songs 查询
-- 使用服务：sync-svc
-- ============================================================

-- ── user_playlists ──────────────────────────────────────────

-- name: CreatePlaylist :one
INSERT INTO user_playlists (user_id, name)
VALUES ($1, $2)
RETURNING *;

-- name: GetPlaylistByID :one
SELECT * FROM user_playlists
WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL;

-- name: ListUserPlaylists :many
SELECT
  p.*,
  COUNT(ps.id) AS song_count
FROM user_playlists p
LEFT JOIN playlist_songs ps ON ps.playlist_id = p.id
WHERE p.user_id = $1 AND p.deleted_at IS NULL
GROUP BY p.id
ORDER BY p.created_at ASC;

-- name: UpdatePlaylistName :one
UPDATE user_playlists
SET name = $2, updated_at = NOW()
WHERE id = $1 AND user_id = $3 AND deleted_at IS NULL
RETURNING *;

-- name: SoftDeletePlaylist :exec
UPDATE user_playlists
SET deleted_at = NOW(), updated_at = NOW()
WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL;

-- name: ListPlaylistsSince :many
-- /user/sync?since= 拉取变更歌单
SELECT * FROM user_playlists
WHERE user_id = $1 AND updated_at > $2 AND deleted_at IS NULL;

-- name: ListDeletedPlaylistsSince :many
SELECT id FROM user_playlists
WHERE user_id = $1 AND deleted_at IS NOT NULL AND deleted_at > $2;

-- ── playlist_songs ──────────────────────────────────────────

-- name: GetNextSortOrder :one
-- 追加歌曲时获取下一个 sort_order
SELECT COALESCE(MAX(sort_order) + 1, 0)
FROM playlist_songs
WHERE playlist_id = $1;

-- name: AddSongToPlaylist :one
INSERT INTO playlist_songs (playlist_id, song_mid, sort_order)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetPlaylistSong :one
SELECT * FROM playlist_songs
WHERE playlist_id = $1 AND song_mid = $2;

-- name: ListPlaylistSongs :many
SELECT * FROM playlist_songs
WHERE playlist_id = $1
ORDER BY sort_order ASC;

-- name: RemoveSongFromPlaylist :one
DELETE FROM playlist_songs
WHERE playlist_id = $1 AND song_mid = $2
RETURNING sort_order;

-- name: CompactSortOrder :exec
-- 删除歌曲后，将 sort_order 大于被删位置的记录减 1
UPDATE playlist_songs
SET sort_order = sort_order - 1
WHERE playlist_id = $1 AND sort_order > $2;
