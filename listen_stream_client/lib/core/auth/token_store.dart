import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_keys.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Pure secure-storage layer for JWT tokens and device identity.
class TokenStore {
  TokenStore()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String at,
    required String rt,
    required String deviceId,
    required String userId,
  }) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken,  value: at),
      _storage.write(key: StorageKeys.refreshToken, value: rt),
      _storage.write(key: StorageKeys.deviceId,     value: deviceId),
      _storage.write(key: StorageKeys.userId,        value: userId),
    ]);
  }

  Future<String?> getAccessToken()  => _storage.read(key: StorageKeys.accessToken);
  Future<String?> getRefreshToken() => _storage.read(key: StorageKeys.refreshToken);
  Future<String?> getDeviceId()     => _storage.read(key: StorageKeys.deviceId);
  Future<String?> getUserId()       => _storage.read(key: StorageKeys.userId);

  Future<bool> hasTokens() async {
    final at = await getAccessToken();
    final rt = await getRefreshToken();
    return at != null && rt != null;
  }

  /// Called on logout: wipes all auth material from secure storage.
  Future<void> clearAll() => _storage.deleteAll();
}
