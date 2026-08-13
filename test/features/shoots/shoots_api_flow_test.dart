import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/shoots/di/shoots_providers.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_shoots_repository.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen,
    FakeShootsRepository repository, {
    Size physicalSize = const Size(390, 844),
  }) async {
    tester.view
      ..physicalSize = physicalSize
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
          shootsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectCreateChoiceAndContinue(
    WidgetTester tester,
    String choice,
  ) async {
    final selection = find.byKey(ValueKey('selection-$choice'));
    expect(selection, findsOneWidget, reason: choice);
    await tester.ensureVisible(selection);
    await tester.tap(selection);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('create_shoot_exposes_customer_flow_only', (tester) async {
    await pumpScreen(
      tester,
      const CreateShootScreen(),
      FakeShootsRepository(),
    );

    expect(find.text('New Shoot'), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-shoot-toggle')), findsNothing);
  });

  Future<GoRouter> pumpRouter(
    WidgetTester tester,
    FakeShootsRepository repository,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: AppRoutes.dashboardShoots,
      routes: [
        GoRoute(
          path: AppRoutes.dashboardShoots,
          builder: (_, _) => const ShootsScreen(),
        ),
        GoRoute(
          path: AppRoutes.createShoot,
          builder: (_, _) => const CreateShootScreen(),
        ),
        GoRoute(
          path: AppRoutes.shootDetailPath,
          builder: (_, state) => ShootDetailScreen(
            jobId: state.pathParameters['jobId']!,
          ),
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
          isPremiumProvider.overrideWithValue(true),
          shootsRepositoryProvider.overrideWithValue(repository),
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

  testWidgets('shoots_list_polls_every_five_seconds_when_job_is_active', (
    tester,
  ) async {
    final repository = FakeShootsRepository();
    await pumpScreen(
      tester,
      const ShootsScreen(),
      repository,
    );
    final initialCalls = repository.getJobsCalls;

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(repository.getJobsCalls, initialCalls + 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('active_shoot_detail_polls_status_every_three_seconds', (
    tester,
  ) async {
    final repository = FakeShootsRepository();
    await pumpScreen(
      tester,
      const ShootDetailScreen(jobId: 'job-heels-processing'),
      repository,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(repository.getJobStatusCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('active_shoot_detail_refreshes_data_when_progress_changes', (
    tester,
  ) async {
    final repository = FakeShootsRepository();
    await pumpScreen(
      tester,
      const ShootDetailScreen(jobId: 'job-heels-processing'),
      repository,
    );
    final initialDetailCalls = repository.getJobCalls;
    final index = repository.jobs.indexWhere(
      (job) => job.id == 'job-heels-processing',
    );
    repository.jobs[index] = repository.jobs[index].copyWith(progress: .72);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(repository.getJobCalls, initialDetailCalls + 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('image_ai_edit_uses_app_dialog_footer_and_loading', (
    tester,
  ) async {
    final repository = _DelayedEditRepository();
    await pumpScreen(
      tester,
      const ShootDetailScreen(jobId: 'job-bag'),
      repository,
      physicalSize: const Size(1200, 1000),
    );

    await tester.ensureVisible(find.byIcon(Icons.auto_fix_high).first);
    await tester.tap(find.byIcon(Icons.auto_fix_high).first);
    await tester.pumpAndSettle();

    final dialog = tester.widget<AppDialog>(find.byType(AppDialog));
    expect(dialog.config.title, 'Edit with AI');
    expect(dialog.footer, isNotNull);
    final dialogImage = find.descendant(
      of: find.byType(AppDialog),
      matching: find.byType(AppImage),
    );
    expect(dialogImage, findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Edit with AI')).dy,
      lessThan(tester.getTopLeft(dialogImage).dy),
    );
    expect(
      tester
          .widget<PrimaryButton>(
            find.byKey(const ValueKey('ai-edit-submit')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Edit prompt'),
      'Remove the left shadow',
    );
    await tester.pump();
    expect(find.text('4 / 500 words'), findsOneWidget);
    final submitFinder = find.byKey(const ValueKey('ai-edit-submit'));
    tester.widget<PrimaryButton>(submitFinder).onPressed!();
    await tester.pump();

    expect(repository.lastEditPrompt, 'Remove the left shadow');
    expect(tester.widget<PrimaryButton>(submitFinder).isLoading, isTrue);
    expect(
      tester
          .widget<AppOutlinedButton>(
            find.widgetWithText(AppOutlinedButton, 'Cancel'),
          )
          .onPressed,
      isNull,
    );

    repository.completeEdit();
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsNothing);
  });

  testWidgets('image_quality_report_uses_app_footer_and_riverpod_loading', (
    tester,
  ) async {
    final repository = _DelayedReportRepository();
    await pumpScreen(
      tester,
      const ShootDetailScreen(jobId: 'job-bag'),
      repository,
      physicalSize: const Size(1200, 1000),
    );

    await tester.ensureVisible(find.byIcon(Icons.flag_outlined).last);
    await tester.tap(find.byIcon(Icons.flag_outlined).last);
    await tester.pumpAndSettle();

    final dialog = tester.widget<AppDialog>(find.byType(AppDialog));
    expect(dialog.footer, isNotNull);
    expect(find.byType(AppDialogActionFooter), findsOneWidget);
    expect(find.byKey(const ValueKey('report-reason-product')), findsOneWidget);
    expect(find.byKey(const ValueKey('report-reason-model')), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(AppTextField, 'What is wrong?'),
      'The product shape is broken around the shoulder.',
    );
    await tester.pump();
    final submitFinder = find.byKey(const ValueKey('report-image-submit'));
    await tester.ensureVisible(submitFinder);
    tester.widget<PrimaryButton>(submitFinder).onPressed!();
    await tester.pump();

    expect(repository.lastReportReason, 'product_deformed');

    final submitButton = tester.widget<PrimaryButton>(
      find.byKey(const ValueKey('report-image-submit')),
    );
    final cancelButton = tester.widget<AppOutlinedButton>(
      find.widgetWithText(AppOutlinedButton, 'Cancel'),
    );
    expect(submitButton.isLoading, isTrue);
    expect(cancelButton.onPressed, isNull);

    expect(
      repository.lastReportComment,
      'The product shape is broken around the shoulder.',
    );

    repository.completeReport();
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsNothing);
  });

  testWidgets('add_variation_submits_real_shot_index', (tester) async {
    final repository = FakeShootsRepository();
    await pumpScreen(
      tester,
      const ShootDetailScreen(jobId: 'job-bag'),
      repository,
    );

    await tester.ensureVisible(find.text('Add Variation').last);
    await tester.tap(find.text('Add Variation').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Extra remarks (optional)'),
      'Warmer light',
    );
    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();

    expect(repository.lastVariationShotIndex, 1);
  });

  testWidgets('completed_shoot_opens_all_image_action_dialogs', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const ShootDetailScreen(jobId: 'job-bag'),
      FakeShootsRepository(),
    );

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

    await tester.ensureVisible(find.text('Add Variation').first);
    await tester.tap(find.text('Add Variation').first);
    await tester.pumpAndSettle();
    expect(find.text('Add Variation'), findsWidgets);
    expect(
      find.text('Generated using current shoot settings.'),
      findsOneWidget,
    );
  });

  testWidgets('create_shoot_posts_plan_and_opens_created_job_route', (
    tester,
  ) async {
    final repository = FakeShootsRepository();
    final router = await pumpRouter(tester, repository);

    router.go(AppRoutes.createShoot);
    await tester.pumpAndSettle();
    for (final choice in ['Tan Leather Bag', 'Mila', 'Alex Chen']) {
      await selectCreateChoiceAndContinue(tester, choice);
    }
    await tester.tap(find.byKey(const ValueKey('plan-shoot-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Generate 5 Shots'));
    await tester.tap(find.text('Generate 5 Shots'));
    await tester.pumpAndSettle();

    expect(repository.planShotsCalls, 1);
    expect(repository.createShootCalls, 1);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.shootDetail('job-created'),
    );
  });
}

class _DelayedReportRepository extends FakeShootsRepository {
  final _reportCompleter = Completer<Result<void>>();

  @override
  Future<Result<void>> reportImage(
    String jobId,
    String imageId, {
    required String reason,
    required String comment,
  }) {
    lastReportReason = reason;
    lastReportComment = comment;
    return _reportCompleter.future;
  }

  void completeReport() => _reportCompleter.complete(const Result.ok(null));
}

class _DelayedEditRepository extends FakeShootsRepository {
  final _editCompleter = Completer<Result<void>>();

  @override
  Future<Result<void>> editImage(
    String jobId,
    String imageId,
    String prompt,
  ) {
    lastEditPrompt = prompt;
    return _editCompleter.future;
  }

  void completeEdit() => _editCompleter.complete(const Result.ok(null));
}
