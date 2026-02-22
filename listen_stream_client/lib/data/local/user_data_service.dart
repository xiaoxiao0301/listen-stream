import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'isar_service.dart';

/// Service to manage user playlists and favorites locally
class UserDataService {
  static Database get _db => IsarService.instance;

  /// Initialize user data tables
  static Future<void> initTables() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS user_playlists (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT NOT NULL,
        description   TEXT NOT NULL DEFAULT '',
        cover_url     TEXT NOT NULL DEFAULT '',
        created_at    INTEGER NOT NULL,
        updated_at    INTEGER NOT NULL
      )
    ''');

    await _db.execute('''
      CREATE TABLE IF NOT EXISTS favorite_songs (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        song_mid      TEXT UNIQUE NOT NULL,
        song_name     TEXT NOT NULL,
        singer_name   TEXT NOT NULL,
        album_name    TEXT NOT NULL DEFAULT '',
        cover_url     TEXT NOT NULL DEFAULT '',
        added_at      INTEGER NOT NULL
      )
    ''');

    await _db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_songs (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id   INTEGER NOT NULL,
        song_mid      TEXT NOT NULL,
        song_name     TEXT NOT NULL,
        singer_name   TEXT NOT NULL,
        album_name    TEXT NOT NULL DEFAULT '',
        cover_url     TEXT NOT NULL DEFAULT '',
        added_at      INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES user_playlists (id) ON DELETE CASCADE,
        UNIQUE(playlist_id, song_mid)
      )
    ''');
  }

  // ── Playlists ───────────────────────────────────────────────────────────────

  static Future<int> createPlaylist({
    required String name,
    String description = '',
    String coverUrl = '',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _db.insert('user_playlists', {
      'name': name,
      'description': description,
      'cover_url': coverUrl,
      'created_at': now,
      'updated_at': now,
    });
  }

  static Future<List<Map<String, dynamic>>> getPlaylists() async {
    return await _db.query(
      'user_playlists',
      orderBy: 'created_at DESC',
    );
  }

  static Future<Map<String, dynamic>?> getPlaylist(int id) async {
    final result = await _db.query(
      'user_playlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  static Future<void> updatePlaylist({
    required int id,
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (coverUrl != null) updates['cover_url'] = coverUrl;

    await _db.update(
      'user_playlists',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deletePlaylist(int id) async {
    await _db.delete('user_playlists', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAllPlaylists() async {
    await _db.delete('user_playlists');
  }

  // ── Favorite Songs ──────────────────────────────────────────────────────────

  static Future<void> addFavoriteSong({
    required String songMid,
    required String songName,
    required String singerName,
    String albumName = '',
    String coverUrl = '',
  }) async {
    await _db.insert(
      'favorite_songs',
      {
        'song_mid': songMid,
        'song_name': songName,
        'singer_name': singerName,
        'album_name': albumName,
        'cover_url': coverUrl,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeFavoriteSong(String songMid) async {
    await _db.delete(
      'favorite_songs',
      where: 'song_mid = ?',
      whereArgs: [songMid],
    );
  }

  static Future<bool> isSongFavorited(String songMid) async {
    final count = Sqflite.firstIntValue(
      await _db.rawQuery(
        'SELECT COUNT(*) FROM favorite_songs WHERE song_mid = ?',
        [songMid],
      ),
    );
    return (count ?? 0) > 0;
  }

  static Future<List<Map<String, dynamic>>> getFavoriteSongs() async {
    return await _db.query(
      'favorite_songs',
      orderBy: 'added_at DESC',
    );
  }

  static Future<void> clearAllFavorites() async {
    await _db.delete('favorite_songs');
  }

  // ── Playlist Songs ──────────────────────────────────────────────────────────

  static Future<void> addSongToPlaylist({
    required int playlistId,
    required String songMid,
    required String songName,
    required String singerName,
    String albumName = '',
    String coverUrl = '',
  }) async {
    await _db.insert(
      'playlist_songs',
      {
        'playlist_id': playlistId,
        'song_mid': songMid,
        'song_name': songName,
        'singer_name': singerName,
        'album_name': albumName,
        'cover_url': coverUrl,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Update playlist updated_at
    await _db.update(
      'user_playlists',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  static Future<void> removeSongFromPlaylist({
    required int playlistId,
    required String songMid,
  }) async {
    await _db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_mid = ?',
      whereArgs: [playlistId, songMid],
    );
  }

  static Future<List<Map<String, dynamic>>> getPlaylistSongs(int playlistId) async {
    return await _db.query(
      'playlist_songs',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'added_at DESC',
    );
  }

  static Future<int> getPlaylistSongCount(int playlistId) async {
    final count = Sqflite.firstIntValue(
      await _db.rawQuery(
        'SELECT COUNT(*) FROM playlist_songs WHERE playlist_id = ?',
        [playlistId],
      ),
    );
    return count ?? 0;
  }

  static Future<void> clearPlaylistSongs(int playlistId) async {
    await _db.delete(
      'playlist_songs',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
  }
}
