import 'package:look_atlas/core/storage/secure_storage.dart';

/// In-memory cache in front of [SecureStorage] for the access token.
///
/// Reading secure storage goes through a platform channel (iOS Keychain /
/// Android EncryptedSharedPreferences), which is far too slow to do on every
/// HTTP request. This cache reads the token once and serves it from memory
/// afterwards, writing changes through to secure storage.
///
/// Auth code MUST keep the cache in sync: call [set] with the new token on
/// sign-in and token refresh, and [set] with `null` (or [invalidate] after
/// clearing storage) on sign-out. A stale cache means requests carry a stale
/// token.
class AuthTokenCache {
  AuthTokenCache(this._storage);

  final SecureStorage _storage;

  String? _cached;
  bool _loaded = false;

  /// The current access token, reading secure storage only on the first call
  /// (or after [invalidate]).
  Future<String?> get() async {
    if (_loaded) return _cached;
    _cached = await _storage.accessToken;
    _loaded = true;
    return _cached;
  }

  /// Updates the in-memory token and writes through to secure storage.
  ///
  /// Pass `null` to delete the stored access token (sign-out).
  Future<void> set(String? token) async {
    _cached = token;
    _loaded = true;
    if (token == null) {
      await _storage.deleteAccessToken();
    } else {
      await _storage.setAccessToken(token);
    }
  }

  /// Drops the in-memory copy; the next [get] re-reads secure storage.
  void invalidate() {
    _cached = null;
    _loaded = false;
  }
}
