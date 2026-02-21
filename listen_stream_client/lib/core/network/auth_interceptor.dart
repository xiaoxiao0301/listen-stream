import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_notifier.dart';
import '../auth/token_store.dart';

/// Injects Authorization header and handles 401 → token-refresh → retry.
///
/// Single-flight guarantee: if multiple requests 401 simultaneously only one
/// refresh is attempted. All others await the same Completer.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.ref});

  final Dio dio;
  final Ref ref;

  static Completer<bool>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokenStore = ref.read(tokenStoreProvider);
    final at = await tokenStore.getAccessToken();
    if (at != null) {
      options.headers['Authorization'] = 'Bearer $at';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final tokenStore = ref.read(tokenStoreProvider);

    // If already refreshing, wait for the ongoing refresh result.
    if (_refreshCompleter != null) {
      final success = await _refreshCompleter!.future;
      if (success) {
        final at = await tokenStore.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $at';
        handler.resolve(await dio.fetch(err.requestOptions));
      } else {
        _forceLogout(err, handler);
      }
      return;
    }

    // First 401 — start refresh.
    _refreshCompleter = Completer<bool>();
    try {
      final rt = await tokenStore.getRefreshToken();
      final deviceId = await tokenStore.getDeviceId();
      if (rt == null || deviceId == null) {
        _refreshCompleter!.complete(false);
        _forceLogout(err, handler);
        return;
      }

      // Call refresh endpoint using a fresh Dio instance to avoid interceptor loops.
      final tempDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final resp = await tempDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': rt, 'deviceId': deviceId},
      );
      final data = resp.data!;
      await tokenStore.saveTokens(
        at: data['access_token'] as String,
        rt: data['refresh_token'] as String,
        deviceId: deviceId,
        userId: await tokenStore.getUserId() ?? '',
      );
      _refreshCompleter!.complete(true);

      // Retry the original request.
      final newAt = await tokenStore.getAccessToken();
      err.requestOptions.headers['Authorization'] = 'Bearer $newAt';
      handler.resolve(await dio.fetch(err.requestOptions));
    } catch (_) {
      _refreshCompleter!.complete(false);
      _forceLogout(err, handler);
    } finally {
      _refreshCompleter = null;
    }
  }

  void _forceLogout(DioException err, ErrorInterceptorHandler handler) {
    ref.read(authNotifierProvider.notifier).logout(message: '登录已过期，请重新登录');
    handler.next(err);
  }
}
