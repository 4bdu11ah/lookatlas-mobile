import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/logging/app_logger.dart';

/// Logs requests and responses in non-release builds with sensitive headers
/// redacted. AppLogger already suppresses debug output in release.
class LoggingInterceptor extends Interceptor {
  static const _redactedHeaders = {'authorization', 'x-api-key', 'cookie'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug(
      '→ ${options.method} ${options.uri}\n'
      'headers: ${_redact(options.headers)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    AppLogger.debug('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Warnings pass the release log filter, so redact the query string in
    // release builds — it may carry identifiers or tokens.
    final uri = err.requestOptions.uri;
    final target = kReleaseMode ? uri.path : '$uri';
    AppLogger.warning(
      '✕ ${err.response ?? ''}',
    );
    AppLogger.warning(
      '✕ ${err.response?.statusCode ?? ''} $target\n'
      '${err.message}',
    );
    handler.next(err);
  }

  Map<String, dynamic> _redact(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _redactedHeaders.contains(entry.key.toLowerCase())
            ? '***'
            : entry.value,
    };
  }
}
