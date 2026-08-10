import 'dart:typed_data';

import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/shoots/data/data_sources/shoots_remote_data_source.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';
import 'package:look_atlas/features/shoots/domain/repositories/shoots_repository.dart';

class ShootsRepositoryImpl implements ShootsRepository {
  const ShootsRepositoryImpl(this._remote);

  final ShootsRemoteDataSource _remote;

  @override
  Future<Result<ShootCreateCatalog>> loadCreateCatalog() async {
    final calibratedProductIds = _remote.getCalibratedProductIds();
    final results = await (
      _remote.getProducts(),
      _remote.getUserModels(),
      _remote.getLibraryModels(),
      _remote.getAvailableCredits(),
      _remote.getLooks(),
      _remote.getLookFilters(),
      _remote.getPresets(),
      _remote.getAppConfig(),
      _remote.getSubscription(),
    ).wait;
    final calibratedResult = await calibratedProductIds;
    final productsFailure = results.$1.failureOrNull;
    if (productsFailure != null) return Err(productsFailure);
    if (results.$2.isErr && results.$3.isErr) {
      return Err(results.$2.failureOrNull!);
    }
    final appConfig = results.$8.valueOrNull ?? const ShootAppConfig();
    final subscription = results.$9.valueOrNull ?? const ShootSubscription();
    final calibratedIds = calibratedResult.valueOrNull ?? const <String>{};
    return Ok(
      ShootCreateCatalog(
        products: [
          for (final product in results.$1.valueOrNull!)
            product.copyWith(isCalibrated: calibratedIds.contains(product.id)),
        ],
        userModels: results.$2.valueOrNull ?? const [],
        libraryModels: results.$3.valueOrNull ?? const [],
        availableCredits: results.$4.valueOrNull ?? 0,
        looks: _mergeDirectors(results.$5.valueOrNull ?? const []),
        lookFilters: results.$6.valueOrNull ?? const {},
        presets: results.$7.valueOrNull ?? const [],
        supportedAspectRatios: appConfig.supportedAspectRatios,
        defaultAspectRatio: appConfig.defaultAspectRatio,
        relaxEnabled: appConfig.relaxEnabled,
        plan: subscription.plan,
        isUnlimitedEligible: subscription.isUnlimitedEligible(
          relaxEnabled: appConfig.relaxEnabled,
        ),
      ),
    );
  }

  @override
  Future<Result<ShootPage>> getJobs({
    String status = '',
    int page = 1,
    int limit = 20,
    String search = '',
  }) => _remote.getJobs(
    status: status,
    page: page,
    limit: limit,
    search: search,
  );

  @override
  Future<Result<ShootJob>> getJob(String jobId) => _remote.getJob(jobId);

  @override
  Future<Result<ShootProgressStatus>> getJobStatus(String jobId) =>
      _remote.getJobStatus(jobId);

  @override
  Future<Result<void>> rerunJob(String jobId) => _remote.rerunJob(jobId);

  @override
  Future<Result<void>> cancelJob(String jobId) => _remote.cancelJob(jobId);

  @override
  Future<Result<void>> setImageApproval(
    String jobId,
    String imageId, {
    required bool approved,
  }) => _remote.setImageApproval(jobId, imageId, approved: approved);

  @override
  Future<Result<Uint8List>> downloadImage(String jobId, String imageId) =>
      _remote.downloadImage(jobId, imageId);

  @override
  Future<Result<void>> requestVideo(
    String jobId,
    ShootVideoRequest request,
  ) => _remote.requestVideo(jobId, request);

  @override
  Future<Result<void>> editImage(
    String jobId,
    String imageId,
    String prompt,
  ) => _remote.editImage(jobId, imageId, prompt);

  @override
  Future<Result<ShootImageEditState>> getImageEditStatus(
    String jobId,
    String imageId,
  ) => _remote.getImageEditStatus(jobId, imageId);

  @override
  Future<Result<void>> reportImage(
    String jobId,
    String imageId, {
    required String reason,
    required String comment,
  }) => _remote.reportImage(
    jobId,
    imageId,
    reason: reason,
    comment: comment,
  );

  @override
  Future<Result<void>> addVariation(
    String jobId,
    int shotIndex,
    String remarks,
  ) => _remote.addVariation(jobId, shotIndex, remarks);

  @override
  Future<Result<void>> redoHandShots(String jobId) =>
      _remote.redoHandShots(jobId);

  @override
  Future<Result<List<ShootImageVersion>>> getImageVersions(
    String jobId,
    String imageId,
  ) => _remote.getImageVersions(jobId, imageId);

  @override
  Future<Result<void>> setActiveImageVersion(
    String jobId,
    String imageId,
    String versionId,
  ) => _remote.setActiveImageVersion(jobId, imageId, versionId);

  @override
  Future<Result<List<PlannedShootShot>>> planShots(
    ShootSelection selection,
  ) => _remote.planShots(selection);

  @override
  Future<Result<PlannedShootShot>> createCustomShot(
    CustomShootShotRequest request,
  ) => _remote.createCustomShot(request);

  @override
  Future<Result<String>> createShoot(CreateShootRequest request) =>
      _remote.createShoot(request);

  @override
  Future<Result<void>> updateProductSubCategory(
    String productId,
    String subCategory,
  ) => _remote.updateProductSubCategory(productId, subCategory);

  @override
  Future<Result<void>> savePreset({
    required String name,
    required Map<String, dynamic> settings,
    String? basedOnLookId,
    String? heroImageUrl,
    bool isDefault = false,
  }) => _remote.savePreset(
    name: name,
    settings: settings,
    basedOnLookId: basedOnLookId,
    heroImageUrl: heroImageUrl,
    isDefault: isDefault,
  );

  @override
  Future<Result<void>> deletePreset(String presetId) =>
      _remote.deletePreset(presetId);
}

List<ShootLook> _mergeDirectors(List<ShootLook> remote) {
  final byId = {for (final director in remote) director.id: director};
  return [
    for (final director in defaultShootDirectors)
      byId.remove(director.id) ?? director,
    ...byId.values,
  ];
}
