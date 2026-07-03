import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key/value storage for sensitive data (auth tokens, refresh
/// tokens). Backed by the iOS Keychain and Android EncryptedSharedPreferences.
///
/// Do not store large blobs here; use it only for secrets.
class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  /// Deletes **every** secret in secure storage, not just auth tokens.
  ///
  /// Prefer [clearTokens] for sign-out. Also note the iOS Keychain persists
  /// across app reinstalls, so anything not cleared here (or on first launch)
  /// can outlive the app itself.
  Future<void> clear() => _storage.deleteAll();

  // Convenience accessors for the common auth flow.
  Future<String?> get accessToken => read(_accessTokenKey);
  Future<void> setAccessToken(String token) => write(_accessTokenKey, token);
  Future<void> deleteAccessToken() => delete(_accessTokenKey);

  Future<String?> get refreshToken => read(_refreshTokenKey);
  Future<void> setRefreshToken(String token) => write(_refreshTokenKey, token);

  /// Deletes only the access and refresh tokens, leaving other secrets
  /// untouched. Use this for sign-out instead of [clear].
  Future<void> clearTokens() async {
    await delete(_accessTokenKey);
    await delete(_refreshTokenKey);
  }
}
