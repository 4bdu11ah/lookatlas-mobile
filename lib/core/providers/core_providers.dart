import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/storage/auth_token_cache.dart';
import 'package:look_atlas/core/storage/key_value_store.dart';
import 'package:look_atlas/core/storage/secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `bootstrap.dart` with the resolved instance so the rest of
/// the app can read it synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in ProviderScope at bootstrap'),
);

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => KeyValueStore(ref.watch(sharedPreferencesProvider)),
);

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

/// Bare backend client for endpoints that must not attach auth or participate
/// in the authenticated client's refresh interceptor.
final publicApiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(baseUrl: AppConfig.apiBaseUrl),
);

/// In-memory cache over the persisted access token so the network layer does
/// not hit the Keychain platform channel on every request.
///
/// Auth code must call [AuthTokenCache.set] on sign-in/refresh and
/// [AuthTokenCache.set] with `null` (or [AuthTokenCache.invalidate]) on
/// sign-out so the cache never serves a stale token.
final authTokenCacheProvider = Provider<AuthTokenCache>(
  (ref) => AuthTokenCache(ref.watch(secureStorageProvider)),
);

/// Callbacks the network layer uses to recover from an expired session.
class TokenRefresher {
  const TokenRefresher({
    required this.refreshToken,
    required this.onAuthFailure,
  });

  /// Performs the backend refresh call, persists the new access token (e.g.
  /// via [AuthTokenCache.set]), and returns it — or `null` when the session
  /// cannot be refreshed.
  final Future<String?> Function() refreshToken;

  /// Invoked when the refresh fails, e.g. to force a sign-out.
  final Future<void> Function() onAuthFailure;
}

/// Seam for 401 token refresh. Returns `null` by default, which disables the
/// refresh interceptor — the template ships with a local auth repo and has no
/// token endpoint. When you wire a real backend, override this provider with
/// a [TokenRefresher] that calls your refresh endpoint and signs the user out
/// on failure.
final tokenRefresherProvider = Provider<TokenRefresher?>((ref) => null);

/// App version + build number, e.g. "1.0.0 (1)". Shown in Settings.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// Shared API client for your backend. The bearer token is served per request
/// from [authTokenCacheProvider] (memory-first, secure storage behind it), so
/// it always reflects the current session without a Keychain read per call.
final apiServiceProvider = Provider<ApiService>((ref) {
  final tokenCache = ref.watch(authTokenCacheProvider);
  final tokenRefresher = ref.watch(tokenRefresherProvider);
  return ApiService(
    baseUrl: AppConfig.apiBaseUrl,
    tokenProvider: tokenCache.get,
    refreshToken: tokenRefresher?.refreshToken,
    onAuthFailure: tokenRefresher?.onAuthFailure,
  );
});
