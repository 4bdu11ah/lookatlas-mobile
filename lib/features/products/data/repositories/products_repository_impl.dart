import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/data/data_sources/products_remote_data_source.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:look_atlas/features/products/domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl(this._remote);

  final ProductsRemoteDataSource _remote;

  @override
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query) =>
      _remote.getProducts(query);

  @override
  Future<Result<String>> createProduct(CatalogProductDraft draft) =>
      _remote.createProduct(draft);

  @override
  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  ) => _remote.updateProduct(productId, draft);

  @override
  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<String, String?> angles,
  ) => _remote.updatePhotoAngles(productId, angles);

  @override
  Future<Result<void>> deleteProduct(String productId) =>
      _remote.deleteProduct(productId);

  @override
  Future<Result<void>> deletePhoto(String productId, String photoId) =>
      _remote.deletePhoto(productId, photoId);

  @override
  Future<Result<void>> replacePhoto(
    String productId,
    String photoId,
    ProductUpload photo,
  ) => _remote.replacePhoto(productId, photoId, photo);

  @override
  Future<Result<Set<String>>> getCalibratedProductIds() async =>
      (await _remote.getCalibratedProducts()).map(
        (products) => {for (final product in products) product.id},
      );

  @override
  Future<Result<Map<String, ProductCalibrationStatus>>>
  getCalibrationStatuses() => _remote.getCalibrationStatuses();

  @override
  Future<Result<ProductCalibrationWorkspace>> loadCalibration(
    String productId,
  ) async {
    final results = await Future.wait([
      _remote.getCalibrationOutlines(),
      _remote.getCalibration(productId),
      _remote.getCalibratedProducts(),
    ]);
    final outlines = results[0] as Result<List<CalibrationOutline>>;
    var calibration = results[1] as Result<ProductCalibration>;
    final calibrated = results[2] as Result<List<ProductCatalogItem>>;
    final availableOutlines =
        outlines.valueOrNull ?? const <CalibrationOutline>[];
    if (calibration case Err(:final failure)) {
      if (failure is NetworkFailure && failure.statusCode == 404) {
        calibration = const Ok(ProductCalibration());
      } else {
        return Err(failure);
      }
    }
    return Ok(
      ProductCalibrationWorkspace(
        outlines: availableOutlines,
        calibration: calibration.valueOrNull!,
        calibratedProducts: calibrated.valueOrNull ?? const [],
      ),
    );
  }

  @override
  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo, {
    required String? calibrationId,
    required int? revision,
    required String mutationId,
    String? bodyArea,
  }) => _remote.uploadWornPhoto(
    productId,
    photo,
    calibrationId: calibrationId,
    revision: revision,
    mutationId: mutationId,
    bodyArea: bodyArea,
  );

  @override
  Future<Result<void>> deleteWornPhoto(
    String productId,
    CalibrationMutationFence fence,
  ) => _remote.deleteWornPhoto(productId, fence);

  @override
  Future<Result<void>> uploadPlacement(
    String productId,
    ProductUpload cutout,
    Map<String, dynamic> placement,
    CalibrationMutationFence fence,
  ) => _remote.uploadPlacement(productId, cutout, placement, fence);

  @override
  Future<Result<ProductUpload>> removeBackgroundFallback(
    String productId,
    ProductUpload photo,
  ) => _remote.removeBackgroundFallback(productId, photo);

  @override
  Future<Result<CalibrationRender>> startCalibrationRender(
    String productId, {
    required String bodyPreset,
    required String mutationId,
    String? feedback,
    String? previousRenderId,
  }) => _remote.startCalibrationRender(
    productId,
    bodyPreset: bodyPreset,
    feedback: feedback,
    previousRenderId: previousRenderId,
    mutationId: mutationId,
  );

  @override
  Future<Result<CalibrationRender?>> getLatestCalibrationRender(
    String productId,
  ) => _remote.getLatestCalibrationRender(productId);

  @override
  Future<Result<List<CalibrationRender>>> getCalibrationRenders(
    String productId,
  ) => _remote.getCalibrationRenders(productId);

  @override
  Future<Result<void>> approveCalibrationRender(
    String productId,
    String renderId,
    CalibrationMutationFence fence,
  ) => _remote.approveCalibrationRender(productId, renderId, fence);

  @override
  Future<Result<void>> promoteCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  ) => _remote.promoteCalibrationCandidate(productId, fence);

  @override
  Future<Result<void>> discardCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  ) => _remote.discardCalibrationCandidate(productId, fence);

  @override
  Future<Result<void>> saveCalibration(
    String productId,
    ProductCalibrationDraft calibration,
  ) => _remote.saveCalibration(productId, calibration);

  @override
  Future<Result<void>> copyCalibration(
    String targetProductId,
    String sourceProductId,
    CalibrationMutationFence fence,
  ) => _remote.copyCalibration(targetProductId, sourceProductId, fence);
}
