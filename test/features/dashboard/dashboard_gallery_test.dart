import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_overview_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_overview_screen.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_collection.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_rooms.dart';

const _credits = DashboardStats(
  credits: 240,
  creditsTotal: 400,
  creditsUsed: 160,
  totalRenders: 0,
  activeJobs: 1,
  completedJobs: 1,
);
const _product = DashboardCollectionItem(
  id: 'product',
  name: 'Merino Cardigan',
  thumbnail: 'assets/images/onboarding/showcase-tshirt-before.jpg',
  description: 'KNT-804 • Knitwear',
);
const _model = DashboardCollectionItem(
  id: 'model',
  name: 'Elena R.',
  featured: true,
  thumbnail: 'assets/images/onboarding/showcase-dress-after.jpg',
  description: '178 cm • Editorial',
);

class _Controller extends DashboardOverviewController {
  _Controller(this.initial);
  final DashboardOverviewState initial;
  int refreshes = 0;
  @override
  DashboardOverviewState build() => initial;
  @override
  Future<void> refresh({bool background = true}) async {
    refreshes++;
  }
}

void main() {
  late GoRouter router;
  late _Controller controller;
  Future<void> pump(
    WidgetTester tester,
    DashboardOverviewState state, {
    double width = 390,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = Size(width, 844);
    addTearDown(tester.view.reset);
    controller = _Controller(state);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            backgroundColor: const Color(0xFFFFFEFA),
            body: DashboardOverviewScreen(onNavigate: (_) {}),
          ),
        ),
        for (final route in [
          AppRoutes.createShoot,
          AppRoutes.dashboardProducts,
          AppRoutes.dashboardModels,
          AppRoutes.dashboardShoots,
          AppRoutes.createContent,
          AppRoutes.studioSchool,
        ])
          GoRoute(
            path: route,
            builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
          ),
        GoRoute(
          path: AppRoutes.shootDetailPath,
          builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardOverviewControllerProvider.overrideWith(() => controller),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  DashboardOverviewState ready({
    DashboardActivationStage stage = DashboardActivationStage.active,
    DashboardPanelStatus panels = const DashboardPanelStatus(),
    DashboardActivity? activity,
    bool stale = false,
  }) => DashboardOverviewState(
    isLoading: false,
    isStale: stale,
    overview: DashboardOverview(
      credits: _credits,
      activation: DashboardActivation(stage: stage, firstShootId: 'first'),
      products: const DashboardCollection(total: 14, items: [_product]),
      models: const DashboardCollection(
        title: 'Your models',
        total: 8,
        items: [_model],
      ),
      panelStatus: panels,
      activity:
          activity ??
          const DashboardActivity(
            activeCount: 1,
            readyCount: 1,
            ready: [
              DashboardRecentJob(
                id: 'ready',
                name: 'Ready campaign',
                status: 'completed',
                renders: 12,
                productThumbnail: '',
                modelThumbnail: '',
              ),
            ],
            active: [
              DashboardRecentJob(
                id: 'live',
                name: 'Live campaign',
                status: 'processing',
                renders: 0,
                productThumbnail: '',
                modelThumbnail: '',
                progress: 65,
                currentStep: 'Step 2/4',
              ),
            ],
          ),
    ),
  );
  testWidgets('overview_emptyActivity_showsOnlyStartShootAction', (
    tester,
  ) async {
    await pump(
      tester,
      ready(activity: const DashboardActivity()),
    );

    expect(find.text('Start a shoot'), findsOneWidget);
    expect(find.text('Needs attention'), findsNothing);
    expect(find.text('View all'), findsNothing);
    expect(find.text('No shoots need your attention.'), findsNothing);
    expect(
      find.text('Your studio is clear for a new production.'),
      findsNothing,
    );
  });
  for (final stage in DashboardActivationStage.values) {
    testWidgets('overview_${stage.name}_primaryActionUsesCorrectDestination', (
      tester,
    ) async {
      await pump(tester, ready(stage: stage));
      final label = DashboardActivation(stage: stage).actionLabel;
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      final expected = switch (stage) {
        DashboardActivationStage.setup => '/products?create=1',
        DashboardActivationStage.generating ||
        DashboardActivationStage.ready => '/shoots/first?from=dashboard',
        DashboardActivationStage.active => '/create',
      };
      expect(find.text(expected), findsOneWidget);
    });
  }
  testWidgets('overview_activityOutage_retryLeavesCollectionAvailable', (
    tester,
  ) async {
    await pump(
      tester,
      ready(panels: const DashboardPanelStatus(activityError: true)),
    );
    expect(
      find.text('Shoot activity is temporarily unavailable.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(controller.refreshes, 1);
    await tester.scrollUntilVisible(
      find.byType(OverviewCollection),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('dashboard-add-product')), findsOneWidget);
  });
  testWidgets('overview_productsOutage_modelPreviewRemainsAvailable', (
    tester,
  ) async {
    await pump(
      tester,
      ready(panels: const DashboardPanelStatus(productsError: true)),
    );
    await tester.scrollUntilVisible(
      find.byType(OverviewCollection),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Product previews are temporarily unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Elena R.'), findsOneWidget);
    final model = find.byKey(const ValueKey('dashboard-model-model'));
    await tester.ensureVisible(model);
    await tester.pumpAndSettle();
    await tester.tap(model);
    await tester.pumpAndSettle();
    expect(find.text('Close model preview'), findsNothing);
    expect(find.byTooltip('Close model preview'), findsOneWidget);
    expect(find.text('178 cm • Editorial'), findsWidgets);
  });
  testWidgets('overview_initialOutage_rendersPageRetry', (tester) async {
    await pump(
      tester,
      const DashboardOverviewState(
        isLoading: false,
        failure: NetworkFailure('Offline'),
      ),
    );
    expect(find.text('Your workspace did not load.'), findsOneWidget);
    expect(find.text('STUDIO ACTIVITY'), findsNothing);
    await tester.tap(find.text('Try again'));
    expect(controller.refreshes, 1);
  });
  testWidgets('overview_staleRefresh_retainsActivityAndShowsReload', (
    tester,
  ) async {
    await pump(tester, ready(stale: true));
    expect(
      find.text(
        'Some dashboard information may be out of date. Network latency detected.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ready campaign'), findsOneWidget);
    await tester.tap(find.text('Reload'));
    expect(controller.refreshes, 1);
  });
  for (final width in [320.0, 390.0, 430.0]) {
    testWidgets('overview_${width.toInt()}px_completeGalleryHasNoOverflow', (
      tester,
    ) async {
      await pump(tester, ready(), width: width);
      for (var index = 0; index < 22; index++) {
        await tester.drag(
          find.byKey(const ValueKey('dashboard-overview-scroll')),
          const Offset(0, -260),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Explore learning'), findsOneWidget);
      expect(find.byType(OverviewComingSoon), findsWidgets);
    });
  }
}
