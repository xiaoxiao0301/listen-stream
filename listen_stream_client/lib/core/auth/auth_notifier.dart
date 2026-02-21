import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_client.dart';
import '../ws/ws_client.dart';
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
    // Reconnect WS on cold start if already logged in.
    ref.read(wsClientProvider).connect();
    return Authenticated(userId: userId ?? '');
  }

  /// POST /auth/sms/verify → save tokens → authenticated.
  ///
  /// Throws on failure so the caller can show errors in the UI.
  Future<void> loginWithSms(String phone, String code) async {
    state = const AsyncLoading();
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/auth/sms/verify',
        data: {'phone': phone, 'code': code},
      );
      final data = resp.data!;
      final at       = data['access_token']  as String;
      final rt       = data['refresh_token'] as String;
      final deviceId = data['device_id']     as String;
      final userId   = _jwtSub(at);
      await _store.saveTokens(
        at:       at,
        rt:       rt,
        deviceId: deviceId,
        userId:   userId,
      );
      state = AsyncData(Authenticated(userId: userId));
      ref.read(wsClientProvider).connect();
    } catch (e, st) {
      debugPrint('[AuthNotifier] loginWithSms error: $e\n$st');
      state = AsyncError(e, st);
      rethrow; // surface the error to _submit so the UI can react
    }
  }

  /// Decode the `sub` claim from a JWT without verifying the signature.
  static String _jwtSub(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return '';
    // Base64Url-decode the payload (add padding if needed).
    var payload = parts[1];
    payload += '=' * ((4 - payload.length % 4) % 4);
    final json = utf8.decode(base64Url.decode(payload));
    final map  = jsonDecode(json) as Map<String, dynamic>;
    return map['sub'] as String? ?? '';
  }

  /// Logout: fire-and-forget POST /auth/logout, then clear all local state.
  Future<void> logout({String? message}) async {
    // Fire-and-forget; ignore network errors on logout.
    try {
      await _dio.post<void>('/auth/logout');
    } catch (_) {}

    await _store.clearAll();
    ref.read(wsClientProvider).disconnect();
    state = AsyncData(Unauthenticated(message));
  }
}
