import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/connectivity/connectivity_provider.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/calendar/di/calendar_providers.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/guides/presentation/guides_feature.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/presentation/screens/studio_school_screen.dart';
import 'package:look_atlas/features/support/di/support_providers.dart';
import 'package:look_atlas/features/support/presentation/support_feature.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';
import 'package:look_atlas/services/service_providers.dart';

import 'fake_support_repository.dart';
import 'fake_welcome_repository.dart';

Future<void> pumpLearningCenter(
  WidgetTester tester, {
  required FakeWelcomeRepository repository,
  FakeSupportRepository? supportRepository,
  String initialLocation = '/school',
  Size size = const Size(390, 844),
  bool online = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/school', builder: (_, _) => const StudioSchoolScreen()),
      GoRoute(
        path: '/guides',
        builder: (_, state) =>
            GuidesScreen(initialTab: state.uri.queryParameters['tab']),
      ),
      GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
      for (final path in [
        '/',
        '/products',
        '/models',
        '/create',
        '/billing',
        '/workshop',
        '/shoots',
        '/calendar',
        '/create-content',
        '/settings',
        '/account',
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('Destination $path')),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AsyncData(
            AppUser(
              id: 'user-1',
              email: 'jane@example.com',
              companyName: 'Acme Studios',
            ),
          ),
        ),
        welcomeRepositoryProvider.overrideWithValue(repository),
        supportRepositoryProvider.overrideWithValue(
          supportRepository ?? FakeSupportRepository(),
        ),
        connectionStatusProvider.overrideWithValue(online),
        dashboardStatsProvider.overrideWith(
          (ref) async => const DashboardStats(
            credits: 1250,
            creditsTotal: 1500,
            creditsUsed: 250,
            totalRenders: 10,
            activeJobs: 1,
            completedJobs: 2,
          ),
        ),
        calendarAttentionProvider.overrideWith((ref) async => 0),
        analyticsServiceProvider.overrideWithValue(NoopAnalyticsService()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
