import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';

abstract interface class ProductsRepository {
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query);

  Future<Result<String>> createProduct(CatalogProductDraft draft);

  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  );

  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<String, String?> angles,
  );

  Future<Result<void>> deleteProduct(String productId);

  Future<Result<void>> deletePhoto(String productId, String photoId);

  Future<Result<void>> replacePhoto(
    String productId,
    String photoId,
    ProductUpload photo,
  );

  Future<Result<Set<String>>> getCalibratedProductIds();

  Future<Result<Map<String, ProductCalibrationStatus>>>
  getCalibrationStatuses();

  Future<Result<ProductCalibrationWorkspace>> loadCalibration(
    String productId,
  );

  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo, {
    required String? calibrationId,
    required int? revision,
    required String mutationId,
    String? bodyArea,
  });

  Future<Result<void>> deleteWornPhoto(
    String productId,
    CalibrationMutationFence fence,
  );

  Future<Result<void>> uploadPlacement(
    String productId,
    ProductUpload cutout,
    Map<String, dynamic> placement,
    CalibrationMutationFence fence,
  );

  Future<Result<ProductUpload>> removeBackgroundFallback(
    String productId,
    ProductUpload photo,
  );

  Future<Result<CalibrationRender>> startCalibrationRender(
    String productId, {
    required String bodyPreset,
    required String mutationId,
    String? feedback,
    String? previousRenderId,
  });

  Future<Result<CalibrationRender?>> getLatestCalibrationRender(
    String productId,
  );

  Future<Result<List<CalibrationRender>>> getCalibrationRenders(
    String productId,
  );

  Future<Result<void>> approveCalibrationRender(
    String productId,
    String renderId,
    CalibrationMutationFence fence,
  );

  Future<Result<void>> promoteCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  );

  Future<Result<void>> discardCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  );

  Future<Result<void>> saveCalibration(
    String productId,
    ProductCalibrationDraft calibration,
  );

  Future<Result<void>> copyCalibration(
    String targetProductId,
    String sourceProductId,
    CalibrationMutationFence fence,
  );
}
