import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:look_atlas/features/products/domain/repositories/products_repository.dart';
import 'package:look_atlas/features/products/domain/use_cases/product_catalog_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  setUpAll(() => registerFallbackValue(const ProductQuery()));

  test('load_calibratedStatuses_populatesRepositoryQuery', () async {
    final repository = _MockProductsRepository();
    when(repository.getCalibrationStatuses).thenAnswer(
      (_) async => const Ok({'product-1': ProductCalibrationStatus.calibrated}),
    );
    when(() => repository.getProducts(any())).thenAnswer(
      (_) async => const Ok(
        ProductCatalogPage(
          products: [],
          page: 1,
          limit: 24,
          total: 0,
          totalPages: 1,
        ),
      ),
    );

    final useCases = ProductCatalogUseCases(repository);
    final context = await useCases.loadCalibrationContext();
    await useCases.load(
      const ProductQuery(search: 'coat'),
      context.calibratedIds,
    );

    final query =
        verify(() => repository.getProducts(captureAny())).captured.single
            as ProductQuery;
    expect(query.search, 'coat');
    expect(query.calibratedIds, {'product-1'});
  });

  test('resolve_existingProduct_combinesProductAndCalibration', () async {
    final repository = _MockProductsRepository();
    const product = ProductCatalogItem(
      id: 'product-1',
      name: 'Coat',
      sku: 'COAT',
      category: 'Outerwear',
    );
    when(() => repository.getProducts(any())).thenAnswer(
      (_) async => const Ok(
        ProductCatalogPage(
          products: [product],
          page: 1,
          limit: 1,
          total: 1,
          totalPages: 1,
        ),
      ),
    );
    when(repository.getCalibrationStatuses).thenAnswer(
      (_) async => const Ok({'product-1': ProductCalibrationStatus.calibrated}),
    );

    final resolved = await ProductCatalogUseCases(repository)
        .resolve('product-1');

    expect(resolved?.product, same(product));
    expect(
      resolved?.statuses['product-1'],
      ProductCalibrationStatus.calibrated,
    );
  });

  test('create_success_resolvesCanonicalProduct', () async {
    final repository = _MockProductsRepository();
    const draft = CatalogProductDraft(
      name: 'Coat',
      sku: 'COAT',
      category: 'Outerwear',
    );
    const product = ProductCatalogItem(
      id: 'product-1',
      name: 'Coat',
      sku: 'COAT',
      category: 'Outerwear',
    );
    when(() => repository.createProduct(draft)).thenAnswer(
      (_) async => const Ok('product-1'),
    );
    when(repository.getCalibrationStatuses).thenAnswer(
      (_) async => const Ok(<String, ProductCalibrationStatus>{}),
    );
    when(() => repository.getProducts(any())).thenAnswer(
      (_) async => const Ok(
        ProductCatalogPage(
          products: [product],
          page: 1,
          limit: 1,
          total: 1,
          totalPages: 1,
        ),
      ),
    );

    final result = await ProductCatalogUseCases(repository).create(draft);

    expect(result.valueOrNull?.product, same(product));
    verifyInOrder([
      () => repository.createProduct(draft),
      repository.getCalibrationStatuses,
      () => repository.getProducts(any()),
    ]);
  });
}
