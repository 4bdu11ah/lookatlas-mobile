import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/data/data_sources/onboarding_remote_data_source.dart';
import 'package:look_atlas/features/onboarding/data/models/onboarding_user_model_dto.dart';
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

  test('complete_onboarding_posts_empty_json_body', () async {
    when(
      () => api.post<void>(
        ApiEndpoints.onboardingComplete,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    final result = await dataSource.completeOnboarding();

    expect(result.isOk, isTrue);
    verify(
      () => api.post<void>(
        ApiEndpoints.onboardingComplete,
        data: const <String, Object?>{},
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
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

  test('update_product_sends_full_photo_list_to_stored_product_id', () async {
    when(
      () => api.put<void>(
        ApiEndpoints.product('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    final draft = ProductDraft(
      name: 'Product',
      sku: 'onboarding-1',
      category: 'tops',
      photos: [
        OnboardingUpload(bytes: Uint8List(2), fileName: 'front.jpg'),
        OnboardingUpload(bytes: Uint8List(2), fileName: 'back.jpg'),
        OnboardingUpload(bytes: Uint8List(2), fileName: 'side.jpg'),
      ],
    );

    await dataSource.updateProduct('product-1', draft);
    final captured =
        verify(
              () => api.put<void>(
                ApiEndpoints.product('product-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;

    expect(captured.files.map((part) => part.key), [
      'photos',
      'photos',
      'photos',
    ]);
    expect(
      Map<String, String>.fromEntries(captured.fields)['category'],
      'tops',
    );
  });

  test('update_product_angles_sends_sort_indexes_for_every_photo', () async {
    when(
      () => api.patch<void>(
        ApiEndpoints.productPhotoAngles('product-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.updateProductAngles('product-1', {
      0: 'front',
      1: 'back',
    });
    final body =
        verify(
              () => api.patch<void>(
                ApiEndpoints.productPhotoAngles('product-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;

    expect(body, {
      'angles': {'0': 'front', '1': 'back'},
    });
  });

  test('create_user_model_sends_exact_multipart_fields', () async {
    when(
      () => api.post<String>(
        ApiEndpoints.userModels,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok('model-1'));
    final draft = UserModelDraft(
      name: 'Model - 2026-07-22',
      gender: UserModelGender.unspecified,
      photos: [
        OnboardingUpload(bytes: Uint8List(2), fileName: 'model-1.jpg'),
        OnboardingUpload(bytes: Uint8List(2), fileName: 'model-2.jpg'),
      ],
    );

    final result = await dataSource.createUserModel(draft);
    final formData =
        verify(
              () => api.post<String>(
                ApiEndpoints.userModels,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;
    final fields = Map<String, String>.fromEntries(formData.fields);

    expect(result.valueOrNull, 'model-1');
    expect(fields, {
      'name': 'Model - 2026-07-22',
      'gender': 'unspecified',
      'height': '',
      'heightEstimated': 'true',
    });
    expect(formData.files.map((part) => part.key), ['photos', 'photos']);
  });

  test('fetch_user_models_parses_models_and_photo_urls', () async {
    when(
      () => api.get<List<OnboardingUserModelDto>>(
        ApiEndpoints.userModels,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<List<OnboardingUserModelDto>>;
      return Result.ok(
        decoder({
          'models': [
            {
              'id': 'model-1',
              'name': 'Custom model',
              'photos': [
                {'url': '/uploads/model-1.jpg'},
              ],
            },
          ],
        }),
      );
    });

    final result = await dataSource.fetchUserModels();
    final model = result.valueOrNull!.single.toEntity();

    expect(model.id, 'model-1');
    expect(model.name, 'Custom model');
    expect(
      model.imageUrl,
      'https://catalogmock-api-production.up.railway.app/uploads/model-1.jpg',
    );
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
        deviceFingerprint: 'fingerprint-1',
        deviceToken: 'dt_123',
        uaFamily: 'android',
        screenHash: 'screen-1',
        tzOffset: -300,
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
    expect(body['deviceFingerprint'], 'fingerprint-1');
    expect(body['deviceToken'], 'dt_123');
    expect(body['uaFamily'], 'android');
    expect(body['screenHash'], 'screen-1');
    expect(body['tzOffset'], -300);
    expect(body['settings'], {
      'useCase': 'pdp',
      'directorId': 'luxury-editorial',
      'background': 'ai_decide',
      'aspectRatio': '3:4',
    });
  });
}
