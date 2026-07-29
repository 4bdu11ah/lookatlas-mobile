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
    final results = await (
      _remote.getProducts(),
      _remote.getUserModels(),
      _remote.getLibraryModels(),
      _remote.getAvailableCredits(),
      _remote.getLooks(),
      _remote.getLookFilters(),
      _remote.getPresets(),
    ).wait;
    final productsFailure = results.$1.failureOrNull;
    if (productsFailure != null) return Err(productsFailure);
    if (results.$2.isErr && results.$3.isErr) {
      return Err(results.$2.failureOrNull!);
    }
    return Ok(
      ShootCreateCatalog(
        products: results.$1.valueOrNull!,
        userModels: results.$2.valueOrNull ?? const [],
        libraryModels: results.$3.valueOrNull ?? const [],
        availableCredits: results.$4.valueOrNull ?? 0,
        looks: results.$5.valueOrNull ?? const [],
        lookFilters: results.$6.valueOrNull ?? const {},
        presets: results.$7.valueOrNull ?? const [],
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
