import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash and error reporting backed by Sentry.
///
/// If `SENTRY_DSN` is not set the reporter degrades to local logging only, so
/// the look_atlas runs with no Sentry account configured.
abstract final class CrashReporter {
  /// Initializes Sentry (if configured) and runs [appRunner] inside an error
  /// zone so uncaught errors are captured.
  static Future<void> init(FutureOr<void> Function() appRunner) async {
    if (!AppConfig.hasSentry) {
      await appRunner();
      return;
    }

    await SentryFlutter.init((options) {
      options
        ..dsn = AppConfig.sentryDsn
        ..environment = AppConfig.flavor.name
        ..tracesSampleRate = AppConfig.isProd ? 0.2 : 1.0
        ..debug = false
        ..sendDefaultPii = false;
    }, appRunner: appRunner);
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    AppLogger.error('Captured error', error: error, stackTrace: stackTrace);
    if (!AppConfig.hasSentry) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: fatal ? Hint.withMap({'fatal': true}) : null,
    );
  }

  /// Associates the current user with subsequent reports. Pass null on logout.
  static Future<void> setUser(String? id) async {
    if (!AppConfig.hasSentry) return;
    await Sentry.configureScope(
      (scope) => scope.setUser(id == null ? null : SentryUser(id: id)),
    );
  }

  /// Hooks Flutter's framework error handlers into the reporter. Call once at
  /// startup before `runApp`.
  ///
  /// Only installed when Sentry is NOT configured: `SentryFlutter.init`
  /// already registers `FlutterErrorIntegration`/`OnErrorIntegration`, and
  /// overwriting `FlutterError.onError` / `PlatformDispatcher.onError` here
  /// would replace them, losing Sentry's mechanism metadata
  /// (handled/unhandled marking) on captured events.
  static void installFlutterHandlers() {
    if (AppConfig.hasSentry) return;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(recordError(details.exception, details.stack, fatal: true));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(recordError(error, stack, fatal: true));
      return true;
    };
  }
}
