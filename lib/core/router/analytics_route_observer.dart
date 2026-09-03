import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';

/// Reports a screen view to analytics on every navigation, using the route's
/// name (set via `settings.name`, which go_router populates from the path).
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;
  String? _lastTrackedName;

  void _track(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty || name == _lastTrackedName) return;
    _lastTrackedName = name;
    unawaited(_analytics.screen(name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _track(previousRoute);
  }
}
