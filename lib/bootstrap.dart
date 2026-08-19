import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/app/app.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/router/app_router.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/services/crash/crash_reporter.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/widgets/app_error_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Composition root. Initializes services and starts the app inside a
/// Sentry-guarded error zone (when configured) so startup crashes are caught.
Future<void> bootstrap() async {
  // Refuse to ship a raw Anthropic key inside a prod binary — anyone can
  // extract and abuse it. See the AI section of `AppConfig` for the intended
  // setup: point AI_BASE_URL at a backend proxy that injects the key.
  if (kReleaseMode && AppConfig.isProd && AppConfig.hasAiKey) {
    throw StateError(
      'AI_API_KEY must not ship in prod builds — point AI_BASE_URL at a '
      'backend proxy instead.',
    );
  }

  await CrashReporter.init(() async {
    WidgetsFlutterBinding.ensureInitialized();
    CrashReporter.installFlutterHandlers();

    // Replace the red error box with a friendly screen in release builds.
    if (kReleaseMode) {
      ErrorWidget.builder = (_) => const AppErrorWidget();
    }

    final prefs = await SharedPreferences.getInstance();
    late final AuthRepository authRepository;
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Wire the network layer's 401 recovery to the auth feature: refresh
        // the token and clear the session when refresh fails. Capture the
        // repository as a plain object so this provider does not read back
        // into authRepositoryProvider and create a Riverpod cycle.
        tokenRefresherProvider.overrideWithValue(
          TokenRefresher(
            refreshToken: () => authRepository.refreshSession(),
            onAuthFailure: () => authRepository.handleSessionExpired(),
          ),
        ),
      ],
    );
    authRepository = container.read(authRepositoryProvider);

    // Only what the first frame needs (theme + initial auth route) blocks here.
    await _initCritical(container);

    runApp(UncontrolledProviderScope(container: container, child: const App()));

    // Warm everything else after the first frame so time-to-interactive stays
    // low. These never block what the user sees.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmDeferred(container));
    });
  });
}

/// Restores the persisted session before the first frame so the router can
/// redirect correctly without a flash of the sign-in screen.
Future<void> _initCritical(ProviderContainer container) async {
  await _guard('auth', () => container.read(authRepositoryProvider).restore());
}

/// Non-critical services, warmed after the UI is on screen. The steps are
/// independent, so they run in parallel; each keeps its own `_guard` so one
/// failing service never blocks the others.
Future<void> _warmDeferred(ProviderContainer container) async {
  await Future.wait([
    _guard('analytics', () => container.read(analyticsServiceProvider).init()),
    _guard(
      'device token',
      () => container.read(deviceTokenServiceProvider).context(),
    ),
    _guard('subscriptions', () async {
      // A null userId configures RevenueCat with an anonymous app user id,
      // which is required for the purchase-before-login flow: the paywall is
      // public and anonymous purchases transfer to the account on sign-up.
      final userId = container.read(authRepositoryProvider).currentUser?.id;
      await container
          .read(subscriptionRepositoryProvider)
          .configure(appUserId: userId);
    }),
    _guard('local notifications', () {
      return container
          .read(localNotificationServiceProvider)
          .initialize(
            onTap: (destination) =>
                container.read(routerProvider).go(destination),
          );
    }),
  ]);
}

Future<void> _guard(String step, Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (error, stack) {
    await CrashReporter.recordError(error, stack);
  }
}
