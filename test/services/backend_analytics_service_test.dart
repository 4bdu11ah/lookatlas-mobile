import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/services/analytics/backend_analytics_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('track_flushes_ten_events_with_mobile_metadata', () async {
    final api = _MockApiService();
    when(
      () => api.post<void>(
        ApiEndpoints.analyticsSync,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    final service = BackendAnalyticsService(
      api,
      tokenProvider: () async => 'access-token',
    );
    await service.init();

    for (var index = 0; index < 9; index++) {
      await service.track('wizard.step_viewed');
    }

    final body =
        verify(
              () => api.post<void>(
                ApiEndpoints.analyticsSync,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, Object>;
    final events = body['events']! as List<Map<String, Object>>;
    final metadata = events.first['metadata']! as Map<String, Object>;
    expect(events, hasLength(10));
    expect(metadata['device_type'], 'mobile');
    expect(metadata['entry_sku'], 'none');
    await service.dispose();
  });
}
