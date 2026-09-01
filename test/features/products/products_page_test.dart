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
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';

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
  int getProductsCalls = 0;

  @override
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query) async {
    getProductsCalls++;
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
  Future<Result<Map<String, ProductCalibrationStatus>>>
  getCalibrationStatuses() async => const Result.ok({
    'product-2': ProductCalibrationStatus.calibrated,
  });

  @override
  Future<Result<String>> createProduct(CatalogProductDraft draft) async =>
      const Result.ok('product-created');

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
    Map<Object, String?> angles,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> deleteProduct(String productId) async {
    deleteCalls++;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deletePhoto(String productId, String photoId) async =>
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
    ProductUpload photo, {
    required String? calibrationId,
    required String? revision,
    required String mutationId,
  }) async => const Result.ok(null);

  @override
  Future<Result<void>> deleteWornPhoto(
    String productId,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> uploadPlacement(
    String productId,
    ProductUpload cutout,
    Map<String, dynamic> placement,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);

  @override
  Future<Result<CalibrationRender>> startCalibrationRender(
    String productId, {
    required String bodyPreset,
    required String mutationId,
    String? feedback,
    String? previousRenderId,
  }) async => const Result.ok(
    CalibrationRender(
      id: 'render-1',
      status: CalibrationRenderStatus.completed,
      imageUrl: 'render.jpg',
    ),
  );

  @override
  Future<Result<CalibrationRender?>> getLatestCalibrationRender(
    String productId,
  ) async => const Result.ok(null);

  @override
  Future<Result<List<CalibrationRender>>> getCalibrationRenders(
    String productId,
  ) async => const Result.ok([]);

  @override
  Future<Result<void>> approveCalibrationRender(
    String productId,
    String renderId,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> promoteCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> discardCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
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
    CalibrationMutationFence fence,
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
  final calibration =
      Completer<Result<Map<String, ProductCalibrationStatus>>>();

  @override
  Future<Result<Map<String, ProductCalibrationStatus>>>
  getCalibrationStatuses() => calibration.future;
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
          isPremiumProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('products_screen_reuses_loaded_catalog_when_reopened', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            user: const AppUser(id: 'user-1', email: 'jane@example.com'),
          ),
        ),
        productsRepositoryProvider.overrideWithValue(productsRepository),
        isPremiumProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(productsRepository.getProductsCalls, 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(productsRepository.getProductsCalls, 1);
  });

  Future<void> selectProductFilter(
    WidgetTester tester,
    Key filterKey,
    String value,
  ) async {
    await tester.scrollUntilVisible(
      find.byKey(filterKey),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(filterKey));
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

  Future<void> openProductDetail(WidgetTester tester) async {
    final card = find.byKey(const ValueKey('open-product-TSH-001'));
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  Future<void> scrollProductDetailTo(
    WidgetTester tester,
    Finder target,
  ) async {
    final detailScroll = find.byWidgetPredicate(
      (widget) => widget is ListView && widget.scrollDirection == Axis.vertical,
    );
    final scrollable = find.descendant(
      of: detailScroll.last,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      target,
      260,
      scrollable: scrollable.first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('product page renders catalog chrome and app bar', (
    tester,
  ) async {
    await pumpProducts(tester);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Products'), findsWidgets);
    expect(find.text('Search products or SKUs'), findsOneWidget);
    expect(find.text('3 PRODUCTS, 1 CALIBRATED'), findsOneWidget);
    expect(find.text('Add a product'), findsOneWidget);
    expect(find.text('The pieces in your studio.'), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('product-loading-shimmer-card-0')),
      300,
      scrollable: find.byType(Scrollable),
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

    await ensureProductVisible(tester, 'Canvas Crossbody Bag');
    expect(find.text('Classic Cotton T-Shirt'), findsNothing);
    expect(find.text('1 PRODUCTS, 1 CALIBRATED'), findsOneWidget);

    await tester.enterText(searchField, 'JWL-018');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await ensureProductVisible(tester, 'Pendant Necklace');
    expect(find.text('Canvas Crossbody Bag'), findsNothing);
    expect(find.text('1 PRODUCTS, 0 CALIBRATED'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('clear-product-search')));
    await tester.pumpAndSettle();

    await ensureProductVisible(tester, 'Classic Cotton T-Shirt');
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

    await ensureProductVisible(tester, 'Classic Cotton T-Shirt');
    expect(find.text('Canvas Crossbody Bag'), findsNothing);
    expect(find.text('1 PRODUCTS, 0 CALIBRATED'), findsOneWidget);

    await selectProductFilter(
      tester,
      const ValueKey('product-status-filter'),
      'Calibrated',
    );

    expect(find.text('No products found'), findsOneWidget);
    expect(find.text('Try a different filter combination.'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
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

  testWidgets('product card opens detail with selectable references', (
    tester,
  ) async {
    await pumpProducts(tester);
    await openProductDetail(tester);
    expect(find.text('PRODUCT RECORD'), findsOneWidget);
    await scrollProductDetailTo(tester, find.text('REFERENCE VIEWS'));
    expect(find.text('REFERENCE VIEWS'), findsOneWidget);
    await scrollProductDetailTo(tester, find.text('Start a shoot'));
    expect(find.text('Start a shoot'), findsOneWidget);
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

    await tester.tap(find.text('Add a product'));
    await tester.pumpAndSettle();
    expect(find.text('Add a product'), findsWidgets);
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

    await openProductDetail(tester);
    await scrollProductDetailTo(tester, find.text('Edit product'));
    await tester.tap(find.text('Edit product'));
    await tester.pumpAndSettle();
    expect(find.text('Edit product'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Current Photos'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Current Photos'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await openProductDetail(tester);
    await scrollProductDetailTo(tester, find.text('Remove'));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm remove'), findsOneWidget);
    await tester.tap(find.text('Confirm remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Product').last);
    await tester.pumpAndSettle();
    expect(productsRepository.deleteCalls, 1);
  });

  testWidgets('product edit form submits its Riverpod draft', (tester) async {
    await pumpProducts(tester);

    await openProductDetail(tester);
    await scrollProductDetailTo(tester, find.text('Edit product'));
    await tester.tap(find.text('Edit product'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Updated Cotton T-Shirt',
    );
    await tester.tap(find.byKey(const ValueKey('submit-product-form')));
    await tester.pumpAndSettle();

    expect(productsRepository.updateCalls, 1);
    expect(find.text('Edit product'), findsNothing);
  });

  testWidgets('product page opens calibration nested flow', (
    tester,
  ) async {
    await pumpProducts(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('calibrate-product-TSH-001')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calibrate-product-TSH-001')));
    await tester.pumpAndSettle();
    expect(find.text('Set product size'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
    expect(
      find.text('Choose the easiest way to set the size'),
      findsOneWidget,
    );

    await tester.tap(find.text('Use a product photo'));
    await tester.pumpAndSettle();
    expect(find.text('Set the size in 3 easy steps'), findsOneWidget);
    await tester.tap(find.text('Choose a product photo'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a product photo'), findsOneWidget);
    expect(find.text('SIZE GUIDE'), findsOneWidget);
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a different size guide'), findsOneWidget);
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
    expect(find.text('SIZE GUIDE'), findsOneWidget);
    expect(find.text('hand side'), findsOneWidget);
    expect(find.text('YOUR PRODUCT PHOTOS'), findsOneWidget);
    expect(find.text('Upload another'), findsOneWidget);
  });
}
