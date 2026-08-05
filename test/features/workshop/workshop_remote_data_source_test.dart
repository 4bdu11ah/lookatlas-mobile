import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/workshop/data/data_sources/workshop_remote_data_source.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late _MockApiService publicApi;
  late WorkshopRemoteDataSource dataSource;

  setUp(() {
    api = _MockApiService();
    publicApi = _MockApiService();
    dataSource = WorkshopRemoteDataSourceImpl(
      api: api,
      publicApi: publicApi,
    );
  });

  test('initial_load_calls_active_and_history_and_decodes_results', () async {
    when(
      () => api.get<WorkshopGeneration?>(
        ApiEndpoints.workshopActive,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<WorkshopGeneration?>;
      return Result.ok(
        decoder({
          'activeGeneration': {
            'id': 'active-1',
            'status': 'processing',
            'prompt': 'Change the background',
          },
        }),
      );
    });
    when(
      () => api.get<List<WorkshopGeneration>>(
        ApiEndpoints.workshopGenerations,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<List<WorkshopGeneration>>;
      return Result.ok(
        decoder({
          'data': {
            'generations': [
              {
                'id': 'done-1',
                'status': 'completed',
                'imageUrl': '/workshop/result.jpg',
                'creditCost': 1,
              },
            ],
          },
        }),
      );
    });

    final active = (await dataSource.getActive()).valueOrNull;
    final history = (await dataSource.getGenerations()).valueOrNull!;

    expect(active?.id, 'active-1');
    expect(active?.isActive, isTrue);
    expect(history.single.status, WorkshopGenerationStatus.completed);
    expect(history.single.imageUrl, endsWith('/workshop/result.jpg'));
    verify(
      () => api.get<WorkshopGeneration?>(
        ApiEndpoints.workshopActive,
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.get<List<WorkshopGeneration>>(
        ApiEndpoints.workshopGenerations,
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('generate_sends_documented_multipart_fields', () async {
    when(
      () => api.post<WorkshopGeneration>(
        ApiEndpoints.workshopGenerate,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<WorkshopGeneration>;
      return Result.ok(
        decoder({'id': 'generation-1', 'status': 'queued', 'creditCost': 1}),
      );
    });
    final request = WorkshopGenerateRequest(
      base: WorkshopUpload(
        bytes: Uint8List.fromList([1, 2]),
        fileName: 'base.png',
      ),
      references: [
        WorkshopUpload(
          bytes: Uint8List.fromList([3]),
          fileName: 'face.jpg',
        ),
        WorkshopUpload(
          bytes: Uint8List.fromList([4]),
          fileName: 'style.webp',
        ),
      ],
      prompt: 'Use the face from reference one.',
      mode: WorkshopEditMode.lock,
    );

    final generation = (await dataSource.generate(request)).valueOrNull!;
    final form =
        verify(
              () => api.post<WorkshopGeneration>(
                ApiEndpoints.workshopGenerate,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as FormData;

    expect(Map<String, String>.fromEntries(form.fields), {
      'prompt': 'Use the face from reference one.',
      'mode': 'locked',
    });
    expect(form.files.map((entry) => entry.key), ['base', 'refs', 'refs']);
    expect(
      form.files.map((entry) => entry.value.contentType.toString()),
      ['image/png', 'image/jpeg', 'image/webp'],
    );
    expect(generation.id, 'generation-1');
    expect(generation.status, WorkshopGenerationStatus.queued);
  });

  test('detail_and_delete_use_generation_endpoint', () async {
    when(
      () => api.get<WorkshopGeneration>(
        ApiEndpoints.workshopGeneration('generation-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<WorkshopGeneration>;
      return Result.ok(
        decoder({
          'generation': {
            'id': 'generation-1',
            'status': 'completed',
            'outputUrl': 'https://cdn.example.com/result.jpg',
          },
        }),
      );
    });
    when(
      () => api.delete<void>(
        ApiEndpoints.workshopGeneration('generation-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    final generation = (await dataSource.getGeneration(
      'generation-1',
    )).valueOrNull!;
    await dataSource.deleteGeneration('generation-1');

    expect(generation.hasImage, isTrue);
    verify(
      () => api.delete<void>(
        ApiEndpoints.workshopGeneration('generation-1'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('generate_409_recovers_by_loading_active_job', () async {
    final options = RequestOptions(path: ApiEndpoints.workshopGenerate);
    final dioError = DioException(
      requestOptions: options,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 409,
        data: {'activeJobId': 'active-1'},
      ),
      type: DioExceptionType.badResponse,
    );
    when(
      () => api.post<WorkshopGeneration>(
        ApiEndpoints.workshopGenerate,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer(
      (_) async => Result.err(
        NetworkFailure(
          'Generation already active.',
          statusCode: 409,
          cause: dioError,
        ),
      ),
    );
    when(
      () => api.get<WorkshopGeneration>(
        ApiEndpoints.workshopGeneration('active-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<WorkshopGeneration>;
      return Result.ok(
        decoder({'id': 'active-1', 'status': 'processing'}),
      );
    });
    final request = WorkshopGenerateRequest(
      base: WorkshopUpload(
        bytes: Uint8List.fromList([1]),
        fileName: 'base.jpg',
      ),
      references: const [],
      prompt: 'Edit it.',
      mode: WorkshopEditMode.inspiration,
    );

    final generation = (await dataSource.generate(request)).valueOrNull!;

    expect(generation.id, 'active-1');
    expect(generation.status, WorkshopGenerationStatus.processing);
    verify(
      () => api.get<WorkshopGeneration>(
        ApiEndpoints.workshopGeneration('active-1'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });
}
