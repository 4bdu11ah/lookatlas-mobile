import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';

abstract interface class ProductsRepository {
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query);

  Future<Result<void>> createProduct(CatalogProductDraft draft);

  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  );

  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<int, String?> angles,
  );

  Future<Result<void>> deleteProduct(String productId);

  Future<Result<void>> deletePhoto(String productId, int photoIndex);

  Future<Result<void>> replacePhoto(
    String productId,
    String photoId,
    ProductUpload photo,
  );

  Future<Result<Set<String>>> getCalibratedProductIds();

  Future<Result<ProductCalibrationWorkspace>> loadCalibration(
    String productId,
  );

  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo,
  );

  Future<Result<void>> uploadCutout(
    String productId,
    ProductUpload photo,
  );

  Future<Result<void>> saveCalibration(
    String productId,
    ProductCalibrationDraft calibration,
  );

  Future<Result<void>> copyCalibration(
    String targetProductId,
    String sourceProductId,
  );
}
