import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/config/app_config.dart';

/// Project-owned logger that emits console-safe chunks without truncation.
///
/// Never pass unredacted secrets or tokens. Debug and info logs are disabled
/// for release and production builds.
abstract final class AppLogger {
  static const int _consoleChunkSize = 800;
  static const String _resetColor = '\x1B[0m';

  static void debug(Object? message) {
    if (AppConfig.isDebugLoggingEnabled) _write('DEBUG', message);
  }

  static void info(Object? message) {
    if (AppConfig.isDebugLoggingEnabled) _write('INFO', message);
  }

  static void warning(Object? message) => _write('WARNING', message);

  static void error(Object? message, {Object? error, StackTrace? stackTrace}) {
    final output = StringBuffer()..write(message);
    if (error != null) output.write('\nerror: $error');
    if (stackTrace != null) output.write('\n$stackTrace');
    _write('ERROR', output);
  }

  static void _write(String level, Object? message) {
    formatLogLines(level, message).forEach(debugPrint);
  }

  @visibleForTesting
  static List<String> formatLogLines(String level, Object? message) {
    final color = switch (level) {
      'DEBUG' => '\x1B[36m',
      'INFO' => '\x1B[32m',
      'WARNING' => '\x1B[33m',
      'ERROR' => '\x1B[31m',
      _ => '',
    };
    return [
      for (final line in frameMessage('[$level] $message'))
        '$color$line$_resetColor',
    ];
  }

  @visibleForTesting
  static List<String> frameMessage(String message, {DateTime? timestamp}) {
    final time = _formatTime(timestamp ?? DateTime.now());
    return [
      '<-------------------- START $time -------------------->',
      ...chunkMessage(message),
      '<-------------------- END $time -------------------->',
    ];
  }

  @visibleForTesting
  static List<String> chunkMessage(
    String message, {
    int chunkSize = _consoleChunkSize,
  }) {
    if (chunkSize < 2) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be at least 2');
    }
    final chunks = <String>[];
    for (var start = 0; start < message.length;) {
      var end = (start + chunkSize).clamp(0, message.length);
      if (end < message.length &&
          _isHighSurrogate(message.codeUnitAt(end - 1)) &&
          _isLowSurrogate(message.codeUnitAt(end))) {
        end--;
      }
      chunks.add(message.substring(start, end));
      start = end;
    }
    return chunks;
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

  static bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;

  static String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final period = timestamp.hour < 12 ? 'AM' : 'PM';
    return '${_twoDigits(hour)}:'
        '${_twoDigits(timestamp.minute)}:'
        '${_twoDigits(timestamp.second)} $period';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
