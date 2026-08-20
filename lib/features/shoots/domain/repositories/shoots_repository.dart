import 'dart:typed_data';

import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';

abstract interface class ShootsRepository {
  Future<Result<ShootPage>> getJobs({
    String status = '',
    int page = 1,
    int limit = 20,
    String search = '',
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

  Future<Result<ShootCreateCatalog>> loadCreateCatalog();

  Future<Result<ShootCreateProducts>> loadCreateProducts();

  Future<Result<ShootCreateModels>> loadCreateModels();

  Future<Result<ShootCreateDirectorSetup>> loadCreateDirectorSetup();

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
    String? basedOnLookId,
    String? heroImageUrl,
    bool isDefault = false,
  });

  Future<Result<void>> deletePreset(String presetId);
}
