import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/services/local_notification_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class _FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeInitializationSettings());
    registerFallbackValue(_FakeNotificationDetails());
  });

  test('showCompletion_shows_one_notification_for_each_task', () async {
    final plugin = _MockNotificationsPlugin();
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    when(plugin.getNotificationAppLaunchDetails).thenAnswer((_) async => null);
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    final service = FlutterLocalNotificationService(plugin: plugin);

    await service.initialize(onTap: (_) {});
    await service.showCompletion(
      taskId: 'shoot-1',
      title: 'Shoot completed',
      body: 'Ready.',
      destination: '/shoots/1',
    );
    await service.showCompletion(
      taskId: 'shoot-1',
      title: 'Shoot completed',
      body: 'Ready.',
      destination: '/shoots/1',
    );

    verify(
      () => plugin.show(
        id: any(named: 'id'),
        title: 'Shoot completed',
        body: 'Ready.',
        notificationDetails: any(named: 'notificationDetails'),
        payload: '/shoots/1',
      ),
    ).called(1);
  });

  test('notificationTap_routes_to_its_payload_destination', () async {
    final plugin = _MockNotificationsPlugin();
    DidReceiveNotificationResponseCallback? onResponse;
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((invocation) async {
      onResponse =
          invocation.namedArguments[#onDidReceiveNotificationResponse]
              as DidReceiveNotificationResponseCallback?;
      return true;
    });
    when(plugin.getNotificationAppLaunchDetails).thenAnswer((_) async => null);
    final service = FlutterLocalNotificationService(plugin: plugin);
    String? destination;

    await service.initialize(onTap: (value) => destination = value);
    onResponse!(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '/shoots/shoot-1?from=dashboard',
      ),
    );

    expect(destination, '/shoots/shoot-1?from=dashboard');
  });
}
