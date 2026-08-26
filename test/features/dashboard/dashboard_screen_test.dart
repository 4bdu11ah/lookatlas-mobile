import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/dashboard_step_guide.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/studio_scene_animation.dart';
import 'package:look_atlas/features/shoots/di/shoots_providers.dart';
import 'package:look_atlas/features/shoots/domain/repositories/shoots_repository.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_shoots_repository.dart';
import '../../helpers/fake_welcome_repository.dart';

class _ConcurrentDashboardRepository implements DashboardRepository {
  final stats = Completer<Result<DashboardStats>>();
  final jobs = Completer<Result<List<DashboardRecentJob>>>();
  final subscription = Completer<Result<DashboardSubscription>>();
  int statsCalls = 0;
  int jobsCalls = 0;
  int subscriptionCalls = 0;

  @override
  Future<Result<DashboardStats>> getStats() {
    statsCalls++;
    return stats.future;
  }

  @override
  Future<Result<List<DashboardRecentJob>>> getRecentJobs() {
    jobsCalls++;
    return jobs.future;
  }

  @override
  Future<Result<DashboardSubscription>> getSubscription() {
    subscriptionCalls++;
    return subscription.future;
  }
}

void main() {
  Future<void> pumpDashboard(
    WidgetTester tester, {
    AppUser? user,
    DashboardRepository dashboardRepository = const FakeDashboardRepository(),
    FakeWelcomeRepository? welcomeRepository,
    ShootsRepository? shootsRepository,
    Map<String, Object> initialPreferences = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPreferences);
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          welcomeRepositoryProvider.overrideWithValue(
            welcomeRepository ?? FakeWelcomeRepository(),
          ),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user:
                  user ??
                  const AppUser(id: 'user-1', email: 'jane@example.com'),
            ),
          ),
          dashboardRepositoryProvider.overrideWithValue(dashboardRepository),
          shootsRepositoryProvider.overrideWithValue(
            shootsRepository ?? FakeShootsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders the page header and all four stat cards', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(find.text('Dashboard'), findsOneWidget);
    expect(
      find.text("Welcome back! Here's your Look Atlas overview."),
      findsOneWidget,
    );
    expect(find.text('CREDITS REMAINING'), findsOneWidget);
    expect(find.text('142'), findsOneWidget);
    expect(find.text('TOTAL RENDERS'), findsOneWidget);
    expect(find.text('386'), findsOneWidget);
    expect(find.text('ACTIVE SHOOTS'), findsOneWidget);
    expect(find.text('COMPLETED SHOOTS'), findsOneWidget);
  });

  testWidgets('mobile stats use the previous two-column grid', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await pumpDashboard(tester);

    final credits = tester.getTopLeft(find.text('CREDITS REMAINING'));
    final renders = tester.getTopLeft(find.text('TOTAL RENDERS'));
    final active = tester.getTopLeft(find.text('ACTIVE SHOOTS'));

    expect(credits.dy, renders.dy);
    expect(credits.dx, lessThan(renders.dx));
    expect(active.dy, greaterThan(credits.dy));
  });

  testWidgets('mobile loading stats use the same two-column grid', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final repository = _ConcurrentDashboardRepository();

    await pumpDashboard(tester, dashboardRepository: repository);

    final shimmerCards = find.descendant(
      of: find.byType(GridView).first,
      matching: find.byType(ShimmerBox),
    );
    expect(shimmerCards, findsNWidgets(4));
    final first = tester.getTopLeft(shimmerCards.at(0));
    final second = tester.getTopLeft(shimmerCards.at(1));
    final third = tester.getTopLeft(shimmerCards.at(2));

    expect(first.dy, second.dy);
    expect(first.dx, lessThan(second.dx));
    expect(third.dy, greaterThan(first.dy));
  });

  testWidgets('renders recent shoots with status chips and quick actions', (
    tester,
  ) async {
    await pumpDashboard(tester);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent Shoots'), findsOneWidget);
    expect(find.text('Tan Leather Bag'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Manage Models'), findsOneWidget);
    expect(find.text('Upload Products'), findsOneWidget);
    expect(find.text('Workshop'), findsOneWidget);
    expect(find.text('New Shoot'), findsOneWidget);
  });

  testWidgets('renders stats recent jobs and subscription state from APIs', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      dashboardRepository: const FakeDashboardRepository(
        stats: DashboardStats(
          credits: 80,
          creditsTotal: 100,
          creditsUsed: 20,
          totalRenders: 35,
          activeJobs: 2,
          completedJobs: 5,
        ),
        jobs: [
          DashboardRecentJob(
            id: 'job-api',
            name: 'API Product Shoot',
            status: 'completed',
            renders: 8,
            productThumbnail:
                'assets/images/onboarding/showcase-bag-before.jpg',
            modelThumbnail: 'assets/images/onboarding/showcase-dress-after.jpg',
          ),
        ],
        subscription: DashboardSubscription(
          status: 'active',
          cancelAtPeriodEnd: false,
          accessTier: 'onetime_download',
          proUpsellActive: true,
        ),
      ),
    );

    expect(find.text('80'), findsOneWidget);
    expect(find.text('35'), findsOneWidget);
    expect(find.text('API Product Shoot'), findsOneWidget);
    expect(
      find.text('Your limited-time Pro offer is available in Billing.'),
      findsOneWidget,
    );
  });

  testWidgets('starts all dashboard API requests in parallel', (tester) async {
    final repository = _ConcurrentDashboardRepository();

    await pumpDashboard(tester, dashboardRepository: repository);

    expect(repository.statsCalls, 1);
    expect(repository.jobsCalls, 1);
    expect(repository.subscriptionCalls, 1);

    repository.stats.complete(
      const Result.ok(
        DashboardStats(
          credits: 80,
          creditsTotal: 100,
          creditsUsed: 20,
          totalRenders: 35,
          activeJobs: 2,
          completedJobs: 5,
        ),
      ),
    );
    repository.jobs.complete(const Result.ok([]));
    repository.subscription.complete(
      const Result.ok(
        DashboardSubscription(
          status: 'active',
          cancelAtPeriodEnd: false,
          accessTier: 'subscriber',
          proUpsellActive: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('80'), findsOneWidget);
  });

  testWidgets('shows the signed-in user initial in the avatar', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      user: const AppUser(id: 'user-1', email: 'jane@example.com'),
    );

    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('avatar initial prefers the company name', (tester) async {
    await pumpDashboard(
      tester,
      user: const AppUser(
        id: 'user-1',
        email: 'jane@example.com',
        companyName: 'Metasense',
      ),
    );

    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('avatar opens the profile menu with credits and actions', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('J'));
    await tester.pumpAndSettle();

    expect(find.text('CREDITS'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('Billing & Credits'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // Tapping outside closes it again.
    await tester.tapAt(const Offset(250, 300));
    await tester.pumpAndSettle();
    expect(find.text('Account Settings'), findsNothing);
  });

  testWidgets('log out signs the user out via the profile menu', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AppUser(id: 'user-1', email: 'jane@example.com'),
    );
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          welcomeRepositoryProvider.overrideWithValue(
            FakeWelcomeRepository(),
          ),
          authRepositoryProvider.overrideWithValue(auth),
          // Sign-out detaches the identity from subscriptions; the real
          // repository needs platform channels.
          subscriptionRepositoryProvider.overrideWithValue(
            FakeSubscriptionRepository(),
          ),
          dashboardRepositoryProvider.overrideWithValue(
            const FakeDashboardRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('J'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 50));

    expect(auth.currentUser, isNull);
  });

  testWidgets('opens the navigation drawer from the menu button', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.byIcon(LucideIcons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Look Atlas'), findsWidgets);
    expect(find.text('Workshop'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-drawer-create')),
      findsNothing,
    );
    final support = find.byKey(
      const ValueKey('dashboard-drawer-support'),
    );
    final assistant = find.byKey(
      const ValueKey('dashboard-drawer-assistant'),
    );
    final school = find.byKey(const ValueKey('dashboard-drawer-school'));
    final settings = find.byKey(
      const ValueKey('dashboard-drawer-settings'),
    );
    expect(school, findsOneWidget);
    expect(assistant, findsOneWidget);
    expect(
      tester.getTopLeft(support).dy,
      lessThan(tester.getTopLeft(school).dy),
    );
    expect(
      tester.getTopLeft(school).dy,
      lessThan(tester.getTopLeft(assistant).dy),
    );
    expect(
      tester.getTopLeft(assistant).dy,
      lessThan(tester.getTopLeft(settings).dy),
    );
    expect(
      find.byKey(const ValueKey('dashboard-drawer-surface')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('dashboard-drawer-content')),
          )
          .transform
          .getTranslation()
          .x,
      greaterThan(0),
    );

    await tester.tap(
      find.byKey(const ValueKey('dashboard-drawer-scrim')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('drawer supports edge swipe opening and closing', (tester) async {
    await pumpDashboard(tester);

    final openingGesture = await tester.startGesture(const Offset(2, 320));
    await openingGesture.moveBy(const Offset(75, 0));
    await tester.pump();
    await openingGesture.moveBy(const Offset(75, 0));
    await tester.pump();
    await openingGesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('dashboard-drawer-scrim')),
      const Offset(-230, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('shows stats before slower dashboard sections complete', (
    tester,
  ) async {
    final repository = _ConcurrentDashboardRepository();
    await pumpDashboard(tester, dashboardRepository: repository);

    repository.stats.complete(
      const Result.ok(
        DashboardStats(
          credits: 80,
          creditsTotal: 100,
          creditsUsed: 20,
          totalRenders: 35,
          activeJobs: 2,
          completedJobs: 5,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('80'), findsOneWidget);
    expect(find.byType(BarSpinner), findsOneWidget);

    repository.jobs.complete(const Result.ok([]));
    repository.subscription.complete(
      const Result.ok(
        DashboardSubscription(
          status: 'active',
          cancelAtPeriodEnd: false,
          accessTier: 'subscriber',
          proUpsellActive: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows and locally dismisses the Studio School helper', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(),
      ),
    );

    expect(
      find.text('New to Look Atlas? Start at Studio School.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Dismiss Studio School suggestion'));
    await tester.pump();

    expect(
      find.text('New to Look Atlas? Start at Studio School.'),
      findsNothing,
    );
  });

  testWidgets('subscriber_setup_rendersBeforeDashboardStatsAndCollapses', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(),
        ),
      ),
    );

    final hero = find.byKey(const ValueKey('dashboard-studio-setup'));
    final stats = find.text('CREDITS REMAINING');
    expect(hero, findsOneWidget);
    expect(find.text('Studio setup: 3 of 6'), findsNothing);
    expect(tester.getTopLeft(hero).dy, lessThan(tester.getTopLeft(stats).dy));

    await tester.tap(find.byTooltip('Collapse studio setup'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('dashboard-welcome-collapsed')),
      findsOneWidget,
    );
  });

  testWidgets('subscriber_helpers_dismissIndependently', (tester) async {
    await pumpDashboard(
      tester,
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('dashboard-consult-helper')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('studio-school-dashboard-helper')),
      findsOneWidget,
    );

    final dismissConsult = find.byTooltip(
      'Dismiss onboarding call suggestion',
    );
    await tester.ensureVisible(dismissConsult);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(dismissConsult);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('dashboard-consult-helper')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('studio-school-dashboard-helper')),
      findsOneWidget,
    );
  });

  testWidgets('showMe_opensGuideWithoutCompletingChecklistStep', (
    tester,
  ) async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(
        dashboard: fakeDashboardWelcomeState(completed: 0),
      ),
    );
    await pumpDashboard(tester, welcomeRepository: repository);

    final showMe = find.text('SHOW ME').first;
    await tester.ensureVisible(showMe);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(showMe);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Add your product'), findsWidgets);
    expect(find.text('Go to Products'), findsOneWidget);
    expect(repository.events, isEmpty);
    expect(repository.currentState.dashboard?.completedCount, 0);

    await tester.tap(find.byTooltip('Close guide'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(DashboardStepGuideDialog), findsNothing);
  });

  testWidgets('completed_checklist_preservesCampaignUntilFlipDismissal', (
    tester,
  ) async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(
        rewardClaimedAt: DateTime(2026, 8, 17),
        dashboard: fakeDashboardWelcomeState(
          completed: 6,
          rewardClaimedAt: DateTime(2026, 8, 17),
          campaign: const DashboardWelcomeCampaign(
            jobId: 'job-bag',
            keptImages: 1,
            images: [],
          ),
        ),
      ),
    );
    await pumpDashboard(tester, welcomeRepository: repository);

    expect(
      find.byKey(const ValueKey('dashboard-campaign-hero')),
      findsOneWidget,
    );
    final dismiss = find.text("I'm all set, hide this");
    await tester.ensureVisible(dismiss);
    await tester.tap(dismiss);
    await tester.pump();

    expect(find.byKey(const ValueKey('dashboard-campaign-hero')), findsNothing);
    final welcomeBottom = tester.getBottomLeft(
      find.text("Welcome back! Here's your Look Atlas overview."),
    );
    final statsTop = tester.getTopLeft(find.byType(GridView).first);
    expect(statsTop.dy - welcomeBottom.dy, lessThan(40));
    expect(repository.events, contains('welcome.flip_dismissed'));
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool('la_welcome_flip_dismissed:user-1'),
      isTrue,
    );
  });

  testWidgets('completedChecklist_withoutJob_showsRewardOnlyState', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(completed: 6),
        ),
      ),
    );

    expect(find.text('Your studio is built.'), findsOneWidget);
    expect(find.text('Claim 20 credits'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-campaign-hero')),
      findsNothing,
    );
  });

  testWidgets('completedJob_loadsSpecificShootAndKeepsNativeSceneMounted', (
    tester,
  ) async {
    final shoots = FakeShootsRepository();
    await pumpDashboard(
      tester,
      shootsRepository: shoots,
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(
            completed: 6,
            campaign: const DashboardWelcomeCampaign(
              jobId: 'job-bag',
              keptImages: 1,
              images: [],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(shoots.lastJobId, 'job-bag');
    expect(find.byType(StudioSceneAnimation), findsOneWidget);
    expect(
      find.text('Studio built. Claim your 20 free credits'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('image-1')), findsOneWidget);
  });

  testWidgets('campaignClaim_revealsRetirementOnlyAfterRefresh', (
    tester,
  ) async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(
        dashboard: fakeDashboardWelcomeState(
          completed: 6,
          campaign: const DashboardWelcomeCampaign(
            jobId: 'job-bag',
            keptImages: 1,
            images: [],
          ),
        ),
      ),
    );
    await pumpDashboard(tester, welcomeRepository: repository);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("I'm all set, hide this"), findsNothing);
    final claim = find.text('Studio built. Claim your 20 free credits');
    await tester.ensureVisible(claim);
    await tester.tap(claim);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.checklistClaimCalls, 1);
    expect(find.text("I'm all set, hide this"), findsOneWidget);
  });

  testWidgets('campaignApproval_refreshDoesNotRestartStudioAnimation', (
    tester,
  ) async {
    final shoots = FakeShootsRepository();
    await pumpDashboard(
      tester,
      shootsRepository: shoots,
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(
            completed: 6,
            rewardClaimedAt: DateTime(2026, 8, 17),
            campaign: const DashboardWelcomeCampaign(
              jobId: 'job-bag',
              keptImages: 1,
              images: [],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final animationState = tester.state(find.byType(StudioSceneAnimation));

    final image = find.byKey(const ValueKey('image-2'));
    await tester.ensureVisible(image);
    await tester.tap(image);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(shoots.approvalCalls, contains(('job-bag', 'image-2', true)));
    expect(
      identical(
        animationState,
        tester.state(find.byType(StudioSceneAnimation)),
      ),
      isTrue,
    );
  });

  testWidgets('oneTimeBuyer_showsDownloadAndUpsellHero', (tester) async {
    await pumpDashboard(
      tester,
      dashboardRepository: const FakeDashboardRepository(
        subscription: DashboardSubscription(
          status: 'active',
          cancelAtPeriodEnd: false,
          accessTier: 'onetime_download',
          proUpsellActive: true,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('dashboard-onetime-hero')),
      findsOneWidget,
    );
    expect(find.text('Your photos. Yours forever.'), findsOneWidget);
    expect(find.text('Claim 20% off'), findsOneWidget);
  });

  testWidgets('returningSubscriber_startsWithCollapsedSetup', (tester) async {
    await pumpDashboard(
      tester,
      initialPreferences: const {'la_welcome_seen:user-1': true},
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('dashboard-welcome-collapsed')),
      findsOneWidget,
    );
  });

  testWidgets('stuckStep_afterTenMinutes_showsRescueCopy', (tester) async {
    final startedAt = DateTime.now()
        .subtract(const Duration(minutes: 11))
        .toIso8601String();
    await pumpDashboard(
      tester,
      initialPreferences: {
        'la_welcome_step_started:user-1': 'step:model|$startedAt',
      },
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Stuck? We'll set it up with you."), findsOneWidget);
  });

  testWidgets('zeroKeepers_afterTenMinutes_showsCampaignRescue', (
    tester,
  ) async {
    final startedAt = DateTime.now()
        .subtract(const Duration(minutes: 11))
        .toIso8601String();
    await pumpDashboard(
      tester,
      initialPreferences: {
        'la_welcome_zero_keepers_started:user-1': 'zero:job-bag|$startedAt',
      },
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(
            completed: 6,
            campaign: const DashboardWelcomeCampaign(
              jobId: 'job-bag',
              keptImages: 0,
              images: [],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Free 30 minutes'), findsOneWidget);
  });

  testWidgets('completeChecklist_claimsRewardThroughWelcomeApi', (
    tester,
  ) async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(
        dashboard: fakeDashboardWelcomeState(completed: 6),
      ),
    );
    await pumpDashboard(tester, welcomeRepository: repository);

    final claim = find.text('Claim 20 credits');
    await tester.ensureVisible(claim);
    await tester.tap(claim);
    await tester.pump();

    expect(repository.checklistClaimCalls, 1);
  });

  testWidgets('incompleteProfile_showsHeaderAction', (tester) async {
    await pumpDashboard(
      tester,
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(profileIncomplete: true),
        ),
      ),
    );

    expect(find.text('Complete profile'), findsOneWidget);
  });

  testWidgets('subscriberSetup_390px_rendersWithoutOverflow', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await pumpDashboard(
      tester,
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('dashboard-studio-setup')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Studio setup illustration, 3 of 6 steps complete',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('studio-setup-motion-gif')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('profileAction_320px_rendersWithoutOverflow', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.reset);

    await pumpDashboard(
      tester,
      welcomeRepository: FakeWelcomeRepository(
        state: fakeEligibleWelcomeState(
          dashboard: fakeDashboardWelcomeState(profileIncomplete: true),
        ),
      ),
    );

    expect(find.text('Complete profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
