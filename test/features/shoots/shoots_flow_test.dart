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
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
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
    String role = 'user',
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
              user: AppUser(
                id: 'user-1',
                email: 'creator@example.com',
                role: role,
              ),
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

  Future<void> selectCurrentCreateStepAndContinue(
    WidgetTester tester,
  ) async {
    final selection = switch (true) {
      _ when find.text('Select Product').evaluate().isNotEmpty => find.byKey(
        const ValueKey('selection-Tan Leather Bag'),
      ),
      _ when find.text('Select Model').evaluate().isNotEmpty => find.byKey(
        const ValueKey('selection-Mila'),
      ),
      _ => find.byKey(const ValueKey('selection-Alex Chen')),
    };
    await tester.ensureVisible(selection);
    await tester.tap(selection);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  Future<GoRouter> pumpShootRouter(
    WidgetTester tester, {
    bool isPremium = true,
    String role = 'user',
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
              user: AppUser(
                id: 'user-1',
                email: 'creator@example.com',
                role: role,
              ),
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

  testWidgets('create_shoot_requires_product_model_and_director_selection', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    PrimaryButton nextButton() => tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Next'),
    );

    expect(
      find.byKey(const ValueKey('create-product-selection-panel')),
      findsNothing,
    );
    expect(nextButton().onPressed, isNull);

    await tester.tap(
      find.byKey(const ValueKey('selection-Tan Leather Bag')),
    );
    await tester.pumpAndSettle();
    expect(nextButton().onPressed, isNotNull);
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('create-model-selection-panel')),
      findsNothing,
    );
    expect(nextButton().onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('selection-Mila')));
    await tester.pumpAndSettle();
    expect(nextButton().onPressed, isNotNull);
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final directorGrid = find.byKey(const ValueKey('create-director-grid'));
    expect(
      find.descendant(of: directorGrid, matching: find.byIcon(Icons.check)),
      findsNothing,
    );
    expect(find.text('Brief Alex Chen (optional)'), findsNothing);
    expect(nextButton().onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('selection-Alex Chen')));
    await tester.pumpAndSettle();
    expect(nextButton().onPressed, isNotNull);
  });

  testWidgets('create_shoot_third_step_scrolls_to_top', (tester) async {
    await pumpScreen(tester, const CreateShootScreen());
    tester.view.physicalSize = const Size(390, 500);
    await tester.pumpAndSettle();

    await selectCurrentCreateStepAndContinue(tester);

    final scrollable = find
        .descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.ensureVisible(find.byKey(const ValueKey('selection-Mila')));
    await tester.tap(find.byKey(const ValueKey('selection-Mila')));
    await tester.pumpAndSettle();
    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(0),
    );

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
    expect(find.text('Choose Your Creative Director'), findsOneWidget);
  });

  testWidgets('create_shoot_later_steps_show_back_instead_of_cancel', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    await selectCurrentCreateStepAndContinue(tester);

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

    await selectCurrentCreateStepAndContinue(tester);
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

      await tester.tap(
        find.byKey(const ValueKey('selection-Tan Leather Bag')),
      );
      await tester.pumpAndSettle();

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

    for (var index = 0; index < 2; index++) {
      await selectCurrentCreateStepAndContinue(tester);
    }
    await tester.tap(
      find.byKey(const ValueKey('selection-Isabella Romano')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
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
    expect(
      find.text(
        'Your custom shot will match the current shoot settings '
        '(location: Let AI Decide, director: Isabella Romano)',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('custom-shot-idea')),
      '1234567890',
    );
    await tester.tap(find.text('Add Shot'));
    await tester.pumpAndSettle();

    expect(
      find.text('Shot idea must be more than 10 characters.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Create Custom Shot'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('custom-shot-idea')),
      '12345678901',
    );
    await tester.tap(find.text('Add Shot'));
    await tester.pumpAndSettle();

    expect(find.text('Create Custom Shot'), findsNothing);
  });

  testWidgets('create_shoot_planning_shows_custom_loader_and_status_text', (
    tester,
  ) async {
    final repository = _DelayedPlanShotsRepository();
    await pumpScreen(
      tester,
      const CreateShootScreen(),
      shootsRepository: repository,
    );

    for (var index = 0; index < 3; index++) {
      await selectCurrentCreateStepAndContinue(tester);
    }
    await tester.tap(find.byKey(const ValueKey('plan-shoot-button')));
    await tester.pump();

    expect(find.byType(ButtonLoader), findsOneWidget);
    expect(find.text('Planning Shots...'), findsOneWidget);

    await repository.completePlan();
    await tester.pumpAndSettle();
    expect(find.text('Cafe Arrival'), findsOneWidget);
  });

  testWidgets('create_shoot_planning_disables_back_and_next_navigation', (
    tester,
  ) async {
    final repository = _DelayedPlanShotsRepository();
    await pumpScreen(
      tester,
      const CreateShootScreen(),
      shootsRepository: repository,
    );

    for (var index = 0; index < 3; index++) {
      await selectCurrentCreateStepAndContinue(tester);
    }
    await tester.tap(find.byKey(const ValueKey('plan-shoot-button')));
    await tester.pump();

    final backButton = tester.widget<AppOutlinedButton>(
      find.byKey(const ValueKey('create-shoot-back')),
    );
    final nextButton = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Next'),
    );
    expect(backButton.onPressed, isNull);
    expect(nextButton.onPressed, isNull);

    await repository.completePlan();
    await tester.pumpAndSettle();
  });

  testWidgets('create_shoot_replanning_shows_loader_and_locks_navigation', (
    tester,
  ) async {
    final repository = _DelayedReplanShotsRepository();
    await pumpScreen(
      tester,
      const CreateShootScreen(),
      shootsRepository: repository,
    );

    for (var index = 0; index < 3; index++) {
      await selectCurrentCreateStepAndContinue(tester);
    }
    await tester.tap(find.byKey(const ValueKey('plan-shoot-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Re-Plan Shots'));
    await tester.pump();

    final planButton = tester.widget<PrimaryButton>(
      find.byKey(const ValueKey('plan-shoot-button')),
    );
    final backButton = tester.widget<AppOutlinedButton>(
      find.byKey(const ValueKey('create-shoot-back')),
    );
    final nextButton = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Next'),
    );
    expect(planButton.isLoading, isTrue);
    expect(find.byType(ButtonLoader), findsOneWidget);
    expect(find.text('Planning Shots...'), findsOneWidget);
    expect(backButton.onPressed, isNull);
    expect(nextButton.onPressed, isNull);

    await repository.completeReplan();
    await tester.pumpAndSettle();
    expect(find.text('Re-Plan Shots'), findsOneWidget);
  });

  testWidgets('create_shoot_review_uses_list_layout_and_full_generate_action', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    await tester.tap(
      find.byKey(const ValueKey('selection-Tan Leather Bag')),
    );
    await tester.tap(find.byKey(const ValueKey('selection-Silver Necklace')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 2; index++) {
      await selectCurrentCreateStepAndContinue(tester);
    }
    await tester.tap(find.byKey(const ValueKey('plan-shoot-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final reviewLayout = find.byKey(const ValueKey('review-layout'));
    final products = find.byKey(const ValueKey('review-products'));
    final models = find.byKey(const ValueKey('review-models'));
    final shots = find.byKey(const ValueKey('review-shots'));
    final settings = find.byKey(const ValueKey('review-settings'));
    expect(
      find.descendant(of: reviewLayout, matching: find.byType(GridView)),
      findsNothing,
    );
    expect(tester.getSize(products).width, tester.getSize(models).width);
    expect(
      tester.getTopLeft(models).dy,
      greaterThan(tester.getBottomLeft(products).dy),
    );
    expect(tester.getTopLeft(shots).dy, tester.getTopLeft(settings).dy);
    expect(
      tester.getSize(shots).width,
      lessThan(tester.getSize(products).width),
    );
    expect(find.text('Tan Leather Bag'), findsWidgets);
    expect(find.text('Silver Necklace'), findsWidgets);
    expect(find.text('Mila'), findsWidgets);

    final generateFinder = find.byWidgetPredicate(
      (widget) =>
          widget is PrimaryButton &&
          (widget.label?.startsWith('Generate ') ?? false),
    );
    final generateButton = tester.widget<PrimaryButton>(generateFinder);
    final generateFlex = tester.widget<Expanded>(
      find.ancestor(of: generateFinder, matching: find.byType(Expanded)).first,
    );
    expect(generateButton.label, endsWith(' Shots'));
    expect(generateButton.iconAlignment, IconAlignment.start);
    expect(generateFlex.flex, 2);
  });

  testWidgets('create_shoot_opens_director_portfolio_and_viewer', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    for (var index = 0; index < 2; index++) {
      await selectCurrentCreateStepAndContinue(tester);
    }
    await tester.tap(
      find.byKey(const ValueKey('selection-Isabella Romano')),
    );
    await tester.pumpAndSettle();
    final portfolioButton = find.byKey(
      const ValueKey('director-portfolio-Alex Chen'),
    );
    await tester.ensureVisible(portfolioButton);
    await tester.tap(portfolioButton);
    await tester.pumpAndSettle();
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('The Story'), findsOneWidget);
    expect(find.text('Style Characteristics'), findsOneWidget);
    expect(find.text('Best For'), findsOneWidget);
    expect(find.text('Signature Approach'), findsOneWidget);
    expect(find.text('Similar Brand Aesthetics'), findsOneWidget);
    expect(find.text('Use Director'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('portfolio-image-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Close image preview'), findsWidgets);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('4 / 4'), findsOneWidget);
  });

  testWidgets('create_shoot_director_step_matches_updated_spec', (
    tester,
  ) async {
    await pumpScreen(tester, const CreateShootScreen());

    for (var index = 0; index < 2; index++) {
      await selectCurrentCreateStepAndContinue(tester);
    }

    expect(find.text('Choose Your Creative Director'), findsOneWidget);
    expect(
      find.text("Select what you're creating and who should direct the shoot"),
      findsOneWidget,
    );
    expect(find.text('Product Detail Page'), findsOneWidget);
    expect(find.text('Social Media'), findsOneWidget);
    expect(find.text('Lookbook / Catalog'), findsOneWidget);
    expect(find.text('Campaign / Hero'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Like Uniqlo, Everlane'), findsOneWidget);
    expect(find.text('Brief Alex Chen (optional)'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('selection-Alex Chen')));
    await tester.pumpAndSettle();

    expect(find.text('Brief Alex Chen (optional)'), findsOneWidget);
    expect(
      find.textContaining('Tell Alex Chen any specific direction'),
      findsOneWidget,
    );
    expect(find.text('Unlimited photos'), findsWidgets);
    expect(find.text('Resolution'), findsOneWidget);
    expect(find.text('Additional Settings'), findsOneWidget);
    expect(find.text('Number of Shots'), findsOneWidget);
    expect(find.text('Variations per Shot'), findsOneWidget);
    expect(find.text('Background Preference'), findsOneWidget);

    final choiceLists = tester.widgetList<ListView>(
      find.byKey(const ValueKey('director-choice-list')),
    );
    expect(choiceLists, isNotEmpty);
    expect(
      choiceLists.every((list) => list.scrollDirection == Axis.horizontal),
      isTrue,
    );

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

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.text('Isabella Romano will plan your product detail page shoot'),
      findsOneWidget,
    );
    expect(
      find.text('Isabella Romano will plan 5 unique shots'),
      findsOneWidget,
    );
    expect(
      find.text('Style: Luxury Editorial • For: Product Detail Page'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('create-shoot-back')));
    await tester.pumpAndSettle();

    final beatrice = find.byKey(
      const ValueKey('selection-Beatrice Hartley'),
    );
    await tester.ensureVisible(beatrice);
    await tester.tap(beatrice);
    await tester.pumpAndSettle();

    expect(
      find.text('Styling for Beatrice Hartley (optional)'),
      findsOneWidget,
    );
    expect(find.text('Clothing style'), findsOneWidget);
    expect(find.text('Dress length'), findsOneWidget);
    expect(find.text('Socks or tights'), findsOneWidget);
    expect(find.text('Hairstyle'), findsOneWidget);
    expect(find.text('Other notes (accessories, etc.)'), findsOneWidget);
  });

  testWidgets('create_shoot_admin_demo_uses_multi_director_budgets', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const CreateShootScreen(),
      role: 'admin',
    );

    for (var index = 0; index < 2; index++) {
      await selectCurrentCreateStepAndContinue(tester);
    }

    await tester.tap(find.byKey(const ValueKey('create-demo-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('New Demo Shoot'), findsOneWidget);
    expect(find.text('Select directors (one or more)'), findsOneWidget);
    expect(find.text('Brief the directors (optional)'), findsNothing);
    expect(find.text('Unlimited photos'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('selection-Alex Chen')));
    await tester.pumpAndSettle();

    expect(find.text('Brief the directors (optional)'), findsOneWidget);
    expect(find.text('Shots: 5'), findsOneWidget);
    expect(find.text('Variations / shot'), findsOneWidget);
    expect(find.text('10 images from this director'), findsOneWidget);
    expect(find.text('Styling for Beatrice Hartley (optional)'), findsNothing);
  });

  testWidgets('create_shoot_admin_demo_fans_out_with_one_group_id', (
    tester,
  ) async {
    final repository = FakeShootsRepository();
    final router = await pumpShootRouter(
      tester,
      role: 'admin',
      shootsRepository: repository,
    );
    router.go(AppRoutes.createShoot);
    await tester.pumpAndSettle();

    for (var index = 0; index < 2; index++) {
      await selectCurrentCreateStepAndContinue(tester);
    }
    await tester.tap(find.byKey(const ValueKey('create-demo-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('selection-Alex Chen')));
    await tester.tap(find.byKey(const ValueKey('selection-Isabella Romano')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Generate Demo'), findsWidgets);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Generate Demo'));
    await tester.pumpAndSettle();

    expect(repository.planShotsCalls, 2);
    expect(repository.createShootCalls, 2);
    expect(
      repository.createRequests.map((request) => request.demoGroupId).toSet(),
      hasLength(1),
    );
    expect(repository.createRequests.first.demoGroupId, isNotEmpty);
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

class _DelayedPlanShotsRepository extends FakeShootsRepository {
  final _planCompleter = Completer<Result<List<PlannedShootShot>>>();
  late ShootSelection _selection;

  @override
  Future<Result<List<PlannedShootShot>>> planShots(
    ShootSelection selection,
  ) {
    _selection = selection;
    return _planCompleter.future;
  }

  Future<void> completePlan() async {
    _planCompleter.complete(await super.planShots(_selection));
  }
}

class _DelayedReplanShotsRepository extends FakeShootsRepository {
  final _replanCompleter = Completer<Result<List<PlannedShootShot>>>();
  late ShootSelection _selection;
  var _planCount = 0;

  @override
  Future<Result<List<PlannedShootShot>>> planShots(
    ShootSelection selection,
  ) {
    _planCount++;
    if (_planCount == 1) return super.planShots(selection);
    _selection = selection;
    return _replanCompleter.future;
  }

  Future<void> completeReplan() async {
    _replanCompleter.complete(await super.planShots(_selection));
  }
}
