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
  Future<Result<void>> createProduct(CatalogProductDraft draft) =>
      _remote.createProduct(draft);

  @override
  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  ) => _remote.updateProduct(productId, draft);

  @override
  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<int, String?> angles,
  ) => _remote.updatePhotoAngles(productId, angles);

  @override
  Future<Result<void>> deleteProduct(String productId) =>
      _remote.deleteProduct(productId);

  @override
  Future<Result<void>> deletePhoto(String productId, int photoIndex) =>
      _remote.deletePhoto(productId, photoIndex);

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
    if (outlines case Err(:final failure)) return Err(failure);
    if (calibration case Err(:final failure)) {
      if (failure is NetworkFailure && failure.statusCode == 404) {
        calibration = const Ok(ProductCalibration());
      } else {
        return Err(failure);
      }
    }
    if (calibrated case Err(:final failure)) return Err(failure);
    return Ok(
      ProductCalibrationWorkspace(
        outlines: outlines.valueOrNull!,
        calibration: calibration.valueOrNull!,
        calibratedProducts: calibrated.valueOrNull!,
      ),
    );
  }

  @override
  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo,
  ) => _remote.uploadWornPhoto(productId, photo);

  @override
  Future<Result<void>> uploadCutout(
    String productId,
    ProductUpload photo,
  ) => _remote.uploadCutout(productId, photo);

  @override
  Future<Result<void>> saveCalibration(
    String productId,
    ProductCalibrationDraft calibration,
  ) => _remote.saveCalibration(productId, calibration);

  @override
  Future<Result<void>> copyCalibration(
    String targetProductId,
    String sourceProductId,
  ) => _remote.copyCalibration(targetProductId, sourceProductId);
}
