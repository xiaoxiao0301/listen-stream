import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_client.dart';
import 'auth_state.dart';
import 'token_store.dart';

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Global authentication state manager (C.2).
///
/// State: AuthState = Authenticated | Unauthenticated | AuthLoading
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return checkAuthState();
  }

  // ── SDK-level helper accessors ──────────────────────────────────────────────
  TokenStore get _store => ref.read(tokenStoreProvider);
  Dio get _dio => ref.read(networkClientProvider);

  /// Called at cold start: if AT+RT present → authenticated without network.
  Future<AuthState> checkAuthState() async {
    final hasTokens = await _store.hasTokens();
    if (!hasTokens) return const Unauthenticated();
    final userId = await _store.getUserId();
    return Authenticated(userId: userId ?? '');
  }

  /// POST /auth/sms/verify → save tokens → authenticated.
  Future<void> loginWithSms(String phone, String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/auth/sms/verify',
        data: {'phone': phone, 'code': code},
      );
      final data = resp.data!;
      await _store.saveTokens(
        at:       data['accessToken']  as String,
        rt:       data['refreshToken'] as String,
        deviceId: data['deviceId']     as String,
        userId:   data['userId']       as String,
      );
      return Authenticated(userId: data['userId'] as String);
    });
  }

  /// Logout: fire-and-forget POST /auth/logout, then clear all local state.
  Future<void> logout({String? message}) async {
    // Fire-and-forget; ignore network errors on logout.
    try {
      await _dio.post<void>('/auth/logout');
    } catch (_) {}

    await _store.clearAll();
    // WsClient disconnect is done by its own provider listener.
    state = AsyncData(Unauthenticated(message));
  }
}
