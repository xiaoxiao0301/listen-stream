import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_keys.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Pure secure-storage layer for JWT tokens and device identity.
class TokenStore {
  TokenStore()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
          mOptions: MacOsOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
            useDataProtectionKeyChain: true,
          ),
        );

  final FlutterSecureStorage _storage;
  bool _usePrefs = false;

  Future<void> saveTokens({
    required String at,
    required String rt,
    required String deviceId,
    required String userId,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: StorageKeys.accessToken,  value: at),
        _storage.write(key: StorageKeys.refreshToken, value: rt),
        _storage.write(key: StorageKeys.deviceId,     value: deviceId),
        _storage.write(key: StorageKeys.userId,        value: userId),
      ]);
    } catch (e) {
      // Fallback to SharedPreferences if secure storage fails (e.g., Keychain entitlement issues)
      print('[TokenStore] Secure storage failed ($e), falling back to SharedPreferences');
      _usePrefs = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.accessToken, at);
      await prefs.setString(StorageKeys.refreshToken, rt);
      await prefs.setString(StorageKeys.deviceId, deviceId);
      await prefs.setString(StorageKeys.userId, userId);
    }
  }

  Future<String?> getAccessToken() async {
    if (_usePrefs) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.accessToken);
    }
    return _storage.read(key: StorageKeys.accessToken);
  }
  
  Future<String?> getRefreshToken() async {
    if (_usePrefs) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.refreshToken);
    }
    return _storage.read(key: StorageKeys.refreshToken);
  }
  
  Future<String?> getDeviceId() async {
   if (_usePrefs) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.deviceId);
    }
    return _storage.read(key: StorageKeys.deviceId);
  }
  
  Future<String?> getUserId() async {
    if (_usePrefs) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.userId);
    }
    return _storage.read(key: StorageKeys.userId);
  }

  Future<bool> hasTokens() async {
    final at = await getAccessToken();
    final rt = await getRefreshToken();
    return at != null && rt != null;
  }

  /// Called on logout: wipes all auth material from secure storage.
  Future<void> clearAll() async {
    if (_usePrefs) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.accessToken);
      await prefs.remove(StorageKeys.refreshToken);
      await prefs.remove(StorageKeys.deviceId);
      await prefs.remove(StorageKeys.userId);
    } else {
      await _storage.deleteAll();
    }
  }
}
