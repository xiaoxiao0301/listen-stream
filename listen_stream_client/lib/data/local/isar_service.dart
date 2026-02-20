import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'cached_response.dart';
import 'etag_cache.dart';

/// Entry-point for all Isar operations.
/// Call [init] before [runApp].
class IsarService {
  IsarService._();

  static Isar? _instance;
  static Isar get instance {
    assert(_instance != null, 'IsarService.init() not called');
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [CachedResponseSchema, ETagCacheSchema],
      directory: dir.path,
    );
  }

  static Future<void> close() => instance.close();
}
