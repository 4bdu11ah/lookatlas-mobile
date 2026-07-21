import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/data/data_sources/onboarding_remote_data_source.dart';
import 'package:look_atlas/features/onboarding/data/models/start_shoot_response_model.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late OnboardingRemoteDataSource dataSource;

  setUp(() {
    api = _MockApiService();
    dataSource = OnboardingRemoteDataSourceImpl(api: api);
  });

  test('create_product_sends_repeated_photo_parts_and_view_angles', () async {
    when(
      () => api.post<String>(
        ApiEndpoints.products,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok('product-1'));
    final draft = ProductDraft(
      name: 'Product',
      sku: 'onboarding-1',
      category: 'tops',
      photos: [
        OnboardingUpload(bytes: Uint8List(2), fileName: 'front.jpg'),
        OnboardingUpload(bytes: Uint8List(2), fileName: 'back.jpg'),
      ],
      viewAngles: const ['Front', 'Back'],
    );

    final result = await dataSource.createProduct(draft);
    final captured =
        verify(
              () => api.post<String>(
                ApiEndpoints.products,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;

    expect(result.valueOrNull, 'product-1');
    expect(captured.files.map((part) => part.key), ['photos', 'photos']);
    final fields = Map<String, String>.fromEntries(captured.fields);
    expect(fields['category'], 'tops');
    expect(fields['view_angles'], '["Front","Back"]');
  });

  test('start_shoot_sends_backend_enum_values_and_settings', () async {
    when(
      () => api.post<StartShootResponseModel>(
        ApiEndpoints.onboardingStartShoot,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer(
      (_) async => const Result.ok(
        StartShootResponseModel(
          entity: StartShootResponse(
            id: 'job-1',
            status: 'pending',
            message: 'Started',
            shotCount: 3,
            variations: 5,
            totalImages: 15,
          ),
        ),
      ),
    );

    await dataSource.startShoot(
      const StartShootRequest(
        productId: 'product-1',
        modelId: 'model-1',
        modelSource: ShootModelSource.lookatlas,
        settings: ShootSettings(
          aspectRatio: '3:4',
          directorId: 'luxury-editorial',
        ),
      ),
    );
    final body =
        verify(
              () => api.post<StartShootResponseModel>(
                ApiEndpoints.onboardingStartShoot,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;

    expect(body['modelSource'], 'lookatlas');
    expect(body['settings'], {
      'useCase': 'pdp',
      'directorId': 'luxury-editorial',
      'background': 'ai_decide',
      'aspectRatio': '3:4',
    });
  });
}
