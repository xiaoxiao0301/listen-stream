import 'dart:async';

import 'package:dio/dio.dart';

/// Exponential-backoff retry: up to 3 retries on network errors.
/// Delays: 1 s, 2 s, 4 s.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, this.maxRetries = 3});
  final Dio dio;
  final int maxRetries;

  static const _delays = [1, 2, 4];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra['_retry'] as int? ?? 0;

    // Only retry on network/timeout errors, not 4xx/5xx.
    final isNetworkError = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if (!isNetworkError || attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    final delaySec = attempt < _delays.length ? _delays[attempt] : _delays.last;
    await Future.delayed(Duration(seconds: delaySec));

    err.requestOptions.extra['_retry'] = attempt + 1;
    try {
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }
}
