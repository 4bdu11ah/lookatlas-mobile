import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/connectivity/connectivity_provider.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_screen.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';
import 'package:look_atlas/services/service_providers.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_welcome_repository.dart';

void main() {
  Future<void> pumpSchool(
    WidgetTester tester, {
    required FakeWelcomeRepository repository,
    bool online = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(id: 'user-1', email: 'jane@example.com'),
            ),
          ),
          welcomeRepositoryProvider.overrideWithValue(repository),
          analyticsServiceProvider.overrideWithValue(NoopAnalyticsService()),
          connectionStatusProvider.overrideWithValue(online),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StudioSchoolScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
  }

  testWidgets('screen_readOnly_keepsLessonsReadableWithoutReward', (
    tester,
  ) async {
    await pumpSchool(tester, repository: FakeWelcomeRepository());

    expect(find.text('Studio School'), findsOneWidget);
    expect(find.text('Learn without tracked progress'), findsOneWidget);
    expect(find.text('How credits work'), findsOneWidget);
    expect(find.byKey(const ValueKey('studio-school-claim')), findsNothing);
  });

  testWidgets('drawer_placesStudioSchoolImmediatelyAfterSupport', (
    tester,
  ) async {
    await pumpSchool(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    final support = find.byKey(const ValueKey('school-drawer-/support'));
    final school = find.byKey(const ValueKey('school-drawer-/school'));
    final settings = find.byKey(const ValueKey('school-drawer-/account'));
    expect(
      tester.getTopLeft(support).dy,
      lessThan(tester.getTopLeft(school).dy),
    );
    expect(
      tester.getTopLeft(school).dy,
      lessThan(tester.getTopLeft(settings).dy),
    );
    expect(find.text('Guides'), findsNothing);
  });

  testWidgets('lessonPlayer_creditLesson_showsCalculatorAndCompletes', (
    tester,
  ) async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(),
    );
    await pumpSchool(tester, repository: repository);

    await tester.tap(find.text('How credits work'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Quick math'), findsOneWidget);
    expect(
      find.textContaining('Starter example, standard: 15 credits'),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('studio-school-done')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('Lesson done.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1201));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.completeCalls, 1);
    expect(find.text('Lesson done.'), findsNothing);
  });

  testWidgets('reward_allLessonsComplete_claimsServerReward', (tester) async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(
        completed: WelcomeLessonId.values.toSet(),
      ),
    );
    await pumpSchool(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('studio-school-claim')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(repository.claimCalls, 1);
    expect(find.text('20 free credits added.'), findsOneWidget);
  });

  testWidgets('lessonPlayer_offline_disablesTrackedCompletion', (
    tester,
  ) async {
    await pumpSchool(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
      online: false,
    );

    await tester.tap(find.text('How credits work'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Reconnect to save lesson progress.'), findsOneWidget);
    final done = tester.widget<FilledButton>(
      find.byKey(const ValueKey('studio-school-done')),
    );
    expect(done.onPressed, isNull);
  });
}
