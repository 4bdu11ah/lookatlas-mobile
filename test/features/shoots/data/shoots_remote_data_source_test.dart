import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/shoots/data/data_sources/shoots_remote_data_source.dart';
import 'package:look_atlas/features/shoots/data/repositories/shoots_repository_impl.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

class _MockRemoteDataSource extends Mock implements ShootsRemoteDataSource {}

void main() {
  late _MockApiService api;
  late ShootsRemoteDataSource dataSource;

  setUp(() {
    api = _MockApiService();
    dataSource = ShootsRemoteDataSourceImpl(api: api);
  });

  test('get_jobs_sends_filters_and_decodes_paginated_jobs', () async {
    when(
      () => api.get<ShootPage>(
        ApiEndpoints.jobs,
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as JsonDecoder<ShootPage>;
      return Result.ok(
        decoder({
          'jobs': [
            {
              'id': 'job-1',
              'name': 'Summer bag',
              'status': 'processing',
              'renders': 2,
              'progressPercentage': 40,
              'productThumbnail': '/bag.jpg',
              'modelThumbnail': 'https://cdn.test/model.jpg',
            },
          ],
          'pagination': {
            'page': 2,
            'totalPages': 4,
            'total': 75,
          },
        }),
      );
    });

    final result = await dataSource.getJobs(
      status: 'processing',
      page: 2,
      limit: 20,
      search: 'bag',
    );

    final query =
        verify(
              () => api.get<ShootPage>(
                ApiEndpoints.jobs,
                queryParameters: captureAny(named: 'queryParameters'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(query, {
      'status': 'processing',
      'page': 2,
      'limit': 20,
      'search': 'bag',
    });
    expect(result.valueOrNull!.jobs.single.progress, 0.4);
    expect(result.valueOrNull!.page, 2);
    expect(result.valueOrNull!.total, 75);
  });

  test('get_job_decodes_nested_shots_images_and_approval', () async {
    when(
      () => api.get<ShootJob>(
        ApiEndpoints.job('job-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as JsonDecoder<ShootJob>;
      return Result.ok(
        decoder({
          'job': {
            'id': 'job-1',
            'name': 'Bag shoot',
            'status': 'completed',
            'product': {'id': 'product-1', 'name': 'Bag'},
            'model': {'id': 'model-1', 'name': 'Mila'},
            'shots': [
              {
                'index': 3,
                'title': 'Detail',
                'images': [
                  {
                    'id': 'image-1',
                    'url': '/render.jpg',
                    'approved': true,
                    'variationIndex': 2,
                  },
                ],
              },
            ],
          },
        }),
      );
    });

    final job = (await dataSource.getJob('job-1')).valueOrNull!;

    expect(job.productId, 'product-1');
    expect(job.modelName, 'Mila');
    expect(job.shots.single.index, 3);
    expect(job.shots.single.images.single.id, 'image-1');
    expect(job.shots.single.images.single.approved, isTrue);
  });

  test('set_image_approval_patches_documented_endpoint_and_body', () async {
    when(
      () => api.patch<void>(
        ApiEndpoints.jobImage('job-1', 'image-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.setImageApproval(
      'job-1',
      'image-1',
      approved: true,
    );

    verify(
      () => api.patch<void>(
        ApiEndpoints.jobImage('job-1', 'image-1'),
        data: {'approved': true},
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('request_video_posts_selected_tier_ratio_variation_and_image', () async {
    when(
      () => api.post<void>(
        ApiEndpoints.jobVideo('job-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.requestVideo(
      'job-1',
      const ShootVideoRequest(
        variationIndex: 2,
        aspectRatio: '16:9',
        videoTier: 'hd',
        startingImageId: 'image-4',
      ),
    );

    verify(
      () => api.post<void>(
        ApiEndpoints.jobVideo('job-1'),
        data: {
          'variationIndex': 2,
          'aspectRatio': '16:9',
          'videoTier': 'hd',
          'startingImageId': 'image-4',
        },
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('plan_shots_posts_complete_v2_contract_and_decodes_shots', () async {
    when(
      () => api.post<List<PlannedShootShot>>(
        ApiEndpoints.planShots,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<List<PlannedShootShot>>;
      return Result.ok(
        decoder({
          'shots': [
            {
              'title': 'Hero',
              'shortDescription': 'Front-facing hero image',
            },
          ],
        }),
      );
    });
    const selection = ShootSelection(
      products: [
        ShootCatalogItem(id: 'product-1', name: 'Bag', imageUrl: ''),
        ShootCatalogItem(id: 'product-2', name: 'Shoes', imageUrl: ''),
      ],
      models: [
        ShootCatalogItem(
          id: 'model-1',
          name: 'Mila',
          imageUrl: '',
          source: 'user',
        ),
        ShootCatalogItem(
          id: 'model-2',
          name: 'Ava',
          imageUrl: '',
          source: 'lookatlas',
        ),
      ],
      productMode: ProductMode.pairing,
      settings: ShootSettings(
        directorFeedback: 'Natural light',
        numberOfShots: 6,
      ),
    );

    final result = await dataSource.planShots(selection);

    final body =
        verify(
              () => api.post<List<PlannedShootShot>>(
                ApiEndpoints.planShots,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(body['productId'], 'product-1');
    expect(body['modelId'], 'model-1');
    expect(body['modelSource'], 'user');
    expect(body['productMode'], 'pairing');
    expect(body['products'], [
      {'productId': 'product-1'},
      {'productId': 'product-2'},
    ]);
    expect(body['models'], [
      {'modelId': 'model-1', 'source': 'user', 'role': 'primary'},
      {'modelId': 'model-2', 'source': 'lookatlas', 'role': 'secondary-1'},
    ]);
    expect(body['directorId'], 'clean-pro');
    expect(body['directorFeedback'], 'Natural light');
    expect(body['numberOfShots'], 6);
    expect(result.valueOrNull!.single.title, 'Hero');
  });

  test('create_shoot_posts_selected_shots_and_returns_job_id', () async {
    when(
      () => api.post<String>(
        ApiEndpoints.createShoot,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as JsonDecoder<String>;
      return Result.ok(
        decoder({
          'job': {'id': 'job-created'},
        }),
      );
    });
    const request = CreateShootRequest(
      selection: ShootSelection(
        products: [
          ShootCatalogItem(id: 'product-1', name: 'Bag', imageUrl: ''),
        ],
        models: [
          ShootCatalogItem(id: 'model-1', name: 'Mila', imageUrl: ''),
        ],
        settings: ShootSettings(variations: 2, lane: ShootLane.relax),
      ),
      shots: [
        PlannedShootShot(title: 'Hero', description: 'Front view'),
      ],
    );

    final result = await dataSource.createShoot(request);

    final body =
        verify(
              () => api.post<String>(
                ApiEndpoints.createShoot,
                data: captureAny(named: 'data'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(body['variations'], 2);
    expect(body['shots'], [
      {'title': 'Hero', 'shortDescription': 'Front view'},
    ]);
    expect((body['settings'] as Map<String, dynamic>)['lane'], 'relax');
    expect(result.valueOrNull, 'job-created');
  });

  test('rerun_and_cancel_use_documented_job_action_endpoints', () async {
    when(
      () => api.post<void>(
        ApiEndpoints.rerunJob('job-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.delete<void>(
        ApiEndpoints.job('job-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.rerunJob('job-1');
    await dataSource.cancelJob('job-1');

    verify(
      () => api.post<void>(
        ApiEndpoints.rerunJob('job-1'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.delete<void>(
        ApiEndpoints.job('job-1'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('image_edit_posts_prompt_and_decodes_poll_status', () async {
    when(
      () => api.post<void>(
        ApiEndpoints.editJobImage('job-1', 'image-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.get<ShootImageEditState>(
        ApiEndpoints.jobImageEditStatus('job-1', 'image-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<ShootImageEditState>;
      return Result.ok(decoder({'status': 'completed'}));
    });

    await dataSource.editImage('job-1', 'image-1', 'Remove shadow');
    final status = await dataSource.getImageEditStatus('job-1', 'image-1');

    verify(
      () => api.post<void>(
        ApiEndpoints.editJobImage('job-1', 'image-1'),
        data: {'prompt': 'Remove shadow'},
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    expect(status.valueOrNull, ShootImageEditState.completed);
  });

  test('variation_and_hand_redo_post_documented_job_endpoints', () async {
    when(
      () => api.post<void>(
        ApiEndpoints.addJobVariation('job-1', 2),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.post<void>(
        ApiEndpoints.redoJobHandShots('job-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.addVariation('job-1', 2, 'Warmer light');
    await dataSource.redoHandShots('job-1');

    verify(
      () => api.post<void>(
        ApiEndpoints.addJobVariation('job-1', 2),
        data: {'remarks': 'Warmer light'},
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.post<void>(
        ApiEndpoints.redoJobHandShots('job-1'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('version_history_loads_and_sets_selected_version', () async {
    when(
      () => api.get<List<ShootImageVersion>>(
        ApiEndpoints.jobImageVersions('job-1', 'image-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as JsonDecoder<List<ShootImageVersion>>;
      return Result.ok(
        decoder({
          'versions': [
            {
              'id': 'version-1',
              'url': '/v1.jpg',
              'label': 'Original',
              'isActive': true,
            },
          ],
        }),
      );
    });
    when(
      () => api.post<void>(
        ApiEndpoints.setActiveJobImageVersion('job-1', 'image-1'),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    final versions = await dataSource.getImageVersions('job-1', 'image-1');
    await dataSource.setActiveImageVersion(
      'job-1',
      'image-1',
      'version-1',
    );

    expect(versions.valueOrNull!.single.isActive, isTrue);
    verify(
      () => api.post<void>(
        ApiEndpoints.setActiveJobImageVersion('job-1', 'image-1'),
        data: {'versionId': 'version-1'},
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('preset_save_and_delete_use_authenticated_preset_routes', () async {
    when(
      () => api.post<void>(
        ApiEndpoints.userPresets,
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    when(
      () => api.delete<void>(
        ApiEndpoints.userPreset('preset-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await dataSource.savePreset(
      name: 'PDP',
      settings: {'background': 'studio'},
      basedOnLookId: 'clean-pro',
      heroImageUrl: '/hero.jpg',
      isDefault: true,
    );
    await dataSource.deletePreset('preset-1');

    verify(
      () => api.post<void>(
        ApiEndpoints.userPresets,
        data: {
          'name': 'PDP',
          'settings': {'background': 'studio'},
          'basedOnLookId': 'clean-pro',
          'heroImageUrl': '/hero.jpg',
          'isDefault': true,
        },
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verify(
      () => api.delete<void>(
        ApiEndpoints.userPreset('preset-1'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('load_create_catalog_starts_all_requests_in_parallel', () async {
    final remote = _MockRemoteDataSource();
    final products = Completer<Result<List<ShootCatalogItem>>>();
    final userModels = Completer<Result<List<ShootCatalogItem>>>();
    final libraryModels = Completer<Result<List<ShootCatalogItem>>>();
    final credits = Completer<Result<int>>();
    final looks = Completer<Result<List<ShootLook>>>();
    final filters = Completer<Result<Map<String, List<String>>>>();
    final presets = Completer<Result<List<ShootPreset>>>();
    final appConfig = Completer<Result<ShootAppConfig>>();
    final subscription = Completer<Result<ShootSubscription>>();
    final calibratedIds = Completer<Result<Set<String>>>();
    when(remote.getProducts).thenAnswer((_) => products.future);
    when(remote.getUserModels).thenAnswer((_) => userModels.future);
    when(remote.getLibraryModels).thenAnswer((_) => libraryModels.future);
    when(remote.getAvailableCredits).thenAnswer((_) => credits.future);
    when(remote.getLooks).thenAnswer((_) => looks.future);
    when(remote.getLookFilters).thenAnswer((_) => filters.future);
    when(remote.getPresets).thenAnswer((_) => presets.future);
    when(remote.getAppConfig).thenAnswer((_) => appConfig.future);
    when(remote.getSubscription).thenAnswer((_) => subscription.future);
    when(
      remote.getCalibratedProductIds,
    ).thenAnswer((_) => calibratedIds.future);

    final future = ShootsRepositoryImpl(remote).loadCreateCatalog();

    verify(remote.getProducts).called(1);
    verify(remote.getUserModels).called(1);
    verify(remote.getLibraryModels).called(1);
    verify(remote.getAvailableCredits).called(1);
    verify(remote.getLooks).called(1);
    verify(remote.getLookFilters).called(1);
    verify(remote.getPresets).called(1);
    verify(remote.getAppConfig).called(1);
    verify(remote.getSubscription).called(1);
    verify(remote.getCalibratedProductIds).called(1);
    products.complete(const Result.ok([]));
    userModels.complete(const Result.ok([]));
    libraryModels.complete(const Result.ok([]));
    credits.complete(const Result.ok(20));
    looks.complete(const Result.ok([]));
    filters.complete(const Result.ok({}));
    presets.complete(const Result.ok([]));
    appConfig.complete(
      const Result.ok(ShootAppConfig(relaxEnabled: true)),
    );
    subscription.complete(
      const Result.ok(ShootSubscription(plan: 'pro', status: 'active')),
    );
    calibratedIds.complete(const Result.ok({}));

    final result = await future;

    expect(result.valueOrNull!.availableCredits, 20);
    expect(result.valueOrNull!.isUnlimitedEligible, isTrue);
  });
}
