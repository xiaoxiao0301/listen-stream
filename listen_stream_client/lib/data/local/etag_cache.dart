/// Plain-Dart model for ETag values and their associated cached response body.
/// Backed by sqflite table `etag_cache`.
class ETagCache {
  final int? id;
  final String key; // "METHOD:url"
  final String etag;
  final String body; // JSON-encoded response body
  final DateTime updatedAt;

  const ETagCache({
    this.id,
    required this.key,
    required this.etag,
    required this.body,
    required this.updatedAt,
  });

  factory ETagCache.fromMap(Map<String, dynamic> m) => ETagCache(
        id: m['id'] as int?,
        key: m['key'] as String,
        etag: m['etag'] as String,
        body: m['body'] as String,
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'key': key,
        'etag': etag,
        'body': body,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };
}
