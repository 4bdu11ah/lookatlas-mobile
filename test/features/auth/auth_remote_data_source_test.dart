import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:look_atlas/features/auth/data/models/app_user_model.dart';
import 'package:look_atlas/features/auth/data/models/auth_session_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  test('register_sends_starter_plan_and_device_context', () async {
    final api = _MockApiService();
    final publicApi = _MockApiService();
    const session = AuthSessionModel(
      accessToken: 'access',
      user: AppUserModel(id: 'user-1', email: 'a@example.com'),
    );
    when(
      () => publicApi.post<AuthSessionModel>(
        ApiEndpoints.authRegister,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(session));
    final dataSource = AuthRemoteDataSourceImpl(
      api: api,
      publicApi: publicApi,
      registrationContext: () async => {
        'deviceFingerprint': 'installation-1',
        'deviceToken': 'dt_123',
        'uaFamily': 'ios',
        'tzOffset': 300,
      },
    );

    await dataSource.register(
      companyName: 'Atlas',
      email: 'a@example.com',
      password: 'password123',
      captchaToken: 'turnstile-token',
    );
    final body =
        verify(
              () => publicApi.post<AuthSessionModel>(
                ApiEndpoints.authRegister,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, Object?>;

    expect(body['plan'], 'starter');
    expect(body['deviceToken'], 'dt_123');
    expect(body['deviceFingerprint'], 'installation-1');
    expect(body['captchaToken'], 'turnstile-token');
  });
}
