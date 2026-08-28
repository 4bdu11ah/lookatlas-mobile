import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/house_model/data/data_sources/house_models_remote_data_source.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late HouseModelsRemoteDataSource dataSource;

  setUp(() {
    api = _MockApiService();
    dataSource = HouseModelsRemoteDataSourceImpl(api: api);
  });

  test('get_user_models_decodes_photo_records_with_urls_and_ids', () async {
    when(
      () => api.get<List<HouseModelProfile>>(
        ApiEndpoints.userModels,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<List<HouseModelProfile>>;
      return Result.ok(
        decoder({
          'data': {
            'models': [
              {
                'id': 'model-1',
                'name': 'Taylor',
                'gender': 'female',
                'height': '174 cm',
                'heightEstimated': true,
                'photoRecords': [
                  {'id': 'photo-front', 'url': '/uploads/front.jpg'},
                  {'id': 'photo-back', 'url': 'https://cdn.example/back.jpg'},
                ],
              },
            ],
          },
        }),
      );
    });

    final model = (await dataSource.getUserModels()).valueOrNull!.single;

    expect(model.id, 'model-1');
    expect(model.heightCm, 174);
    expect(model.heightEstimated, isTrue);
    expect(model.source, HouseModelSource.user);
    expect(
      model.photos.first,
      'https://catalogmock-api-production.up.railway.app/uploads/front.jpg',
    );
    expect(model.photos.last, 'https://cdn.example/back.jpg');
    expect(model.photoIds, ['photo-front', 'photo-back']);
  });

  test('get_library_models_marks_models_as_lookatlas_source', () async {
    when(
      () => api.get<List<HouseModelProfile>>(
        ApiEndpoints.lookAtlasModels,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<List<HouseModelProfile>>;
      return Result.ok(
        decoder([
          {
            '_id': 'library-1',
            'name': 'Sofia',
            'height': "5'9",
            'thumbnail': '/sofia.jpg',
          },
        ]),
      );
    });

    final model = (await dataSource.getLibraryModels()).valueOrNull!.single;

    expect(model.id, 'library-1');
    expect(model.source, HouseModelSource.lookAtlas);
    expect(model.heightCm, 175);
    expect(model.imageUrl, contains('/sofia.jpg'));
  });

  test('create_model_posts_repeated_photo_parts_and_profile_fields', () async {
    when(
      () => api.post<void>(
        ApiEndpoints.userModels,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    final draft = _draft(photoCount: 2);

    await dataSource.createModel(draft);
    final formData =
        verify(
              () => api.post<void>(
                ApiEndpoints.userModels,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;

    expect(Map<String, String>.fromEntries(formData.fields), {
      'name': 'Taylor',
      'gender': 'female',
      'height': '174',
      'heightEstimated': 'false',
    });
    expect(formData.files.map((part) => part.key), ['photos', 'photos']);
    expect(
      formData.files.map((part) => part.value.contentType.toString()),
      ['image/jpeg', 'image/png'],
    );
  });

  test('update_model_puts_multipart_data_to_model_endpoint', () async {
    when(
      () => api.put<void>(
        ApiEndpoints.userModel('model-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.updateModel('model-1', _draft(photoCount: 1));

    final formData =
        verify(
              () => api.put<void>(
                ApiEndpoints.userModel('model-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;
    expect(formData.files.single.key, 'photos');
  });

  test('patch_model_sends_metadata_without_multipart_data', () async {
    when(
      () => api.patch<void>(
        ApiEndpoints.userModel('model-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.patchModel('model-1', _draft());

    final body =
        verify(
              () => api.patch<void>(
                ApiEndpoints.userModel('model-1'),
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(body, {
      'name': 'Taylor',
      'gender': 'female',
      'height': '174cm',
      'heightEstimated': false,
    });
  });

  test('delete_model_uses_model_endpoint', () async {
    when(
      () => api.delete<void>(
        ApiEndpoints.userModel('model-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.deleteModel('model-1');

    verify(
      () => api.delete<void>(
        ApiEndpoints.userModel('model-1'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('delete_photo_uses_photo_id_endpoint', () async {
    when(
      () => api.delete<void>(
        ApiEndpoints.userModelPhoto('model-1', 'photo-2'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.deletePhoto('model-1', 'photo-2');

    verify(
      () => api.delete<void>(
        ApiEndpoints.userModelPhoto('model-1', 'photo-2'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('generate_model_posts_prompt_and_decodes_generation', () async {
    when(
      () => api.post<HouseModelGeneration>(
        ApiEndpoints.generateModel,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<HouseModelGeneration>;
      return Result.ok(
        decoder({
          'generation': {
            'generationId': 'generation-1',
            'status': 'processing',
            'creditCost': 20,
          },
        }),
      );
    });
    const draft = AiHouseModelDraft(
      gender: 'female',
      age: 25,
      description: 'Silver hair editorial model',
    );

    final generation = (await dataSource.generateModel(draft)).valueOrNull!;
    final body =
        verify(
              () => api.post<HouseModelGeneration>(
                ApiEndpoints.generateModel,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;

    expect(body, {
      'gender': 'female',
      'age': 25,
      'description': 'Silver hair editorial model',
    });
    expect(generation.id, 'generation-1');
    expect(generation.status, HouseModelGenerationStatus.processing);
    expect(generation.creditCost, 20);
  });

  test('get_generation_decodes_completed_status_and_model_id', () async {
    when(
      () => api.get<HouseModelGeneration>(
        ApiEndpoints.modelGeneration('generation-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<HouseModelGeneration>;
      return Result.ok(
        decoder({
          'id': 'generation-1',
          'status': 'completed',
          'modelId': 'model-2',
        }),
      );
    });

    final generation = (await dataSource.getGeneration(
      'generation-1',
    )).valueOrNull!;

    expect(generation.status, HouseModelGenerationStatus.completed);
    expect(generation.modelId, 'model-2');
  });
}

HouseModelDraft _draft({int photoCount = 0}) => HouseModelDraft(
  name: 'Taylor',
  gender: 'female',
  heightCm: 174,
  heightEstimated: false,
  photos: [
    for (var index = 0; index < photoCount; index++)
      HouseModelUpload(
        bytes: Uint8List(2),
        fileName: 'model-$index.${index == 1 ? 'png' : 'jpg'}',
      ),
  ],
);
