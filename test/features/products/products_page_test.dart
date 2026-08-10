import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/products/di/products_providers.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:look_atlas/features/products/domain/repositories/products_repository.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';

import '../../helpers/fake_repositories.dart';

class _FakeProductsRepository implements ProductsRepository {
  final List<ProductCatalogItem> products = [
    ProductCatalogItem(
      id: 'product-1',
      name: 'Classic Cotton T-Shirt',
      sku: 'TSH-001',
      category: 'Tops',
      createdAt: DateTime(2026, 7, 12),
      photos: const [
        ProductPhoto(
          id: 'photo-1',
          url: 'assets/images/onboarding/angles/tops-front.png',
          sortOrder: 0,
          viewAngle: 'front',
        ),
        ProductPhoto(
          id: 'photo-2',
          url: 'assets/images/onboarding/angles/tops-back.png',
          sortOrder: 1,
          viewAngle: 'back',
        ),
      ],
    ),
    ProductCatalogItem(
      id: 'product-2',
      name: 'Canvas Crossbody Bag',
      sku: 'BAG-012',
      category: 'Bags',
      subCategory: 'Crossbody',
      createdAt: DateTime(2026, 7, 8),
      photos: const [
        ProductPhoto(
          id: 'photo-3',
          url: 'assets/images/onboarding/angles/bags-front.png',
          sortOrder: 0,
          viewAngle: 'front',
        ),
      ],
    ),
    ProductCatalogItem(
      id: 'product-3',
      name: 'Pendant Necklace',
      sku: 'JWL-018',
      category: 'Jewelry',
      createdAt: DateTime(2026, 7, 4),
      photos: const [
        ProductPhoto(
          id: 'photo-4',
          url: 'assets/images/onboarding/angles/jewelry-closeup1.png',
          sortOrder: 0,
        ),
      ],
    ),
  ];

  int deleteCalls = 0;
  int updateCalls = 0;

  @override
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query) async {
    final search = query.search.toLowerCase();
    final filtered = products.where((product) {
      final matchesSearch =
          search.isEmpty ||
          '${product.name} ${product.sku} ${product.description ?? ''}'
              .toLowerCase()
              .contains(search);
      final matchesCategory =
          query.category.isEmpty || product.category == query.category;
      final calibrated = product.id == 'product-2';
      final matchesCalibration =
          query.calibration.isEmpty ||
          (query.calibration == 'calibrated' && calibrated) ||
          (query.calibration == 'uncalibrated' && !calibrated);
      return matchesSearch && matchesCategory && matchesCalibration;
    }).toList();
    switch (query.sort) {
      case 'oldest':
        filtered.sort(
          (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          ),
        );
      case 'name_asc':
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case 'name_desc':
        filtered.sort((a, b) => b.name.compareTo(a.name));
    }
    return Result.ok(
      ProductCatalogPage(
        products: filtered,
        page: 1,
        limit: 20,
        total: filtered.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<Result<Set<String>>> getCalibratedProductIds() async =>
      const Result.ok({'product-2'});

  @override
  Future<Result<void>> createProduct(CatalogProductDraft draft) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  ) async {
    updateCalls++;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<int, String?> angles,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> deleteProduct(String productId) async {
    deleteCalls++;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deletePhoto(String productId, int photoIndex) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> replacePhoto(
    String productId,
    String photoId,
    ProductUpload photo,
  ) async => const Result.ok(null);

  @override
  Future<Result<ProductCalibrationWorkspace>> loadCalibration(
    String productId,
  ) async => Result.ok(
    ProductCalibrationWorkspace(
      outlines: const [
        CalibrationOutline(id: 'hand_side', name: 'Hand Side'),
        CalibrationOutline(
          id: 'full_body_front',
          name: 'Full Body Front',
        ),
      ],
      calibration: const ProductCalibration(),
      calibratedProducts: [products[1]],
    ),
  );

  @override
  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> uploadCutout(
    String productId,
    ProductUpload photo,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> saveCalibration(
    String productId,
    ProductCalibrationDraft calibration,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> copyCalibration(
    String targetProductId,
    String sourceProductId,
  ) async => const Result.ok(null);
}

class _PagedProductsRepository extends _FakeProductsRepository {
  @override
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query) async {
    final pageProducts = query.page == 1
        ? products.take(2).toList()
        : products.skip(2).toList();
    return Result.ok(
      ProductCatalogPage(
        products: pageProducts,
        page: query.page,
        limit: 2,
        total: products.length,
        totalPages: 2,
      ),
    );
  }
}

class _LoadingProductsRepository extends _FakeProductsRepository {
  final calibration = Completer<Result<Set<String>>>();

  @override
  Future<Result<Set<String>>> getCalibratedProductIds() => calibration.future;
}

void main() {
  late _FakeProductsRepository productsRepository;

  setUp(() => productsRepository = _FakeProductsRepository());

  Future<void> pumpProducts(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(id: 'user-1', email: 'jane@example.com'),
            ),
          ),
          productsRepositoryProvider.overrideWithValue(productsRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectProductFilter(
    WidgetTester tester,
    Key filterKey,
    String value,
  ) async {
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-product-filter-sheet')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('open-product-filter-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(filterKey));
    await tester.pump();
    final option = find.text(value).last;
    if (option.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        option,
        120,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.tap(option);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show products'));
    await tester.pumpAndSettle();
  }

  Future<void> ensureProductVisible(
    WidgetTester tester,
    String productName,
  ) async {
    await tester.scrollUntilVisible(
      find.text(productName),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(productName), findsOneWidget);
  }

  testWidgets('product page renders catalog chrome and app bar', (
    tester,
  ) async {
    await pumpProducts(tester);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Products'), findsWidgets);
    expect(find.text('Classic Cotton T-Shirt'), findsOneWidget);
    expect(find.text('Search by name, sku, or description'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('open-product-filter-sheet')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        '3 products - 1 calibrated',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Add Product'), findsOneWidget);
    await ensureProductVisible(tester, 'Canvas Crossbody Bag');
  });

  testWidgets('product page shows shimmer cards while the catalog loads', (
    tester,
  ) async {
    final loadingRepository = _LoadingProductsRepository();
    productsRepository = loadingRepository;
    await pumpProducts(tester);

    expect(
      find.byKey(const ValueKey('products-loading-shimmer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('product-loading-shimmer-card-0')),
      findsOneWidget,
    );

    loadingRepository.calibration.complete(const Result.ok({}));
  });

  testWidgets('product search filters by product fields through Riverpod', (
    tester,
  ) async {
    await pumpProducts(tester);

    final searchField = find.byKey(const ValueKey('product-search-field'));
    await tester.enterText(searchField, 'bag');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Canvas Crossbody Bag'), findsOneWidget);
    expect(find.text('Classic Cotton T-Shirt'), findsNothing);
    expect(
      find.textContaining(
        '1 products - 1 calibrated',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.enterText(searchField, 'JWL-018');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Pendant Necklace'), findsOneWidget);
    expect(find.text('Canvas Crossbody Bag'), findsNothing);
    expect(
      find.textContaining(
        '1 products - 0 calibrated',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('clear-product-search')));
    await tester.pumpAndSettle();

    expect(find.text('Classic Cotton T-Shirt'), findsOneWidget);
    await ensureProductVisible(tester, 'Canvas Crossbody Bag');
  });

  testWidgets('product filters update the list through Riverpod', (
    tester,
  ) async {
    await pumpProducts(tester);

    await selectProductFilter(
      tester,
      const ValueKey('product-category-filter'),
      'Tops',
    );

    expect(find.text('Classic Cotton T-Shirt'), findsOneWidget);
    expect(find.text('Canvas Crossbody Bag'), findsNothing);
    expect(
      find.textContaining(
        '1 products - 0 calibrated',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await selectProductFilter(
      tester,
      const ValueKey('product-status-filter'),
      'Calibrated',
    );

    expect(find.text('No products found'), findsOneWidget);
    expect(find.text('Try a different filter combination.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-product-filter-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    await selectProductFilter(
      tester,
      const ValueKey('product-sort-filter'),
      'Oldest first',
    );

    expect(find.text('Pendant Necklace'), findsOneWidget);
    await ensureProductVisible(tester, 'Canvas Crossbody Bag');
    await ensureProductVisible(tester, 'Classic Cotton T-Shirt');
  });

  testWidgets('product card changes photo by swipe', (tester) async {
    await pumpProducts(tester);

    expect(
      find.byKey(const ValueKey('product-TSH-001-photo-dot-0-active')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('product-TSH-001-photo-dot-1-active')),
      findsNothing,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('product-TSH-001-photo-pager')),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('product-TSH-001-photo-pager')),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('product-TSH-001-photo-dot-1-active')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('product-TSH-001-photo-pager')),
      const Offset(260, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('product-TSH-001-photo-dot-0-active')),
      findsOneWidget,
    );
  });

  testWidgets('product page loads the next API page', (tester) async {
    productsRepository = _PagedProductsRepository();
    await pumpProducts(tester);

    await tester.scrollUntilVisible(
      find.text('Load more'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    await ensureProductVisible(tester, 'Pendant Necklace');
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('product search shows empty state when nothing matches', (
    tester,
  ) async {
    await pumpProducts(tester);

    await tester.enterText(
      find.byKey(const ValueKey('product-search-field')),
      'denim',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('No products found'), findsOneWidget);
    expect(find.text('No product matches "denim".'), findsOneWidget);
    expect(find.text('Classic Cotton T-Shirt'), findsNothing);
  });

  testWidgets('product page opens add, edit, and delete dialogs', (
    tester,
  ) async {
    await pumpProducts(tester);

    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Add New Product'), findsOneWidget);
    expect(
      find.textContaining('Product Name', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Product Photos', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('edit-product-TSH-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-product-TSH-001')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Product'), findsOneWidget);
    expect(find.text('Current Photos'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('delete-product-TSH-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-product-TSH-001')));
    await tester.pumpAndSettle();
    expect(find.text('Delete Product'), findsWidgets);
    expect(find.text('This action cannot be undone'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-product-TSH-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Product').last);
    await tester.pumpAndSettle();
    expect(productsRepository.deleteCalls, 1);
  });

  testWidgets('product edit form submits its Riverpod draft', (tester) async {
    await pumpProducts(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('edit-product-TSH-001')),
    );
    await tester.tap(find.byKey(const ValueKey('edit-product-TSH-001')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Updated Cotton T-Shirt',
    );
    await tester.tap(find.byKey(const ValueKey('submit-product-form')));
    await tester.pumpAndSettle();

    expect(productsRepository.updateCalls, 1);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('product page opens photo and calibration nested screens', (
    tester,
  ) async {
    await pumpProducts(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('replace-product-photo-TSH-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('replace-product-photo-TSH-001')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Replace photo'), findsOneWidget);
    expect(find.text('Save replacement'), findsOneWidget);

    Navigator.of(tester.element(find.text('Replace photo'))).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('calibrate-product-TSH-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calibrate-product-TSH-001')));
    await tester.pumpAndSettle();
    expect(find.text('Set real-world size'), findsOneWidget);
    expect(find.byType(CustomAppBar), findsOneWidget);
    expect(
      find.text('How should we learn the real-world size?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Place the product on a body outline'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a body view'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Full Body Front')).dx,
      lessThan(tester.getTopLeft(find.text('Hand Side')).dx),
      reason: 'The recommended body view should be shown first.',
    );
    await tester.ensureVisible(find.text('Hand Side'));
    await tester.tap(find.text('Hand Side'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Full Body Front')).dx,
      lessThan(tester.getTopLeft(find.text('Hand Side')).dx),
      reason: 'Selecting a view must not change the grid order.',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a product photo'), findsOneWidget);
    expect(find.text('PLACING ON'), findsOneWidget);
    expect(find.text('hand side'), findsOneWidget);
    expect(find.text('YOUR PRODUCT PHOTOS'), findsOneWidget);
    expect(find.text('Upload another'), findsOneWidget);
  });
}
