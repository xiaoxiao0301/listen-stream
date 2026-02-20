/// Wrapper emitted by CachePolicy.fetch() stream.
class CacheResult<T> {
  const CacheResult({required this.data, this.isFromCache = false});
  final T data;
  /// True when this data came from L2 (Isar); false when from network.
  final bool isFromCache;
}
