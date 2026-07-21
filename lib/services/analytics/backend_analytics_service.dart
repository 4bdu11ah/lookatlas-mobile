import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';

class BackendAnalyticsService
    with WidgetsBindingObserver
    implements AnalyticsService {
  BackendAnalyticsService(this._api, {required this.tokenProvider});

  static const _flushInterval = Duration(seconds: 5);
  static const _flushThreshold = 10;
  static const _maxBatchSize = 50;

  final ApiService _api;
  final Future<String?> Function() tokenProvider;
  final List<Map<String, Object>> _queue = [];
  final String _sessionId = _uuid();
  Timer? _timer;
  bool _isFlushing = false;
  bool _initialized = false;

  @override
  Future<void> init() async {
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _timer ??= Timer.periodic(_flushInterval, (_) => unawaited(flush()));
    await track('session.started');
  }

  @override
  Future<void> track(
    String event, {
    Map<String, Object>? properties,
  }) async {
    _queue.add({
      'event': event,
      'metadata': {
        'device_type': 'mobile',
        'entry_sku': 'none',
        ...?properties,
      },
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'session_id': _sessionId,
    });
    if (_initialized && _queue.length >= _flushThreshold) await flush();
  }

  @override
  Future<void> screen(
    String name, {
    Map<String, Object>? properties,
  }) => track('screen.viewed', properties: {'screen': name, ...?properties});

  @override
  Future<void> identify(String userId, {Map<String, Object>? traits}) async {}

  @override
  Future<void> reset() => flush();

  Future<void> flush() async {
    if (_isFlushing || _queue.isEmpty) return;
    final token = await tokenProvider();
    if (token == null || token.isEmpty) return;
    _isFlushing = true;
    final size = min(_queue.length, _maxBatchSize);
    final batch = _queue.sublist(0, size);
    final result = await _api.post<void>(
      ApiEndpoints.analyticsSync,
      data: {'events': batch},
      decoder: (_) {},
    );
    if (result.isOk) _queue.removeRange(0, size);
    _isFlushing = false;
  }

  Future<void> dispose() async {
    _timer?.cancel();
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    if (_initialized) await flush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ({
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    }.contains(state)) {
      unawaited(flush());
    }
  }

  static String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

class CompositeAnalyticsService implements AnalyticsService {
  const CompositeAnalyticsService(this._services);

  final List<AnalyticsService> _services;

  @override
  Future<void> init() =>
      Future.wait(_services.map((service) => service.init()));

  @override
  Future<void> track(String event, {Map<String, Object>? properties}) =>
      Future.wait(
        _services.map(
          (service) => service.track(event, properties: properties),
        ),
      );

  @override
  Future<void> screen(String name, {Map<String, Object>? properties}) =>
      Future.wait(
        _services.map(
          (service) => service.screen(name, properties: properties),
        ),
      );

  @override
  Future<void> identify(String userId, {Map<String, Object>? traits}) =>
      Future.wait(
        _services.map(
          (service) => service.identify(userId, traits: traits),
        ),
      );

  @override
  Future<void> reset() =>
      Future.wait(_services.map((service) => service.reset()));
}
