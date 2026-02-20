import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../data/local/cached_response.dart';
import '../../data/local/isar_service.dart';
import 'cache_result.dart';

final cachePolicyProvider = Provider<CachePolicy>((ref) => CachePolicy());

/// Client-side stale-while-revalidate cache (C.3).
///
/// fetch() emits:
///   1. Cached value immediately (even if stale) — fast first paint.
///   2. Network response once available — seamless data refresh.
class CachePolicy {
  Isar get _isar => IsarService.instance;

  /// Standard stale-while-revalidate fetch.
  Stream<CacheResult<T>> fetch<T>({
    required String cacheKey,
    required int ttlSeconds,
    required Future<T> Function() networkFetch,
    required T Function(Map<String, dynamic>) fromJson,
  }) async* {
    // 1. Emit cached data immediately.
    final cached = await _isar.cachedResponses.where().cacheKeyEqualTo(cacheKey).findFirst();
    if (cached != null) {
      yield CacheResult<T>(
        data: fromJson(jsonDecode(cached.body) as Map<String, dynamic>),
        isFromCache: true,
      );
    }

    // 2. Background fetch if no cache or expired.
    if (cached == null || cached.isExpired) {
      final fresh = await networkFetch();
      await _persist(cacheKey, fresh, ttlSeconds);
      yield CacheResult<T>(data: fresh, isFromCache: false);
    }
  }

  /// Force-refresh: bypass cache, fetch from network, update L2.
  Future<T> forceRefresh<T>({
    required String cacheKey,
    required int ttlSeconds,
    required Future<T> Function() networkFetch,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final fresh = await networkFetch();
    await _persist(cacheKey, fresh, ttlSeconds);
    return fresh;
  }

  /// Invalidate a specific cache entry.
  Future<void> invalidate(String cacheKey) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.cachedResponses.where().cacheKeyEqualTo(cacheKey).findFirst();
      if (existing != null) await _isar.cachedResponses.delete(existing.id);
    });
  }

  Future<void> _persist<T>(String cacheKey, T data, int ttlSeconds) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.cachedResponses.where().cacheKeyEqualTo(cacheKey).findFirst();
      final record = (existing ?? CachedResponse())
        ..cacheKey  = cacheKey
        ..body      = jsonEncode(data)
        ..etag      = ''
        ..cachedAt  = DateTime.now()
        ..ttlSeconds = ttlSeconds;
      await _isar.cachedResponses.put(record);
    });
  }
}
