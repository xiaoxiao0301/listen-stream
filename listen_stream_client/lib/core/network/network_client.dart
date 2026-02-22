import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_interceptor.dart';
import 'etag_interceptor.dart';
import 'retry_interceptor.dart';

/// Provider for the application-wide Dio instance.
final networkClientProvider = Provider<Dio>((ref) {
  return NetworkClient.build(ref);
});

class NetworkClient {
  NetworkClient._();

  /// Builds a Dio instance with the full interceptor chain (C.1 spec order):
  ///   1. AuthInterceptor  — inject AT, 401→refresh
  ///   2. ETagInterceptor  — If-None-Match + 304→200 transparent translation
  ///   3. RetryInterceptor — exponential backoff (max 3 retries: 1s/2s/4s)
  ///   4. LogInterceptor   — DEBUG only
  static Dio build(Ref ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8002'),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
        // Accept 304 Not Modified as valid response (handled by ETagInterceptor)
        validateStatus: (status) => status != null && status >= 200 && status < 400,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(dio: dio, ref: ref),
      if (!kDebugMode) ETagInterceptor(),
      RetryInterceptor(dio: dio),
      if (const bool.fromEnvironment('dart.vm.product', defaultValue: false) == false)
        LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}
