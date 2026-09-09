import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:look_atlas/features/products/domain/repositories/products_repository.dart';

typedef ProductCatalogLoad = ({
  Result<Map<String, ProductCalibrationStatus>> statuses,
  Set<String> calibratedIds,
});

typedef CreatedCatalogProduct = ({
  ProductCatalogItem product,
  Map<String, ProductCalibrationStatus> statuses,
});

class ProductCatalogUseCases {
  const ProductCatalogUseCases(this._repository);

  final ProductsRepository _repository;

  Future<ProductCatalogLoad> loadCalibrationContext() async {
    final statuses = await _repository.getCalibrationStatuses();
    final calibratedIds = {
      for (final entry in (statuses.valueOrNull ?? const {}).entries)
        if (entry.value.isCalibrated) entry.key,
    };
    return (statuses: statuses, calibratedIds: calibratedIds);
  }

  Future<Result<ProductCatalogPage>> load(
    ProductQuery query,
    Set<String> calibratedIds,
  ) {
    return _repository.getProducts(
      ProductQuery(
        page: query.page,
        limit: query.limit,
        search: query.search,
        category: query.category,
        sort: query.sort,
        calibration: query.calibration,
        calibratedIds: calibratedIds,
        productId: query.productId,
      ),
    );
  }

  Future<CreatedCatalogProduct?> resolve(String productId) async {
    final results = await Future.wait<Object>([
      _repository.getProducts(ProductQuery(productId: productId, limit: 1)),
      _repository.getCalibrationStatuses(),
    ]);
    final page = results[0] as Result<ProductCatalogPage>;
    final statuses =
        results[1] as Result<Map<String, ProductCalibrationStatus>>;
    final product = page.valueOrNull?.products
        .where((item) => item.id == productId)
        .firstOrNull;
    return product == null
        ? null
        : (product: product, statuses: statuses.valueOrNull ?? const {});
  }

  Future<Result<CreatedCatalogProduct?>> create(
    CatalogProductDraft draft,
  ) async {
    final created = await _repository.createProduct(draft);
    final failure = created.failureOrNull;
    if (failure != null) return Err(failure);
    final productId = created.valueOrNull!;
    final statuses = await _repository.getCalibrationStatuses();
    final page = await _repository.getProducts(
      ProductQuery(productId: productId, limit: 1),
    );
    final product = page.valueOrNull?.products.firstOrNull;
    return Ok(
      product == null
          ? null
          : (product: product, statuses: statuses.valueOrNull ?? const {}),
    );
  }
}
