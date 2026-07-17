import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_dropdown.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontLoader = FontLoader('Satoshi')
      ..addFont(rootBundle.load('assets/fonts/Satoshi-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Satoshi-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Satoshi-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Satoshi-Black.ttf'));
    await fontLoader.load();
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await iconLoader.load();
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    bool isPremium = true,
  }) async {
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
          isPremiumProvider.overrideWithValue(isPremium),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<GoRouter> pumpShootRouter(
    WidgetTester tester, {
    bool isPremium = true,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: AppRoutes.dashboardShoots,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('Dashboard home')),
        ),
        GoRoute(
          path: AppRoutes.dashboardShoots,
          builder: (_, _) => const DashboardFeatureScreen.shoots(),
        ),
        GoRoute(
          path: AppRoutes.shootDetail,
          builder: (_, _) => const ShootDetailScreen(),
        ),
        GoRoute(
          path: AppRoutes.createShoot,
          builder: (_, _) => const CreateShootScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(id: 'user-1', email: 'creator@example.com'),
            ),
          ),
          isPremiumProvider.overrideWithValue(isPremium),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('shoots_free_user_opens_new_shoot_paywall', (tester) async {
    await pumpScreen(
      tester,
      const DashboardFeatureScreen.shoots(),
      isPremium: false,
    );

    expect(find.text('Tan Leather Bag'), findsOneWidget);
    expect(find.text('Gold Evening Heels'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('new-shoot-button')));
    await tester.pumpAndSettle();

    expect(find.text('Spin up another shoot.'), findsOneWidget);
    expect(find.text('200 photos every month'), findsOneWidget);
    expect(find.text('See Pro'), findsOneWidget);
  });

  testWidgets('shoot_dialogs_use_default_app_dialog_style', (tester) async {
    await pumpScreen(
      tester,
      const DashboardFeatureScreen.shoots(),
      isPremium: false,
    );

    await tester.tap(find.byKey(const ValueKey('new-shoot-button')));
    await tester.pumpAndSettle();

    final appDialog = tester.widget<AppDialog>(find.byType(AppDialog));
    expect(appDialog.config, same(AppDialogConfig.standard));
  });

  testWidgets('shoots_app_bar_back_opens_dashboard', (tester) async {
    await pumpShootRouter(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(CustomAppBar),
        matching: find.byIcon(Icons.arrow_back),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard home'), findsOneWidget);
  });

  testWidgets('create_shoot_app_bar_back_opens_shoots', (tester) async {
    await pumpShootRouter(tester);

    await tester.tap(find.byKey(const ValueKey('new-shoot-button')));
    await tester.pumpAndSettle();
    expect(find.text('Create Shoot'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(CustomAppBar),
        matching: find.byIcon(Icons.arrow_back),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('new-shoot-button')), findsOneWidget);
  });

  testWidgets('shoots_page_matches_mobile_golden', (tester) async {
    await pumpScreen(tester, const DashboardFeatureScreen.shoots());
    expect(find.byType(CustomAppBar), findsOneWidget);
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(() async {
      for (final asset in const [
        'assets/images/onboarding/showcase-bag-before.jpg',
        'assets/images/onboarding/showcase-shoes-before.jpg',
        'assets/images/onboarding/showcase-dress-after.jpg',
        'assets/images/onboarding/showcase-tshirt-after.jpg',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/shoots_page.png'),
    );
  });

  testWidgets('shoots_search_and_status_filter_update_visible_cards', (
    tester,
  ) async {
    await pumpScreen(tester, const DashboardFeatureScreen.shoots());

    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.byType(AppDropdown<String>), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const ValueKey('shoot-search-field')),
      'Tan Leather',
    );
    await tester.pump();

    expect(find.text('Tan Leather Bag'), findsOneWidget);
    expect(find.text('Gold Evening Heels'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('shoot-search-field')),
      '',
    );
    await tester.pump();
    await tester.tap(find.text('All statuses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Processing').last);
    await tester.pumpAndSettle();

    expect(find.text('Tan Leather Bag'), findsNothing);
    expect(find.text('Gold Evening Heels'), findsOneWidget);
  });

  testWidgets('create_shoot_wizard_opens_nested_creation_dialogs', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    expect(find.byType(CustomAppBar), findsOneWidget);
    expect(find.text('Back to shoots'), findsNothing);
    final circleCenters = List.generate(
      5,
      (index) => tester
          .getCenter(
            find.byKey(ValueKey('create-step-circle-${index + 1}')),
          )
          .dy,
    );
    BoxDecoration stepDecoration(int index) {
      final indicator = tester.widget<Container>(
        find.byKey(ValueKey('create-step-circle-$index')),
      );
      return indicator.decoration! as BoxDecoration;
    }

    expect(circleCenters.toSet(), hasLength(1));
    expect(stepDecoration(1).color, AppColors.black);
    expect(stepDecoration(2).color, AppColors.neutralLight);
    expect(stepDecoration(1).shape, BoxShape.rectangle);
    expect(stepDecoration(2).shape, BoxShape.rectangle);
    expect(stepDecoration(1).border, isNull);
    expect(stepDecoration(2).border, isNull);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('create-step-circle-1')),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('create-step-label-1')),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    for (var index = 0; index < 4; index++) {
      expect(
        tester
            .getCenter(
              find.byKey(ValueKey('create-step-connector-$index')),
            )
            .dy,
        closeTo(circleCenters[index], 0.1),
      );
    }
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('create-step-label-1'))).dy,
      greaterThan(
        tester
            .getBottomRight(
              find.byKey(const ValueKey('create-step-circle-1')),
            )
            .dy,
      ),
    );
    expect(find.text('Select Product'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create-product-search')),
      findsOneWidget,
    );
    expect(find.byType(AppTextField), findsOneWidget);
    await tester.tap(find.text('Add New Product'));
    await tester.pumpAndSettle();
    expect(find.text('Add New Product'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.byType(AppTextField),
      ),
      findsNWidgets(3),
    );

    await tester.tap(find.text('Click to upload'));
    await tester.pumpAndSettle();
    expect(find.text('Crop photo'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Select Model'), findsOneWidget);
    expect(stepDecoration(1).color, AppColors.neutralLight);
    expect(stepDecoration(2).color, AppColors.black);
    expect(find.byKey(const ValueKey('create-model-search')), findsOneWidget);
    expect(find.byType(AppTextField), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Add New Model'), findsOneWidget);
  });

  testWidgets('create_shoot_product_grid_pages_and_preserves_selection', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    expect(find.text('Tan Leather Bag'), findsNWidgets(2));
    expect(find.text('Silver Necklace'), findsNothing);
    expect(find.text('Previous page'), findsNothing);
    expect(find.text('Next page'), findsNothing);
    final previousButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('create-product-previous-page')),
    );
    final nextButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('create-product-next-page')),
    );
    expect(
      previousButton.style?.shape?.resolve({}),
      isA<RoundedRectangleBorder>(),
    );
    expect(nextButton.style?.shape?.resolve({}), isA<RoundedRectangleBorder>());
    expect(
      previousButton.style?.side?.resolve({})?.color,
      AppColors.neutral200,
    );
    expect(nextButton.style?.side?.resolve({})?.color, AppColors.neutral200);
    final paginationBoxSizes = [
      tester.getSize(
        find.byKey(const ValueKey('create-product-previous-page')),
      ),
      tester.getSize(find.byKey(const ValueKey('create-product-page-1'))),
      tester.getSize(find.byKey(const ValueKey('create-product-page-2'))),
      tester.getSize(find.byKey(const ValueKey('create-product-next-page'))),
    ];
    expect(paginationBoxSizes.toSet(), {const Size.square(36)});
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create-product-page-1')),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create-product-page-2')),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );

    final nextPage = find.byKey(const ValueKey('create-product-next-page'));
    await tester.ensureVisible(nextPage);
    await tester.tap(nextPage);
    await tester.pumpAndSettle();

    expect(find.text('Tan Leather Bag'), findsOneWidget);
    expect(find.text('Silver Necklace'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create-product-page-2')),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );

    final product = find.byKey(
      const ValueKey('selection-Silver Necklace'),
    );
    await tester.ensureVisible(product);
    await tester.tap(product);
    await tester.pumpAndSettle();
    expect(find.text('Silver Necklace'), findsNWidgets(2));

    final previousPage = find.byKey(
      const ValueKey('create-product-previous-page'),
    );
    await tester.ensureVisible(previousPage);
    await tester.tap(previousPage);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create-product-page-1')),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(find.text('Silver Necklace'), findsOneWidget);
  });

  testWidgets('create_shoot_planning_builds_plan_and_custom_shot_dialog', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    for (var index = 0; index < 3; index++) {
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('plan-shoot-button')));
    await tester.pumpAndSettle();

    expect(find.text('Cafe Arrival'), findsOneWidget);
    expect(find.text('Quiet Product Moment'), findsOneWidget);

    await tester.ensureVisible(find.text('Add Custom Shot'));
    await tester.tap(find.text('Add Custom Shot'));
    await tester.pumpAndSettle();

    expect(find.text('Create Custom Shot'), findsOneWidget);
    expect(find.text("What's your shot idea? *"), findsOneWidget);
    expect(find.text('Pose Direction (optional)'), findsOneWidget);
  });

  testWidgets('create_shoot_opens_subtype_portfolio_and_portfolio_viewer', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    final productCard = find.byKey(
      const ValueKey('selection-Tan Leather Bag'),
    );
    await tester.ensureVisible(productCard);
    await tester.tap(productCard);
    await tester.pumpAndSettle();
    expect(find.text('Pick a sub-type'), findsOneWidget);
    expect(find.text('Crossbody bag'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 2; index++) {
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    final portfolioButton = find.byKey(
      const ValueKey('director-portfolio-Alex Chen'),
    );
    await tester.ensureVisible(portfolioButton);
    await tester.tap(portfolioButton);
    await tester.pumpAndSettle();
    expect(find.text('THE STORY'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('portfolio-image-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 4'), findsOneWidget);
    expect(
      find.text('Crisp tailoring with clean, commercial light'),
      findsOneWidget,
    );
  });

  testWidgets('completed_shoot_opens_preview_and_video_three_step_flow', (
    tester,
  ) async {
    await pumpScreen(tester, const ShootDetailScreen());

    expect(find.text('Completed'), findsOneWidget);
    await tester.ensureVisible(find.text('Generate Video'));
    await tester.tap(find.text('Generate Video'));
    await tester.pumpAndSettle();

    expect(find.text('Choose quality'), findsOneWidget);
    expect(
      tester
          .widget<Container>(
            find.byKey(const ValueKey('video-progress-1')),
          )
          .color,
      AppColors.black,
    );
    expect(
      tester
          .widget<Container>(
            find.byKey(const ValueKey('video-progress-2')),
          )
          .color,
      AppColors.neutral200,
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Starting Frame'), findsOneWidget);
    expect(
      tester
          .widget<Container>(
            find.byKey(const ValueKey('video-progress-2')),
          )
          .color,
      AppColors.black,
    );
    expect(
      tester
          .widget<Container>(
            find.byKey(const ValueKey('video-progress-3')),
          )
          .color,
      AppColors.neutral200,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Almost There'), findsOneWidget);
    expect(find.text('Generate Video · 10 Credits'), findsOneWidget);
    expect(
      tester
          .widget<Container>(
            find.byKey(const ValueKey('video-progress-3')),
          )
          .color,
      AppColors.black,
    );
    final backFlex = tester.widget<Expanded>(
      find.ancestor(
        of: find.byKey(const ValueKey('video-confirm-back')),
        matching: find.byType(Expanded),
      ),
    );
    final generateFlex = tester.widget<Expanded>(
      find.ancestor(
        of: find.byKey(const ValueKey('video-confirm-generate')),
        matching: find.byType(Expanded),
      ),
    );
    expect(backFlex.flex, 1);
    expect(generateFlex.flex, 3);
  });

  testWidgets('completed_shoot_opens_all_image_and_calibration_dialogs', (
    tester,
  ) async {
    await pumpScreen(tester, const ShootDetailScreen());

    await tester.ensureVisible(find.text('Calibrate Product'));
    await tester.tap(find.text('Calibrate Product'));
    await tester.pumpAndSettle();
    expect(find.text('Calibrate Tan Leather Bag'), findsOneWidget);
    expect(find.text('Upload a worn photo'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    final firstResult = find
        .byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName.endsWith(
                'showcase-bag-after.jpg',
              ),
        )
        .first;
    await tester.ensureVisible(firstResult);
    await tester.tap(firstResult);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.download_outlined), findsWidgets);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.auto_fix_high).first);
    await tester.pumpAndSettle();
    expect(find.text('Edit with AI'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history).first);
    await tester.pumpAndSettle();
    expect(find.text('Version History'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add').first);
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();
    expect(find.text('Add Variation'), findsOneWidget);
    expect(find.text('Generated in 2K · 2 credits.'), findsOneWidget);
  });

  testWidgets('processing_and_failed_shoot_cards_open_matching_details', (
    tester,
  ) async {
    final router = await pumpShootRouter(tester);

    final details = find.text('View Details');
    await tester.ensureVisible(details.at(1));
    await tester.tap(details.at(1));
    await tester.pumpAndSettle();

    expect(find.byType(ShootDetailScreen), findsOneWidget);
    expect(find.byType(DashboardFeatureScreen), findsNothing);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('64%'), findsOneWidget);
    expect(find.text('Generating images...'), findsOneWidget);
    expect(find.byType(CustomAppBar), findsOneWidget);
    expect(find.text('Back to Jobs'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(CustomAppBar),
        matching: find.byIcon(Icons.arrow_back),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.dashboardShoots,
    );
    final refreshedDetails = find.text('View Details');
    await tester.ensureVisible(refreshedDetails.at(2));
    await tester.tap(refreshedDetails.at(2));
    await tester.pumpAndSettle();

    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('job_7f2a9c13'), findsOneWidget);
    expect(find.text('Rerun Job'), findsOneWidget);
  });
}
