import 'dart:convert';

import 'package:look_atlas/core/storage/secure_storage.dart';
import 'package:look_atlas/features/auth/data/models/app_user_model.dart';

/// Persists the auth session on-device. The repository talks to this instead
/// of touching [SecureStorage] or JSON directly, so swapping to a remote
/// backend later is a one-file change.
abstract interface class AuthLocalDataSource {
  /// The cached user, or null when signed out.
  Future<AppUserModel?> readUser();

  /// Persists [user]. Token persistence is owned by the repository via the
  /// network layer's `AuthTokenCache`, not by this data source.
  Future<void> cacheUser(AppUserModel user);

  /// Clears the cached user and any stored tokens.
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._storage);

  final SecureStorage _storage;
  static const _userKey = 'auth_user';

  @override
  Future<AppUserModel?> readUser() async {
    final raw = await _storage.read(_userKey);
    if (raw == null) return null;
    return AppUserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> cacheUser(AppUserModel user) async {
    await _storage.write(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<void> clear() async {
    await _storage.delete(_userKey);
    await _storage.clearTokens();
  }
}
