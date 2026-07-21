import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/services/device/device_info_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('device_info_test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('getDeviceInfo_validNativeResponse_returnsTypedDeviceInfo', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getDeviceInfo');
      return <String, Object?>{
        'deviceId': 'device-123',
        'identifierType': 'androidId',
        'platform': 'android',
        'manufacturer': 'Google',
        'model': 'Pixel 9',
        'systemName': 'Android',
        'systemVersion': '16',
        'apiLevel': 36,
      };
    });
    const service = DeviceInfoService(channel: channel);

    final info = await service.getDeviceInfo();

    expect(info.deviceId, 'device-123');
    expect(info.identifierType, 'androidId');
    expect(info.platform, 'android');
    expect(info.manufacturer, 'Google');
    expect(info.model, 'Pixel 9');
    expect(info.systemName, 'Android');
    expect(info.systemVersion, '16');
    expect(info.apiLevel, 36);
  });

  test('getDeviceInfo_missingRequiredField_throwsFormatException', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      return <String, Object?>{
        'identifierType': 'keychainUuid',
        'platform': 'ios',
        'manufacturer': 'Apple',
        'model': 'iPhone17,1',
        'systemName': 'iOS',
        'systemVersion': '18.0',
      };
    });
    const service = DeviceInfoService(channel: channel);

    final future = service.getDeviceInfo();

    await expectLater(future, throwsA(isA<FormatException>()));
  });

  test('getDeviceInfo_iOSResponse_allowsMissingApiLevel', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      return <String, Object?>{
        'deviceId': 'keychain-uuid',
        'identifierType': 'keychainUuid',
        'platform': 'ios',
        'manufacturer': 'Apple',
        'model': 'iPhone17,1',
        'systemName': 'iOS',
        'systemVersion': '18.0',
      };
    });
    const service = DeviceInfoService(channel: channel);

    final info = await service.getDeviceInfo();

    expect(info.deviceId, 'keychain-uuid');
    expect(info.identifierType, 'keychainUuid');
    expect(info.platform, 'ios');
    expect(info.apiLevel, isNull);
  });

  test('getDeviceInfo_nullNativeResponse_throwsStateError', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    const service = DeviceInfoService(channel: channel);

    final future = service.getDeviceInfo();

    await expectLater(future, throwsStateError);
  });
}
