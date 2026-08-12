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
import 'package:look_atlas/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_repositories.dart';
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
  }) async {
    SharedPreferences.setMockInitialValues({});
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

    await tester.tap(find.byIcon(Icons.menu));
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
    final school = find.byKey(const ValueKey('dashboard-drawer-school'));
    final settings = find.byKey(
      const ValueKey('dashboard-drawer-settings'),
    );
    expect(school, findsOneWidget);
    expect(
      tester.getTopLeft(support).dy,
      lessThan(tester.getTopLeft(school).dy),
    );
    expect(
      tester.getTopLeft(school).dy,
      lessThan(tester.getTopLeft(settings).dy),
    );
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
}
