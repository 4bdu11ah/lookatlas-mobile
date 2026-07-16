import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpProducts(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(id: 'user-1', email: 'jane@example.com'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardFeatureScreen.products(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> selectProductFilter(
    WidgetTester tester,
    Key filterKey,
    String value,
  ) async {
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

  testWidgets('product page renders catalog chrome and app bar', (
    tester,
  ) async {
    await pumpProducts(tester);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Products'), findsWidgets);
    expect(find.text('Classic Cotton T-Shirt'), findsOneWidget);
    expect(find.text('Canvas Crossbody Bag'), findsOneWidget);
    expect(find.text('Search by name, sku, or description'), findsOneWidget);
    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('All products'), findsOneWidget);
    expect(find.text('Newest first'), findsOneWidget);
    expect(
      find.textContaining(
        '3 products - 1 calibrated',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Add Product'), findsOneWidget);
  });

  testWidgets('product search filters by product fields through Riverpod', (
    tester,
  ) async {
    await pumpProducts(tester);

    final searchField = find.byKey(const ValueKey('product-search-field'));
    await tester.enterText(searchField, 'bag');
    await tester.pump();

    expect(find.text('Canvas Crossbody Bag'), findsOneWidget);
    expect(find.text('Classic Cotton T-Shirt'), findsNothing);
    expect(
      find.textContaining(
        '3 products - 1 calibrated',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.enterText(searchField, 'JWL-018');
    await tester.pump();

    expect(find.text('Pendant Necklace'), findsOneWidget);
    expect(find.text('Canvas Crossbody Bag'), findsNothing);
    expect(
      find.textContaining(
        '3 products - 0 calibrated',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('clear-product-search')));
    await tester.pump();

    expect(find.text('Classic Cotton T-Shirt'), findsOneWidget);
    expect(find.text('Canvas Crossbody Bag'), findsOneWidget);
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
        '3 products - 0 calibrated',
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

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    await selectProductFilter(
      tester,
      const ValueKey('product-sort-filter'),
      'Oldest first',
    );

    expect(find.text('Pendant Necklace'), findsOneWidget);
    expect(find.text('Canvas Crossbody Bag'), findsOneWidget);
    expect(find.text('Classic Cotton T-Shirt'), findsNothing);

    await selectProductFilter(
      tester,
      const ValueKey('product-sort-filter'),
      'Name Z-A',
    );

    expect(find.text('Pendant Necklace'), findsOneWidget);
    expect(find.text('Classic Cotton T-Shirt'), findsOneWidget);
    expect(find.text('Canvas Crossbody Bag'), findsNothing);
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

  testWidgets('product search shows empty state when nothing matches', (
    tester,
  ) async {
    await pumpProducts(tester);

    await tester.enterText(
      find.byKey(const ValueKey('product-search-field')),
      'denim',
    );
    await tester.pump();

    expect(find.text('No products found'), findsOneWidget);
    expect(find.text('No product matches "denim".'), findsOneWidget);
    expect(find.text('Classic Cotton T-Shirt'), findsNothing);
  });

  testWidgets('product page opens add, edit, delete, and paywall dialogs', (
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
    await tester.scrollUntilVisible(
      find.text('Click to upload photos'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.textContaining('Product Photos', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text('Click to upload photos'));
    await tester.pumpAndSettle();
    expect(find.text('3 photos selected'), findsOneWidget);

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

    await tester.ensureVisible(find.text('Dismiss'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Add products. Keep shooting.'), findsOneWidget);
    expect(find.text('View plans'), findsOneWidget);
  });

  testWidgets('product page opens crop and calibration nested screens', (
    tester,
  ) async {
    await pumpProducts(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('crop-product-TSH-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('crop-product-TSH-001')));
    await tester.pumpAndSettle();
    expect(find.text('Crop photo'), findsOneWidget);
    expect(find.text('Save crop'), findsOneWidget);

    await tester.tap(find.text('Save crop'));
    await tester.pumpAndSettle();

    await pumpProducts(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('calibrate-product-TSH-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calibrate-product-TSH-001')));
    await tester.pumpAndSettle();
    expect(find.text('Set real-world size'), findsOneWidget);
    expect(
      find.text('How should we learn the real-world size?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a body view'), findsOneWidget);
  });
}
