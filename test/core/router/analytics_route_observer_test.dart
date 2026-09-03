import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/router/analytics_route_observer.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';

class _RecordingAnalytics implements AnalyticsService {
  final List<String> screens = [];

  @override
  Future<void> screen(
    String name, {
    Map<String, Object>? properties,
  }) async => screens.add(name);

  @override
  Future<void> identify(String userId, {Map<String, Object>? traits}) async {}

  @override
  Future<void> init() async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> track(
    String event, {
    Map<String, Object>? properties,
  }) async {}
}

void main() {
  test('does not report the same visible route repeatedly', () async {
    final analytics = _RecordingAnalytics();
    final observer = AnalyticsRouteObserver(analytics);
    final firstProductSize = MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'product_size'),
      builder: (_) => const SizedBox.shrink(),
    );
    final duplicateProductSize = MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'product_size'),
      builder: (_) => const SizedBox.shrink(),
    );
    final products = MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'dashboard_products'),
      builder: (_) => const SizedBox.shrink(),
    );

    observer
      ..didPush(firstProductSize, null)
      ..didReplace(
        newRoute: duplicateProductSize,
        oldRoute: firstProductSize,
      )
      ..didPush(products, duplicateProductSize)
      ..didPop(products, duplicateProductSize);
    await Future<void>.delayed(Duration.zero);

    expect(analytics.screens, [
      'product_size',
      'dashboard_products',
      'product_size',
    ]);
  });
}
