import 'package:dio/dio.dart';
import 'package:look_atlas/core/logging/app_logger.dart';

/// Refreshes an expired access token on 401 responses and replays the
/// original request.
///
/// Concurrent 401 responses share [_refreshing], so the token endpoint is hit
/// once and every failed request replays with the same fresh token.
///
/// The refresh call and the sign-out reaction are injected as callbacks so
/// this stays backend-agnostic (the template ships with a local auth repo).
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required this.tokenProvider,
    required this.refreshToken,
    required this.onAuthFailure,
  }) : _dio = dio;

  final Dio _dio;

  /// Returns the access token currently persisted by the auth layer.
  final Future<String?> Function() tokenProvider;

  /// Performs the refresh call and returns the new access token, or `null`
  /// when the session cannot be refreshed. Implementations must also persist
  /// the new token wherever the request `tokenProvider` reads it from.
  final Future<String?> Function() refreshToken;

  /// Invoked when the refresh fails, e.g. to force a sign-out.
  final Future<void> Function() onAuthFailure;

  /// Marks a request that was already replayed after a refresh so a second
  /// 401 is surfaced instead of looping forever.
  static const _retriedKey = 'token_refresh_retried';

  Future<String?>? _refreshing;
  Future<void>? _expiringSession;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    if (alreadyRetried) {
      await _expireSession();
      handler.next(err);
      return;
    }

    final currentToken = await tokenProvider();
    if (currentToken == null || currentToken.isEmpty) {
      handler.next(err);
      return;
    }
    final failedAuthorization = err.requestOptions.headers['Authorization'];
    if (failedAuthorization != 'Bearer $currentToken') {
      await _replay(err, handler, currentToken);
      return;
    }

    final newToken = await _refreshOnce();
    if (newToken == null || newToken.isEmpty) {
      handler.next(err);
      return;
    }
    await _replay(err, handler, newToken);
  }

  Future<void> _replay(
    DioException error,
    ErrorInterceptorHandler handler,
    String token,
  ) async {
    final options = error.requestOptions
      ..extra[_retriedKey] = true
      ..headers['Authorization'] = 'Bearer $token';
    try {
      // `fetch` re-enters the full interceptor chain, so retry/logging still
      // apply to the replayed request.
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  Future<String?> _refreshOnce() {
    final activeRefresh = _refreshing;
    if (activeRefresh != null) return activeRefresh;

    late final Future<String?> refresh;
    refresh = _performRefresh().whenComplete(() {
      if (identical(_refreshing, refresh)) _refreshing = null;
    });
    _refreshing = refresh;
    return refresh;
  }

  Future<String?> _performRefresh() async {
    try {
      final token = await refreshToken();
      if (token != null && token.isNotEmpty) return token;
    } on Object catch (error) {
      AppLogger.warning('Token refresh threw: $error');
    }
    await _expireSession();
    return null;
  }

  Future<void> _expireSession() {
    final activeExpiration = _expiringSession;
    if (activeExpiration != null) return activeExpiration;

    late final Future<void> expiration;
    expiration = Future<void>.sync(onAuthFailure).whenComplete(() {
      if (identical(_expiringSession, expiration)) {
        _expiringSession = null;
      }
    });
    _expiringSession = expiration;
    return expiration;
  }
}
