import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:isar/isar.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/etag_cache.dart';

/// Attaches If-None-Match to requests and transparently converts 304 → 200.
///
/// On 304: reads the cached body from Isar and returns it as a 200 response.
/// Requires [ETagCache] Isar collection.
class ETagInterceptor extends Interceptor {
  ETagInterceptor({required this.isar});
  final Isar isar;

  String _key(RequestOptions opts) =>
      '${opts.method}:${opts.uri}';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final key = _key(options);
    final cached = await isar.eTagCaches.where().keyEqualTo(key).findFirst();
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
      final cached = await isar.eTagCaches.where().keyEqualTo(key).findFirst();
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
      await isar.writeTxn(() async {
        final existing = await isar.eTagCaches.where().keyEqualTo(key).findFirst();
        if (existing != null) {
          existing.etag = etag;
          existing.body = jsonEncode(response.data);
          existing.updatedAt = DateTime.now();
          await isar.eTagCaches.put(existing);
        } else {
          await isar.eTagCaches.put(ETagCache()
            ..key = key
            ..etag = etag
            ..body = jsonEncode(response.data)
            ..updatedAt = DateTime.now());
        }
      });
    }
    handler.next(response);
  }
}
