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
  Future<Result<ShootCreateProducts>> loadCreateProducts() async {
    final calibratedProductIds = _remote.getCalibratedProductIds();
    final productsResult = await _remote.getProducts();
    final calibratedResult = await calibratedProductIds;
    final productsFailure = productsResult.failureOrNull;
    if (productsFailure != null) return Err(productsFailure);
    final calibratedIds = calibratedResult.valueOrNull ?? const <String>{};
    return Ok(
      ShootCreateProducts([
        for (final product in productsResult.valueOrNull!)
          product.copyWith(isCalibrated: calibratedIds.contains(product.id)),
      ]),
    );
  }

  @override
  Future<Result<ShootCreateModels>> loadCreateModels() async {
    final results = await (
      _remote.getUserModels(),
      _remote.getLibraryModels(),
    ).wait;
    if (results.$1.isErr && results.$2.isErr) {
      return Err(results.$1.failureOrNull!);
    }
    return Ok(
      ShootCreateModels(
        userModels: results.$1.valueOrNull ?? const [],
        libraryModels: results.$2.valueOrNull ?? const [],
      ),
    );
  }

  @override
  Future<Result<ShootCreateDirectorSetup>> loadCreateDirectorSetup() async {
    final results = await (
      _remote.getAvailableCredits(),
      _remote.getLooks(),
      _remote.getLookFilters(),
      _remote.getPresets(),
      _remote.getAppConfig(),
      _remote.getSubscription(),
    ).wait;
    final appConfig = results.$5.valueOrNull ?? const ShootAppConfig();
    final subscription = results.$6.valueOrNull ?? const ShootSubscription();
    return Ok(
      ShootCreateDirectorSetup(
        availableCredits: results.$1.valueOrNull ?? 0,
        looks: _mergeDirectors(results.$2.valueOrNull ?? const []),
        lookFilters: results.$3.valueOrNull ?? const {},
        presets: results.$4.valueOrNull ?? const [],
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
  Future<Result<ShootCreateCatalog>> loadCreateCatalog() async {
    final results = await (
      loadCreateProducts(),
      loadCreateModels(),
      loadCreateDirectorSetup(),
    ).wait;
    if (results.$1 case Err(:final failure)) return Err(failure);
    if (results.$2 case Err(:final failure)) return Err(failure);
    if (results.$3 case Err(:final failure)) return Err(failure);
    final products = results.$1.valueOrNull!;
    final models = results.$2.valueOrNull!;
    final directorSetup = results.$3.valueOrNull!;
    return Ok(
      ShootCreateCatalog(
        products: products.products,
        userModels: models.userModels,
        libraryModels: models.libraryModels,
        looks: directorSetup.looks,
        lookFilters: directorSetup.lookFilters,
        presets: directorSetup.presets,
        availableCredits: directorSetup.availableCredits,
        supportedAspectRatios: directorSetup.supportedAspectRatios,
        defaultAspectRatio: directorSetup.defaultAspectRatio,
        relaxEnabled: directorSetup.relaxEnabled,
        plan: directorSetup.plan,
        isUnlimitedEligible: directorSetup.isUnlimitedEligible,
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
    // ...byId.values,
  ];
}
