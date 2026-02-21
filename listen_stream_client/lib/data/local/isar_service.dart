import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Entry-point for all local SQLite operations.
/// Call [init] before [runApp].
class IsarService {
  IsarService._();

  static Database? _instance;
  static Database get instance {
    assert(_instance != null, 'IsarService.init() not called');
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _instance = await openDatabase(
      '${dir.path}/listen_stream.db',
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE cached_responses (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            cache_key   TEXT UNIQUE NOT NULL,
            body        TEXT NOT NULL,
            etag        TEXT NOT NULL DEFAULT '',
            cached_at   INTEGER NOT NULL,
            ttl_seconds INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE etag_cache (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            key        TEXT UNIQUE NOT NULL,
            etag       TEXT NOT NULL,
            body       TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> close() async => _instance?.close();
}
