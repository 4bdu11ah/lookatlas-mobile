import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/network/dio_client.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/shoots/data/models/shoots_api_codec.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';

abstract interface class ShootsRemoteDataSource {
  Future<Result<ShootPage>> getJobs({
    required String status,
    required int page,
    required int limit,
    required String search,
  });
  Future<Result<ShootJob>> getJob(String jobId);
  Future<Result<ShootProgressStatus>> getJobStatus(String jobId);
  Future<Result<void>> rerunJob(String jobId);
  Future<Result<void>> cancelJob(String jobId);
  Future<Result<void>> setImageApproval(
    String jobId,
    String imageId, {
    required bool approved,
  });
  Future<Result<Uint8List>> downloadImage(String jobId, String imageId);
  Future<Result<void>> requestVideo(
    String jobId,
    ShootVideoRequest request,
  );
  Future<Result<void>> editImage(
    String jobId,
    String imageId,
    String prompt,
  );
  Future<Result<ShootImageEditState>> getImageEditStatus(
    String jobId,
    String imageId,
  );
  Future<Result<void>> reportImage(
    String jobId,
    String imageId, {
    required String reason,
    required String comment,
  });
  Future<Result<void>> addVariation(
    String jobId,
    int shotIndex,
    String remarks,
  );
  Future<Result<void>> redoHandShots(String jobId);
  Future<Result<List<ShootImageVersion>>> getImageVersions(
    String jobId,
    String imageId,
  );
  Future<Result<void>> setActiveImageVersion(
    String jobId,
    String imageId,
    String versionId,
  );
  Future<Result<List<ShootCatalogItem>>> getProducts();
  Future<Result<List<ShootCatalogItem>>> getUserModels();
  Future<Result<List<ShootCatalogItem>>> getLibraryModels();
  Future<Result<int>> getAvailableCredits();
  Future<Result<ShootAppConfig>> getAppConfig();
  Future<Result<ShootSubscription>> getSubscription();
  Future<Result<Set<String>>> getCalibratedProductIds();
  Future<Result<List<ShootLook>>> getLooks();
  Future<Result<Map<String, List<String>>>> getLookFilters();
  Future<Result<List<ShootPreset>>> getPresets();
  Future<Result<List<PlannedShootShot>>> planShots(
    ShootSelection selection,
  );
  Future<Result<PlannedShootShot>> createCustomShot(
    CustomShootShotRequest request,
  );
  Future<Result<String>> createShoot(CreateShootRequest request);
  Future<Result<void>> updateProductSubCategory(
    String productId,
    String subCategory,
  );
  Future<Result<void>> savePreset({
    required String name,
    required Map<String, dynamic> settings,
    required bool isDefault,
    String? basedOnLookId,
    String? heroImageUrl,
  });
  Future<Result<void>> deletePreset(String presetId);
}

class ShootsRemoteDataSourceImpl implements ShootsRemoteDataSource {
  ShootsRemoteDataSourceImpl({
    required ApiService api,
    ApiService? publicApi,
  }) : _api = api,
       _publicApi = publicApi ?? api;

  final ApiService _api;
  final ApiService _publicApi;

  @override
  Future<Result<ShootPage>> getJobs({
    required String status,
    required int page,
    required int limit,
    required String search,
  }) => _api.get<ShootPage>(
    ApiEndpoints.jobs,
    queryParameters: {
      'status': status,
      'page': page,
      'limit': limit,
      'search': search,
    },
    decoder: ShootsApiCodec.decodeJobPage,
  );

  @override
  Future<Result<ShootJob>> getJob(String jobId) => _api.get<ShootJob>(
    ApiEndpoints.job(jobId),
    decoder: ShootsApiCodec.decodeJobResponse,
  );

  @override
  Future<Result<ShootProgressStatus>> getJobStatus(String jobId) =>
      _api.get<ShootProgressStatus>(
        ApiEndpoints.jobStatus(jobId),
        decoder: ShootsApiCodec.decodeProgress,
      );

  @override
  Future<Result<void>> rerunJob(String jobId) => _api.post<void>(
    ApiEndpoints.rerunJob(jobId),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> cancelJob(String jobId) => _api.delete<void>(
    ApiEndpoints.job(jobId),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> setImageApproval(
    String jobId,
    String imageId, {
    required bool approved,
  }) => _api.patch<void>(
    ApiEndpoints.jobImage(jobId, imageId),
    data: {'approved': approved},
    decoder: (_) {},
  );

  @override
  Future<Result<Uint8List>> downloadImage(
    String jobId,
    String imageId,
  ) async {
    try {
      final response = await _api.raw.get<List<int>>(
        ApiEndpoints.downloadJobImage(jobId, imageId),
        options: Options(responseType: ResponseType.bytes),
      );
      return Ok(Uint8List.fromList(response.data ?? const []));
    } on DioException catch (error) {
      return Err(mapDioError(error));
    } on Object catch (error, stack) {
      return Err(
        UnknownFailure(
          'Could not download this image.',
          cause: error,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> requestVideo(
    String jobId,
    ShootVideoRequest request,
  ) => _api.post<void>(
    ApiEndpoints.jobVideo(jobId),
    data: ShootsApiCodec.videoPayload(request),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> editImage(
    String jobId,
    String imageId,
    String prompt,
  ) => _api.post<void>(
    ApiEndpoints.editJobImage(jobId, imageId),
    data: {'prompt': prompt},
    decoder: (_) {},
  );

  @override
  Future<Result<ShootImageEditState>> getImageEditStatus(
    String jobId,
    String imageId,
  ) => _api.get<ShootImageEditState>(
    ApiEndpoints.jobImageEditStatus(jobId, imageId),
    decoder: ShootsApiCodec.decodeEditStatus,
  );

  @override
  Future<Result<void>> reportImage(
    String jobId,
    String imageId, {
    required String reason,
    required String comment,
  }) => _api.post<void>(
    ApiEndpoints.reportJobImage(jobId, imageId),
    data: {'reason': reason, 'comment': comment},
    decoder: (_) {},
  );

  @override
  Future<Result<void>> addVariation(
    String jobId,
    int shotIndex,
    String remarks,
  ) => _api.post<void>(
    ApiEndpoints.addJobVariation(jobId, shotIndex),
    data: {if (remarks.trim().isNotEmpty) 'remarks': remarks.trim()},
    decoder: (_) {},
  );

  @override
  Future<Result<void>> redoHandShots(String jobId) => _api.post<void>(
    ApiEndpoints.redoJobHandShots(jobId),
    decoder: (_) {},
  );

  @override
  Future<Result<List<ShootImageVersion>>> getImageVersions(
    String jobId,
    String imageId,
  ) => _api.get<List<ShootImageVersion>>(
    ApiEndpoints.jobImageVersions(jobId, imageId),
    decoder: ShootsApiCodec.decodeVersions,
  );

  @override
  Future<Result<void>> setActiveImageVersion(
    String jobId,
    String imageId,
    String versionId,
  ) => _api.post<void>(
    ApiEndpoints.setActiveJobImageVersion(jobId, imageId),
    data: {'versionId': versionId},
    decoder: (_) {},
  );

  @override
  Future<Result<List<ShootCatalogItem>>> getProducts() =>
      _api.get<List<ShootCatalogItem>>(
        ApiEndpoints.products,
        queryParameters: const {'includePhotos': true},
        decoder: (data) => ShootsApiCodec.decodeCatalogItems(data, 'products'),
      );

  @override
  Future<Result<List<ShootCatalogItem>>> getUserModels() =>
      _api.get<List<ShootCatalogItem>>(
        ApiEndpoints.userModels,
        decoder: (data) => ShootsApiCodec.decodeCatalogItems(
          data,
          'models',
          source: 'user',
        ),
      );

  @override
  Future<Result<List<ShootCatalogItem>>> getLibraryModels() =>
      _api.get<List<ShootCatalogItem>>(
        ApiEndpoints.lookAtlasModels,
        decoder: (data) => ShootsApiCodec.decodeCatalogItems(
          data,
          'models',
          source: 'lookatlas',
        ),
      );

  @override
  Future<Result<int>> getAvailableCredits() => _api.get<int>(
    ApiEndpoints.dashboardStats,
    decoder: ShootsApiCodec.decodeAvailableCredits,
  );

  @override
  Future<Result<ShootAppConfig>> getAppConfig() =>
      _publicApi.get<ShootAppConfig>(
        ApiEndpoints.appConfig,
        decoder: ShootsApiCodec.decodeAppConfig,
      );

  @override
  Future<Result<ShootSubscription>> getSubscription() =>
      _api.get<ShootSubscription>(
        ApiEndpoints.billingSubscription,
        decoder: ShootsApiCodec.decodeSubscription,
      );

  @override
  Future<Result<Set<String>>> getCalibratedProductIds() =>
      _api.get<Set<String>>(
        ApiEndpoints.calibratedProducts,
        decoder: ShootsApiCodec.decodeCalibratedProductIds,
      );

  @override
  Future<Result<List<ShootLook>>> getLooks() => _api.get<List<ShootLook>>(
    ApiEndpoints.looks,
    decoder: ShootsApiCodec.decodeLooks,
  );

  @override
  Future<Result<Map<String, List<String>>>> getLookFilters() =>
      _api.get<Map<String, List<String>>>(
        ApiEndpoints.lookFilters,
        decoder: ShootsApiCodec.decodeFilters,
      );

  @override
  Future<Result<List<ShootPreset>>> getPresets() => _api.get<List<ShootPreset>>(
    ApiEndpoints.userPresets,
    decoder: ShootsApiCodec.decodePresets,
  );

  @override
  Future<Result<List<PlannedShootShot>>> planShots(
    ShootSelection selection,
  ) => _api.post<List<PlannedShootShot>>(
    ApiEndpoints.planShots,
    data: ShootsApiCodec.planPayload(selection),
    options: Options(receiveTimeout: const Duration(minutes: 2)),
    decoder: ShootsApiCodec.decodePlannedShots,
  );

  @override
  Future<Result<PlannedShootShot>> createCustomShot(
    CustomShootShotRequest request,
  ) => _api.post<PlannedShootShot>(
    ApiEndpoints.customShot,
    data: ShootsApiCodec.customShotPayload(request),
    decoder: ShootsApiCodec.decodeCustomShot,
  );

  @override
  Future<Result<String>> createShoot(CreateShootRequest request) =>
      _api.post<String>(
        ApiEndpoints.createShoot,
        data: ShootsApiCodec.createPayload(request),
        decoder: ShootsApiCodec.decodeCreatedJobId,
      );

  @override
  Future<Result<void>> updateProductSubCategory(
    String productId,
    String subCategory,
  ) => _api.put<void>(
    ApiEndpoints.product(productId),
    data: FormData.fromMap({'sub_category': subCategory}),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> savePreset({
    required String name,
    required Map<String, dynamic> settings,
    required bool isDefault,
    String? basedOnLookId,
    String? heroImageUrl,
  }) {
    final data = <String, dynamic>{
      'name': name,
      'settings': settings,
      'isDefault': isDefault,
    };
    if (basedOnLookId != null) data['basedOnLookId'] = basedOnLookId;
    if (heroImageUrl != null) data['heroImageUrl'] = heroImageUrl;
    return _api.post<void>(
      ApiEndpoints.userPresets,
      data: data,
      decoder: (_) {},
    );
  }

  @override
  Future<Result<void>> deletePreset(String presetId) => _api.delete<void>(
    ApiEndpoints.userPreset(presetId),
    decoder: (_) {},
  );
}
