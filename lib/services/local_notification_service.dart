import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:look_atlas/core/logging/app_logger.dart';

typedef NotificationTapHandler = void Function(String destination);

abstract interface class LocalNotificationService {
  Future<void> initialize({required NotificationTapHandler onTap});

  Future<void> showCompletion({
    required String taskId,
    required String title,
    required String body,
    required String destination,
  });
}

class FlutterLocalNotificationService implements LocalNotificationService {
  FlutterLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'completion_alerts',
    'Completion alerts',
    description: 'Alerts when shoots and AI tasks finish.',
    importance: Importance.high,
  );
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'completion_alerts',
      'Completion alerts',
      channelDescription: 'Alerts when shoots and AI tasks finish.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final Set<String> _shownTaskIds = <String>{};
  NotificationTapHandler? _onTap;
  bool _initialized = false;

  @override
  Future<void> initialize({required NotificationTapHandler onTap}) async {
    _onTap = onTap;
    if (_initialized) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _handleResponse,
      );
      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_channel);
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
      _initialized = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _handleDestination(launch?.notificationResponse?.payload);
      }
    } on Object catch (error) {
      AppLogger.warning('Local notification initialization failed: $error');
    }
  }

  @override
  Future<void> showCompletion({
    required String taskId,
    required String title,
    required String body,
    required String destination,
  }) async {
    if (!_initialized || !_shownTaskIds.add(taskId)) return;
    try {
      await _plugin.show(
        id: taskId.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: _details,
        payload: destination,
      );
    } on Object catch (error) {
      _shownTaskIds.remove(taskId);
      AppLogger.warning('Local notification display failed: $error');
    }
  }

  void _handleResponse(NotificationResponse response) =>
      _handleDestination(response.payload);

  void _handleDestination(String? destination) {
    if (destination == null || !destination.startsWith('/')) return;
    _onTap?.call(destination);
  }
}
