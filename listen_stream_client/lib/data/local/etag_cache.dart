import 'package:isar/isar.dart';

part 'etag_cache.g.dart';

/// Isar collection for ETag values and their associated cached response body.
@collection
class ETagCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;   // "METHOD:url"

  late String etag;
  late String body;  // JSON-encoded response body
  late DateTime updatedAt;
}
