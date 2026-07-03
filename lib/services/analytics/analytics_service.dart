import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Provider-agnostic analytics contract. Swap the implementation without
/// touching call sites. Never send PII or secrets as event properties.
abstract interface class AnalyticsService {
  Future<void> init();
  Future<void> track(String event, {Map<String, Object>? properties});
  Future<void> screen(String name, {Map<String, Object>? properties});
  Future<void> identify(String userId, {Map<String, Object>? traits});
  Future<void> reset();
}

/// Used when no analytics key is configured. Keeps the app running with zero
/// setup while logging events in dev for visibility.
class NoopAnalyticsService implements AnalyticsService {
  @override
  Future<void> init() async {}

  @override
  Future<void> track(String event, {Map<String, Object>? properties}) async {
    AppLogger.debug('analytics.track (noop): $event $properties');
  }

  @override
  Future<void> screen(String name, {Map<String, Object>? properties}) async {}

  @override
  Future<void> identify(String userId, {Map<String, Object>? traits}) async {}

  @override
  Future<void> reset() async {}
}

class PostHogAnalyticsService implements AnalyticsService {
  @override
  Future<void> init() async {
    final config = PostHogConfig(AppConfig.posthogApiKey)
      ..host = AppConfig.posthogHost
      ..captureApplicationLifecycleEvents = true
      ..debug = AppConfig.isDebugLoggingEnabled;
    await Posthog().setup(config);
  }

  @override
  Future<void> track(String event, {Map<String, Object>? properties}) =>
      Posthog().capture(eventName: event, properties: properties);

  @override
  Future<void> screen(String name, {Map<String, Object>? properties}) =>
      Posthog().screen(screenName: name, properties: properties);

  @override
  Future<void> identify(String userId, {Map<String, Object>? traits}) =>
      Posthog().identify(userId: userId, userProperties: traits);

  @override
  Future<void> reset() => Posthog().reset();
}

/// Returns the configured service, falling back to the no-op implementation.
AnalyticsService createAnalyticsService() =>
    AppConfig.hasPosthog ? PostHogAnalyticsService() : NoopAnalyticsService();
