import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/shoots/di/shoots_providers.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_shoots_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpModelStep(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(id: 'user-1', email: 'creator@example.com'),
            ),
          ),
          isPremiumProvider.overrideWithValue(true),
          shootsRepositoryProvider.overrideWithValue(
            FakeShootsRepository(catalog: _catalog),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CreateShootScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('model_multi_select_matches_selected_roster_design', (
    tester,
  ) async {
    await pumpModelStep(tester);

    for (final name in ['Mei', 'Sofia']) {
      final model = find.byKey(ValueKey('selection-$name'));
      await tester.ensureVisible(model);
      await tester.tap(model);
      await tester.pumpAndSettle();
    }

    expect(
      find.text(
        "3/3 models · 1 primary + 2 secondary · they'll appear together in 1 shot",
      ),
      findsOneWidget,
    );
    expect(find.text('Clear all'), findsOneWidget);
    expect(find.text('Primary'), findsNWidgets(2));
    expect(find.text('Secondary 1'), findsNWidgets(2));
    expect(find.text('Secondary 2'), findsNWidgets(2));

    final disabledPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey('selection-disabled-Nora')),
    );
    expect(disabledPointer.ignoring, isTrue);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('selection-opacity-Nora')),
          )
          .opacity,
      0.35,
    );
    expect(find.text('Secondary 3'), findsNothing);

    final panel = find.byKey(const ValueKey('create-model-selection-panel'));
    await tester.ensureVisible(panel);
    await tester.pumpAndSettle();

    final primaryBadge = find.descendant(
      of: find.byKey(const ValueKey('selection-Aisha')),
      matching: find.text('Primary'),
    );
    final badgePosition = tester.widget<Positioned>(
      find.ancestor(of: primaryBadge, matching: find.byType(Positioned)).first,
    );
    expect(badgePosition.left, 8);
    expect(badgePosition.right, isNull);

    await tester.tap(find.byTooltip('Remove Mei'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "2/3 models · 1 primary + 1 secondary · they'll appear together in 1 shot",
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const ValueKey('selection-disabled-Nora')),
          )
          .ignoring,
      isFalse,
    );

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
  });

  testWidgets('model_pagination_changes_page_and_search_resets_to_first', (
    tester,
  ) async {
    await pumpModelStep(tester);

    expect(
      find.byKey(const ValueKey('create-model-page-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create-model-page-2')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('create-model-previous-page')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('create-model-next-page')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('create-model-page-2')),
    );
    await tester.tap(find.byKey(const ValueKey('create-model-page-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('selection-Yuki')), findsOneWidget);
    expect(find.byKey(const ValueKey('selection-Aisha')), findsNothing);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('create-model-previous-page')),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('create-model-next-page')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey('create-model-search')),
      'Aisha',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('selection-Aisha')), findsOneWidget);
    expect(find.byKey(const ValueKey('create-model-page-2')), findsNothing);
  });
}

final _catalog = ShootCreateCatalog(
  products: const [
    ShootCatalogItem(
      id: 'product-1',
      name: 'Bag',
      subtitle: 'BAG-1',
      imageUrl: 'assets/images/onboarding/showcase-bag-before.jpg',
    ),
  ],
  userModels: [
    const ShootCatalogItem(
      id: 'model-1',
      name: 'Aisha',
      subtitle: 'Female',
      imageUrl: 'assets/images/onboarding/showcase-dress-after.jpg',
      source: 'user',
    ),
    const ShootCatalogItem(
      id: 'model-2',
      name: 'Mei',
      subtitle: 'Female',
      imageUrl: 'assets/images/onboarding/showcase-tshirt-after.jpg',
      source: 'user',
    ),
    const ShootCatalogItem(
      id: 'model-3',
      name: 'Sofia',
      subtitle: 'Female',
      imageUrl: 'assets/images/onboarding/showcase-shoes-after.jpg',
      source: 'user',
    ),
    const ShootCatalogItem(
      id: 'model-4',
      name: 'Nora',
      subtitle: 'Female',
      imageUrl: 'assets/images/onboarding/showcase-sunglasses-after.jpg',
      source: 'user',
    ),
    ...List.generate(
      7,
      (index) => ShootCatalogItem(
        id: 'model-${index + 5}',
        name: index == 6 ? 'Yuki' : 'Model ${index + 5}',
        subtitle: 'Female',
        imageUrl: 'assets/images/onboarding/showcase-dress-after.jpg',
        source: 'user',
      ),
    ),
  ],
  libraryModels: const [],
  looks: const [],
  lookFilters: const {},
  presets: const [],
  availableCredits: 100,
);
