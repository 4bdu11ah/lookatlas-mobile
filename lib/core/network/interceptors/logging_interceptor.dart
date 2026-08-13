import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/logging/app_logger.dart';

/// Logs requests and responses in non-release builds with sensitive headers
/// redacted. AppLogger already suppresses debug output in release.
class LoggingInterceptor extends Interceptor {
  static const _methodsWithBody = {'POST', 'PUT', 'PATCH', 'DELETE'};
  static const _redactedHeaders = {'authorization', 'x-api-key', 'cookie'};
  static const _redactedFields = {
    'access_token',
    'api_key',
    'apikey',
    'authorization',
    'cookie',
    'password',
    'refresh_token',
    'secret',
    'token',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug(formatRequestLog(options));
    handler.next(options);
  }

  @visibleForTesting
  String formatRequestLog(RequestOptions options) {
    final message = StringBuffer(
      '→ ${options.method} ${options.uri}\n'
      'headers: ${_redact(options.headers)}',
    );
    if (_methodsWithBody.contains(options.method.toUpperCase())) {
      message.write('\nbody: ${formatRequestBody(options)}');
    }
    return message.toString();
  }

  @visibleForTesting
  Object? formatRequestBody(RequestOptions options) {
    return _formatBody(options.data);
  }

  Object? _formatBody(Object? data) {
    if (data is FormData) return _formatFormData(data);
    if (data is Uint8List) return '<binary: ${data.length} bytes>';
    if (data is Stream<List<int>>) return '<stream body>';
    if (data is String) return _formatRawString(data);
    return _sanitize(data);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    AppLogger.debug(formatResponseLog(response));
    handler.next(response);
  }

  @visibleForTesting
  String formatResponseLog(Response<dynamic> response) =>
      '← ${response.statusCode} ${response.requestOptions.uri}\n'
      'body: ${_formatBody(response.data)}';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Warnings pass the release log filter, so redact the query string in
    // release builds — it may carry identifiers or tokens.
    final uri = err.requestOptions.uri;
    final target = kReleaseMode ? uri.path : '$uri';
    final message = StringBuffer(
      '✕ ${err.response?.statusCode ?? ''} $target\n${err.message}',
    );
    AppLogger.warning(message);
    if (err.response != null) {
      AppLogger.debug('error body: ${_formatBody(err.response?.data)}');
    }
    handler.next(err);
  }

  Map<String, dynamic> _redact(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _redactedHeaders.contains(entry.key.toLowerCase())
            ? '***'
            : _sanitize(entry.value),
    };
  }

  Map<String, Object?> _formatFormData(FormData data) => {
    'fields': [
      for (final field in data.fields)
        {
          field.key: _isSensitiveField(field.key)
              ? '***'
              : _sanitize(field.value),
        },
    ],
    'files': [
      for (final file in data.files)
        {
          'field': file.key,
          'filename': _sanitize(file.value.filename),
          'contentType': file.value.contentType?.toString(),
          'length': file.value.length,
        },
    ],
  };

  Object? _formatRawString(String data) {
    try {
      return _sanitize(jsonDecode(data));
    } on FormatException {
      final redacted = data.replaceAllMapped(
        RegExp(
          r'((?:access_token|api_key|authorization|cookie|password|refresh_token|secret|token)=)[^&\s]*',
          caseSensitive: false,
        ),
        (match) => '${match.group(1)}***',
      );
      return _maskEmails(redacted);
    }
  }

  Object? _sanitize(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          '${entry.key}': _isSensitiveField('${entry.key}')
              ? '***'
              : _sanitize(entry.value),
      };
    }
    if (value is Iterable) return value.map(_sanitize).toList();
    if (value is String) return _maskEmails(value);
    return value;
  }

  bool _isSensitiveField(String field) {
    final normalized = field.toLowerCase().replaceAll('-', '_');
    return _redactedFields.contains(normalized) ||
        normalized.contains('password') ||
        normalized.endsWith('_token') ||
        normalized.endsWith('_secret');
  }

  String _maskEmails(String value) => value.replaceAllMapped(
    RegExp(
      r'\b([a-z0-9._%+-])[a-z0-9._%+-]*@([a-z0-9.-]+\.[a-z]{2,})\b',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}***@${match.group(2)}',
  );
}
