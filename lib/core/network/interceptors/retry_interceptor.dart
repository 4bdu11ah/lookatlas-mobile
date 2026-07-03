import 'dart:math';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/logging/app_logger.dart';

/// Retries transient failures with exponential backoff and jitter.
///
/// Only idempotent methods (GET, HEAD) are retried so a half-completed POST is
/// never replayed. Retries apply to timeouts, connection drops, and 5xx/429
/// responses. When the server sends a `Retry-After` header (429/503), that
/// delay is honored instead of the computed backoff.
///
/// Note on interceptor ordering: `_dio.fetch(options)` re-enters the full
/// interceptor chain from the top, so `AuthInterceptor` refreshes the
/// Authorization header on every retried request. Do not "fix" the ordering
/// by replaying through a bare Dio — stale tokens would leak into retries.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  static const _idempotentMethods = {'GET', 'HEAD'};
  static const _attemptKey = 'retry_attempt';

  /// Upper bound for a server-provided `Retry-After` so a misbehaving server
  /// cannot stall the client for minutes.
  static const _maxRetryAfter = Duration(seconds: 30);

  final Random _random = Random();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    final delay = _retryAfter(err.response) ?? _backoffWithJitter(attempt);
    AppLogger.debug(
      'Retrying ${err.requestOptions.uri} '
      '(attempt ${attempt + 1}/$maxRetries) in ${delay.inMilliseconds}ms',
    );
    await Future<void>.delayed(delay);

    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  /// Exponential backoff (400ms, 800ms, 1600ms, ...) with ±25% random jitter
  /// so many clients recovering from the same outage don't retry in lockstep.
  Duration _backoffWithJitter(int attempt) {
    final backoffMs = baseDelay.inMilliseconds * (1 << attempt);
    final jitterFactor = 0.75 + _random.nextDouble() * 0.5;
    return Duration(milliseconds: (backoffMs * jitterFactor).round());
  }

  /// The server-requested delay from a `Retry-After` header on 429/503, or
  /// null when absent or not a plain seconds value (the HTTP-date form is
  /// ignored). Capped at [_maxRetryAfter].
  Duration? _retryAfter(Response<dynamic>? response) {
    final status = response?.statusCode;
    if (status != 429 && status != 503) return null;

    final header = response?.headers.value('retry-after');
    if (header == null) return null;

    final seconds = int.tryParse(header.trim());
    if (seconds == null || seconds < 0) return null;

    final delay = Duration(seconds: seconds);
    return delay > _maxRetryAfter ? _maxRetryAfter : delay;
  }

  bool _shouldRetry(DioException err) {
    if (!_idempotentMethods.contains(err.requestOptions.method.toUpperCase())) {
      return false;
    }
    final status = err.response?.statusCode;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse =>
        status == 429 || (status != null && status >= 500),
      _ => false,
    };
  }
}
