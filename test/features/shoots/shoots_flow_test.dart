import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/shoots/di/shoots_providers.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_shoots_repository.dart';
import '../../helpers/test_font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadTestFonts);

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    bool isPremium = true,
    FakeShootsRepository? shootsRepository,
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
          shootsRepositoryProvider.overrideWithValue(
            shootsRepository ?? FakeShootsRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<GoRouter> pumpShootRouter(
    WidgetTester tester, {
    bool isPremium = true,
    FakeShootsRepository? shootsRepository,
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
          builder: (_, _) => const ShootsScreen(),
        ),
        GoRoute(
          path: AppRoutes.shootDetailPath,
          builder: (_, state) => ShootDetailScreen(
            jobId: state.pathParameters['jobId']!,
          ),
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
          shootsRepositoryProvider.overrideWithValue(
            shootsRepository ?? FakeShootsRepository(),
          ),
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
      const ShootsScreen(),
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
      const ShootsScreen(),
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

  testWidgets('create_shoot_first_step_cancel_opens_shoots', (tester) async {
    await pumpShootRouter(tester);

    await tester.tap(find.byKey(const ValueKey('new-shoot-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('create-shoot-cancel')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('create-shoot-back')), findsNothing);

    final cancelButton = find.byKey(const ValueKey('create-shoot-cancel'));
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('new-shoot-button')), findsOneWidget);
  });

  testWidgets('create_shoot_content_stays_aligned_to_top', (tester) async {
    await pumpScreen(tester, const CreateShootScreen());

    final alignment = tester.widget<Align>(
      find.byKey(const ValueKey('create-shoot-top-alignment')),
    );

    expect(alignment.alignment, Alignment.topCenter);
  });

  testWidgets('create_shoot_later_steps_show_back_instead_of_cancel', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create-shoot-back')), findsOneWidget);
    expect(find.byKey(const ValueKey('create-shoot-cancel')), findsNothing);
  });

  testWidgets('create_shoot_loading_shows_shimmer_in_product_grid', (
    tester,
  ) async {
    final repository = _DelayedCreateCatalogRepository();
    await pumpScreen(
      tester,
      const CreateShootScreen(),
      shootsRepository: repository,
    );

    final grid = find.byKey(const ValueKey('create-product-grid-shimmer'));
    expect(find.text('Select Product'), findsOneWidget);
    expect(grid, findsOneWidget);
    expect(
      find.descendant(of: grid, matching: find.byType(ShimmerBox)),
      findsNWidgets(4),
    );
    expect(find.byType(ContentShimmer), findsNothing);

    repository.completeCatalog();
    await tester.pumpAndSettle();

    expect(grid, findsNothing);
  });

  testWidgets('shoots_search_and_status_filter_update_visible_cards', (
    tester,
  ) async {
    await pumpScreen(tester, const ShootsScreen());

    expect(find.byType(AppTextField), findsOneWidget);
    expect(
      find.byKey(const ValueKey('open-shoot-filter-sheet')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('shoot-search-field')),
      'Tan Leather',
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Tan Leather Bag'), findsOneWidget);
    expect(find.text('Gold Evening Heels'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('shoot-search-field')),
      '',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
      find.byKey(const ValueKey('open-shoot-filter-sheet')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Processing').last);
    await tester.pump();
    await tester.tap(find.text('Show shoots'));
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
    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();
    expect(find.text('Add New Product'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.byType(AppTextField),
      ),
      findsNWidgets(4),
    );

    await tester.tap(find.text('Click to upload'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
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

  testWidgets(
    'create_shoot_product_selection_matches_single_and_multi_states',
    (tester) async {
      await pumpScreen(tester, const CreateShootScreen());

      expect(find.text('Add Product'), findsOneWidget);
      expect(find.text('1/3 products'), findsOneWidget);
      expect(
        find.text('Set real-world size so the model renders it to scale'),
        findsOneWidget,
      );
      expect(find.text('Worn together'), findsNothing);
      expect(find.text('Colour / style variants'), findsNothing);
      expect(find.text('Tan Leather Bag'), findsNWidgets(2));
      expect(find.text('Silver Necklace'), findsOneWidget);

      final product = find.byKey(
        const ValueKey('selection-Silver Necklace'),
      );
      await tester.ensureVisible(product);
      await tester.tap(product);
      await tester.pumpAndSettle();

      expect(
        find.text('2/3 products · worn together in every shot'),
        findsOneWidget,
      );
      expect(find.text('Worn together'), findsOneWidget);
      expect(find.text('Colour / style variants'), findsOneWidget);
      expect(find.text('Product 2'), findsNWidgets(2));
      expect(find.text('Silver Necklace'), findsNWidgets(2));

      await tester.tap(find.text('Colour / style variants'));
      await tester.pumpAndSettle();
      expect(
        find.text('2/6 products · split across shots as variants'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Remove Silver Necklace'));
      await tester.pumpAndSettle();
      expect(find.text('1/3 products'), findsOneWidget);
      expect(find.text('Worn together'), findsNothing);

      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create-product-selection-panel')),
        findsNothing,
      );
    },
  );

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

  testWidgets('create_shoot_opens_director_portfolio_and_viewer', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

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
    expect(find.text('Clean Professional'), findsWidgets);
  });

  testWidgets('create_shoot_director_step_matches_updated_spec', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    for (var index = 0; index < 2; index++) {
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Choose Your Creative Director'), findsOneWidget);
    expect(
      find.text("Select what you're creating and who should direct the shoot"),
      findsOneWidget,
    );
    expect(find.text('E-commerce PDP'), findsOneWidget);
    expect(find.text('Social Media'), findsOneWidget);
    expect(find.text('Lookbook'), findsOneWidget);
    expect(find.text('Campaign'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Like Uniqlo, Everlane'), findsOneWidget);
    expect(find.text('Brief Alex Chen (optional)'), findsOneWidget);
    expect(
      find.text("Anything specific you'd like the director to consider?"),
      findsOneWidget,
    );
    expect(find.text('Resolution'), findsNothing);
    expect(find.text('Additional Settings'), findsNothing);

    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('create-director-grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(delegate.crossAxisSpacing, 16);
    expect(delegate.mainAxisSpacing, 16);
    expect(delegate.childAspectRatio, 3 / 4);

    final isabella = find.byKey(
      const ValueKey('selection-Isabella Romano'),
    );
    await tester.ensureVisible(isabella);
    await tester.tap(isabella);
    await tester.pumpAndSettle();

    expect(find.text('Brief Isabella Romano (optional)'), findsOneWidget);
  });

  testWidgets('completed_shoot_opens_preview_and_video_three_step_flow', (
    tester,
  ) async {
    final repository = FakeShootsRepository();
    await pumpScreen(
      tester,
      const ShootDetailScreen(jobId: 'job-bag'),
      shootsRepository: repository,
    );

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

    await tester.tap(find.text('Generate Video · 10 Credits'));
    await tester.pumpAndSettle();

    expect(repository.lastVideoRequest?.variationIndex, 0);
    expect(repository.lastVideoRequest?.aspectRatio, '9:16');
    expect(repository.lastVideoRequest?.videoTier, 'standard');
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
    expect(find.byType(ShootsScreen), findsNothing);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('64%'), findsOneWidget);
    expect(find.text('Generating images...'), findsWidgets);
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

class _DelayedCreateCatalogRepository extends FakeShootsRepository {
  final _catalogCompleter = Completer<Result<ShootCreateCatalog>>();

  @override
  Future<Result<ShootCreateCatalog>> loadCreateCatalog() =>
      _catalogCompleter.future;

  void completeCatalog() => _catalogCompleter.complete(
    super.loadCreateCatalog(),
  );
}
