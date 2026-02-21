import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/local/etag_cache.dart';
import '../../data/local/isar_service.dart';

/// Attaches If-None-Match to requests and transparently converts 304 → 200.
///
/// On 304: reads the cached body from SQLite and returns it as a 200 response.
class ETagInterceptor extends Interceptor {
  Database get _db => IsarService.instance;

  String _key(RequestOptions opts) => '${opts.method}:${opts.uri}';

  Future<ETagCache?> _find(String key) async {
    final rows = await _db.query(
      'etag_cache',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : ETagCache.fromMap(rows.first);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final key = _key(options);
    final cached = await _find(key);
    if (cached != null && cached.etag.isNotEmpty) {
      options.headers['If-None-Match'] = cached.etag;
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.statusCode == 304) {
      // Return the previously cached body as a 200 response.
      final key = _key(response.requestOptions);
      final cached = await _find(key);
      if (cached != null) {
        handler.resolve(Response(
          requestOptions: response.requestOptions,
          statusCode: 200,
          data: jsonDecode(cached.body),
        ));
        return;
      }
    }

    // Store/update ETag if present.
    final etag = response.headers.value('etag');
    if (etag != null && response.statusCode == 200) {
      final key = _key(response.requestOptions);
      final record = ETagCache(
        key: key,
        etag: etag,
        body: jsonEncode(response.data),
        updatedAt: DateTime.now(),
      );
      await _db.insert(
        'etag_cache',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 304 in error case (if validateStatus didn't accept it)
    if (err.response?.statusCode == 304) {
      final key = _key(err.requestOptions);
      final cached = await _find(key);
      if (cached != null) {
        handler.resolve(Response(
          requestOptions: err.requestOptions,
          statusCode: 200,
          data: jsonDecode(cached.body),
        ));
        return;
      }
    }
    handler.next(err);
  }
}
