import 'package:logger/logger.dart';
import 'package:look_atlas/core/config/app_config.dart';

/// Thin wrapper over `logger` with environment-aware verbosity.
///
/// Never pass secrets, tokens, or full request bodies that may contain
/// credentials. In release builds only warnings and errors are emitted.
abstract final class AppLogger {
  static final Logger _logger = Logger(
    filter: _AppLogFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      lineLength: 100,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(Object? message) => _logger.d(message);
  static void info(Object? message) => _logger.i(message);
  static void warning(Object? message) => _logger.w(message);

  static void error(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (AppConfig.isDebugLoggingEnabled) return true;
    return event.level.index >= Level.warning.index;
  }
}
