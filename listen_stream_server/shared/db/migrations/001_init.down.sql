-- ============================================================
-- 回滚：按照依赖顺序反向删除
-- ============================================================
DROP TABLE IF EXISTS operation_logs;
DROP TABLE IF EXISTS playlist_songs;
DROP TABLE IF EXISTS user_playlists;
DROP TABLE IF EXISTS history;
DROP TABLE IF EXISTS favorites;
DROP TABLE IF EXISTS admin_users;
DROP TABLE IF EXISTS system_configs;
DROP TABLE IF EXISTS devices;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS user_role;
