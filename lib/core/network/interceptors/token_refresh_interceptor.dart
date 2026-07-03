import 'package:dio/dio.dart';
import 'package:look_atlas/core/logging/app_logger.dart';

/// Refreshes an expired access token on 401 responses and replays the
/// original request.
///
/// Implemented as a [QueuedInterceptor]: Dio serializes the callbacks of a
/// QueuedInterceptor, so when several in-flight requests fail with 401 at
/// once, only one `onError` runs at a time. The first callback performs the
/// refresh and later ones replay with the already-refreshed token, which
/// prevents a concurrent-refresh stampede against the token endpoint.
///
/// The refresh call and the sign-out reaction are injected as callbacks so
/// this stays backend-agnostic (the template ships with a local auth repo).
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required this.refreshToken,
    required this.onAuthFailure,
  }) : _dio = dio;

  final Dio _dio;

  /// Performs the refresh call and returns the new access token, or `null`
  /// when the session cannot be refreshed. Implementations must also persist
  /// the new token wherever the request `tokenProvider` reads it from.
  final Future<String?> Function() refreshToken;

  /// Invoked when the refresh fails, e.g. to force a sign-out.
  final Future<void> Function() onAuthFailure;

  /// Marks a request that was already replayed after a refresh so a second
  /// 401 is surfaced instead of looping forever.
  static const _retriedKey = 'token_refresh_retried';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    if (err.response?.statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    String? newToken;
    try {
      newToken = await refreshToken();
    } on Object catch (error) {
      AppLogger.warning('Token refresh threw: $error');
      newToken = null;
    }

    if (newToken == null || newToken.isEmpty) {
      await onAuthFailure();
      handler.next(err);
      return;
    }

    final options = err.requestOptions
      ..extra[_retriedKey] = true
      ..headers['Authorization'] = 'Bearer $newToken';
    try {
      // `fetch` re-enters the full interceptor chain, so retry/logging still
      // apply to the replayed request.
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }
}
