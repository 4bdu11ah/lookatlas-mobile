import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/shoots/data/data_sources/shoots_remote_data_source.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late ShootsRemoteDataSource dataSource;

  setUp(() {
    api = _MockApiService();
    dataSource = ShootsRemoteDataSourceImpl(api: api);
  });

  test('create_catalog_methods_call_all_documented_initial_routes', () async {
    when(
      () => api.get<List<ShootCatalogItem>>(
        ApiEndpoints.products,
        queryParameters: const {'includePhotos': true},
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok([]));
    when(
      () => api.get<List<ShootCatalogItem>>(
        ApiEndpoints.userModels,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok([]));
    when(
      () => api.get<List<ShootCatalogItem>>(
        ApiEndpoints.lookAtlasModels,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok([]));
    when(
      () => api.get<int>(
        ApiEndpoints.dashboardStats,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(10));
    when(
      () => api.get<List<ShootLook>>(
        ApiEndpoints.looks,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok([]));
    when(
      () => api.get<Map<String, List<String>>>(
        ApiEndpoints.lookFilters,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok({}));
    when(
      () => api.get<List<ShootPreset>>(
        ApiEndpoints.userPresets,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok([]));

    await (
      dataSource.getProducts(),
      dataSource.getUserModels(),
      dataSource.getLibraryModels(),
      dataSource.getAvailableCredits(),
      dataSource.getLooks(),
      dataSource.getLookFilters(),
      dataSource.getPresets(),
    ).wait;

    verify(
      () => api.get<List<ShootCatalogItem>>(
        ApiEndpoints.products,
        queryParameters: const {'includePhotos': true},
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.get<List<ShootCatalogItem>>(
        ApiEndpoints.userModels,
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.get<List<ShootCatalogItem>>(
        ApiEndpoints.lookAtlasModels,
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.get<int>(
        ApiEndpoints.dashboardStats,
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.get<List<ShootLook>>(
        ApiEndpoints.looks,
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.get<Map<String, List<String>>>(
        ApiEndpoints.lookFilters,
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.get<List<ShootPreset>>(
        ApiEndpoints.userPresets,
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('custom_shot_posts_current_settings_and_existing_shots', () async {
    when(
      () => api.post<PlannedShootShot>(
        ApiEndpoints.customShot,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as JsonDecoder<PlannedShootShot>;
      return Result.ok(
        decoder({
          'shot': {
            'title': 'Macro detail',
            'shortDescription': 'Close product detail',
          },
        }),
      );
    });
    const selection = ShootSelection(
      product: ShootCatalogItem(
        id: 'product-1',
        name: 'Bag',
        imageUrl: '',
      ),
      model: ShootCatalogItem(
        id: 'model-1',
        name: 'Mila',
        imageUrl: '',
      ),
      settings: ShootSettings(
        useCase: 'campaign',
        directorId: 'editorial',
        background: 'street',
      ),
    );

    final result = await dataSource.createCustomShot(
      const CustomShootShotRequest(
        selection: selection,
        shotIdea: 'Macro detail',
        poseDirection: 'Hold product',
        focusArea: 'Stitching',
        existingShots: [
          PlannedShootShot(title: 'Hero', description: 'Front view'),
        ],
      ),
    );

    final body =
        verify(
              () => api.post<PlannedShootShot>(
                ApiEndpoints.customShot,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(body['shotIdea'], 'Macro detail');
    expect(body['useCase'], 'campaign');
    expect(body['directorId'], 'editorial');
    expect(body['background'], 'street');
    expect(body['existingShots'], [
      {'title': 'Hero', 'shortDescription': 'Front view'},
    ]);
    expect(result.valueOrNull!.title, 'Macro detail');
  });
}
