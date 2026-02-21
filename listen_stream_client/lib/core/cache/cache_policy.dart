import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

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
  Database get _db => IsarService.instance;

  Future<CachedResponse?> _find(String cacheKey) async {
    final rows = await _db.query(
      'cached_responses',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    return rows.isEmpty ? null : CachedResponse.fromMap(rows.first);
  }

  /// Standard stale-while-revalidate fetch.
  Stream<CacheResult<T>> fetch<T>({
    required String cacheKey,
    required int ttlSeconds,
    required Future<T> Function() networkFetch,
    required T Function(Map<String, dynamic>) fromJson,
  }) async* {
    // 1. Emit cached data immediately.
    final cached = await _find(cacheKey);
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
    await _db.delete(
      'cached_responses',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
  }

  Future<void> _persist<T>(String cacheKey, T data, int ttlSeconds) async {
    final record = CachedResponse(
      cacheKey: cacheKey,
      body: jsonEncode(data),
      etag: '',
      cachedAt: DateTime.now(),
      ttlSeconds: ttlSeconds,
    );
    await _db.insert(
      'cached_responses',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
