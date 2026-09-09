import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:look_atlas/features/products/domain/repositories/products_repository.dart';
import 'package:look_atlas/features/products/domain/use_cases/product_catalog_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  test('load_calibratedStatuses_populatesRepositoryQuery', () async {
    final repository = _MockProductsRepository();
    when(repository.getCalibrationStatuses).thenAnswer(
      (_) async => const Ok({'product-1': ProductCalibrationStatus.calibrated}),
    );
    when(() => repository.getProducts(any())).thenAnswer(
      (_) async => const Ok(
        ProductCatalogPage(products: [], page: 1, limit: 24, total: 0, totalPages: 1),
      ),
    );

    await ProductCatalogUseCases(repository).load(const ProductQuery(search: 'coat'));

    final query = verify(() => repository.getProducts(captureAny())).captured.single
        as ProductQuery;
    expect(query.search, 'coat');
    expect(query.calibratedIds, {'product-1'});
  });
}
