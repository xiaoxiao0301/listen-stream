/// Plain-Dart model for stale-while-revalidate response cache (L2).
/// Backed by sqflite table `cached_responses`.
class CachedResponse {
  final int? id;
  final String cacheKey;
  final String body; // JSON string
  final String etag;
  final DateTime cachedAt;
  final int ttlSeconds;

  const CachedResponse({
    this.id,
    required this.cacheKey,
    required this.body,
    required this.etag,
    required this.cachedAt,
    required this.ttlSeconds,
  });

  bool get isExpired =>
      DateTime.now().isAfter(cachedAt.add(Duration(seconds: ttlSeconds)));

  factory CachedResponse.fromMap(Map<String, dynamic> m) => CachedResponse(
        id: m['id'] as int?,
        cacheKey: m['cache_key'] as String,
        body: m['body'] as String,
        etag: m['etag'] as String? ?? '',
        cachedAt:
            DateTime.fromMillisecondsSinceEpoch(m['cached_at'] as int),
        ttlSeconds: m['ttl_seconds'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'cache_key': cacheKey,
        'body': body,
        'etag': etag,
        'cached_at': cachedAt.millisecondsSinceEpoch,
        'ttl_seconds': ttlSeconds,
      };
}
