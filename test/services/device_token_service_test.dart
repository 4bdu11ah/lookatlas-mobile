import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/storage/key_value_store.dart';
import 'package:look_atlas/services/device/device_info.dart';
import 'package:look_atlas/services/device/device_info_service.dart';
import 'package:look_atlas/services/device/device_token_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

class _MockDeviceInfoService extends Mock implements DeviceInfoService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bootstrap_persists_token_and_reuses_it', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _MockApiService();
    final deviceInfo = _MockDeviceInfoService();
    final store = await KeyValueStore.create();
    const info = DeviceInfo(
      deviceId: 'installation-1',
      identifierType: 'installationId',
      platform: 'ios',
      manufacturer: 'Apple',
      model: 'iPhone',
      systemName: 'iOS',
      systemVersion: '18',
    );
    when(deviceInfo.getDeviceInfo).thenAnswer((_) async => info);
    when(
      () => api.post<String>(
        ApiEndpoints.deviceTokenBootstrap,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok('dt_123'));
    final service = DeviceTokenService(
      publicApi: api,
      store: store,
      deviceInfo: deviceInfo,
    );

    final first = await service.context();
    final second = await service.context();

    expect(first.deviceToken, 'dt_123');
    expect(second.deviceToken, 'dt_123');
    expect(first.fingerprint, 'installation-1');
    expect(first.screenHash, isNotEmpty);
    expect(first.toRegistrationJson()['screenHash'], first.screenHash);
    verify(
      () => api.post<String>(
        ApiEndpoints.deviceTokenBootstrap,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });
}
