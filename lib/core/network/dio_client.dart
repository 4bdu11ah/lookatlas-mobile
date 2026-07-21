import 'package:dio/dio.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/interceptors/auth_interceptor.dart';
import 'package:look_atlas/core/network/interceptors/logging_interceptor.dart';
import 'package:look_atlas/core/network/interceptors/retry_interceptor.dart';
import 'package:look_atlas/core/network/interceptors/token_refresh_interceptor.dart';

/// Factory for a configured [Dio] instance with sane timeouts, auth, and
/// logging. Construct one per base URL (e.g. your API, the AI proxy).
abstract final class DioClient {
  static Dio create({
    required String baseUrl,
    Future<String?> Function()? tokenProvider,
    Future<String?> Function()? refreshToken,
    Future<void> Function()? onAuthFailure,
    Map<String, String>? headers,
  }) {
    final dio =
        Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/json',
                if (headers != null) ...headers,
              },
            ),
          )
          // Decode large JSON bodies off the main isolate so parsing a big
          // response never janks the UI.
          ..transformer = BackgroundTransformer();

    // Interceptor order matters:
    // 1. Auth attaches the bearer token to every request, including requests
    //    replayed by the refresh and retry interceptors (both replay via
    //    `dio.fetch`, which re-enters this chain from the top).
    // 2. Token refresh sits before retry so a refreshed replay still gets
    //    retry coverage for transient failures.
    // 3. Logging is last so it observes the final request/response/error.
    if (tokenProvider != null) {
      dio.interceptors.add(AuthInterceptor(tokenProvider));
    }
    if (refreshToken != null && onAuthFailure != null) {
      dio.interceptors.add(
        TokenRefreshInterceptor(
          dio: dio,
          refreshToken: refreshToken,
          onAuthFailure: onAuthFailure,
        ),
      );
    }
    dio.interceptors.add(RetryInterceptor(dio));
    dio.interceptors.add(LoggingInterceptor());

    return dio;
  }
}

/// Maps a [DioException] to a typed [Failure] for the domain layer.
///
/// A cancelled request maps to [CancelledFailure] so callers can
/// pattern-match and ignore it; everything else maps to [NetworkFailure].
Failure mapDioError(DioException error) {
  if (error.type == DioExceptionType.cancel) {
    return CancelledFailure(
      'The request was cancelled.',
      cause: error,
      stackTrace: error.stackTrace,
    );
  }

  final status = error.response?.statusCode;
  final serverError = _serverError(error.response?.data);
  final message = switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'The connection timed out. Please try again.',
    DioExceptionType.connectionError =>
      'No internet connection. Please check your network.',
    DioExceptionType.badResponse =>
      serverError.$2 ??
          switch (status ?? 0) {
            401 || 403 => 'You are not authorized to do that.',
            404 => 'We could not find what you were looking for.',
            >= 500 => 'Something went wrong on our end. Please try again.',
            _ => 'The request failed. Please try again.',
          },
    _ => 'An unexpected network error occurred.',
  };

  return NetworkFailure(
    message,
    statusCode: status,
    code: serverError.$1,
    cause: error,
    stackTrace: error.stackTrace,
  );
}

(String?, String?) _serverError(Object? body) {
  if (body is! Map<String, dynamic>) return (null, null);
  final error = body['error'];
  if (error is Map<String, dynamic>) {
    final code = error['code'];
    final message = error['message'];
    return (code is String ? code : null, message is String ? message : null);
  }
  final message = body['message'];
  return (null, message is String ? message : null);
}
