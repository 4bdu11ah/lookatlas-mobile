import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/welcome_profile/presentation/welcome_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_welcome_repository.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'jane@example.com');

  Future<(FakeWelcomeRepository, SharedPreferences)> pumpFlow(
    WidgetTester tester, {
    DashboardWelcomeProfile profile = const DashboardWelcomeProfile(),
    Duration entranceElapsed = const Duration(milliseconds: 300),
    bool reduceMotion = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(
        dashboard: fakeDashboardWelcomeState(
          profileIncomplete: true,
          profileFullyEmpty: profile.isFullyEmpty,
        ).copyWith(profile: profile),
      ),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.welcome,
      routes: [
        GoRoute(
          path: AppRoutes.welcome,
          builder: (_, _) => const WelcomeProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('Dashboard home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: user),
          ),
          welcomeRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
    if (entranceElapsed > Duration.zero) {
      await tester.pump(entranceElapsed);
    } else {
      await tester.pump();
    }
    return (repository, preferences);
  }

  testWidgets('directorPrints_arriveFromBothSidesAtTheCenteredPile', (
    tester,
  ) async {
    await pumpFlow(tester, entranceElapsed: Duration.zero);

    double translationFor(int index) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byKey(ValueKey('director-print-$index')),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[12];

    expect(translationFor(0), lessThan(-300));
    expect(translationFor(2), greaterThan(300));

    await tester.pump(const Duration(milliseconds: 800));

    expect(translationFor(0), closeTo(0, .01));
    expect(translationFor(2), closeTo(0, .01));
  });

  testWidgets('directorPrints_doNotReplayWhenProfileStateChanges', (
    tester,
  ) async {
    await pumpFlow(tester);
    await tester.pump(const Duration(milliseconds: 800));

    await tester.enterText(find.byType(TextField).first, 'example.com');
    await tester.pump();

    for (final index in [0, 2]) {
      final translation = tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byKey(ValueKey('director-print-$index')),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[12];
      expect(translation, closeTo(0, .01));
    }
  });

  testWidgets('directorPrints_respectReducedMotion', (tester) async {
    await pumpFlow(
      tester,
      reduceMotion: true,
      entranceElapsed: Duration.zero,
    );

    for (final index in [0, 2]) {
      final translation = tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byKey(ValueKey('director-print-$index')),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[12];
      expect(translation, closeTo(0, .01));
    }
  });

  testWidgets('brandField_doesNotAutofocusOnScreenOpen', (tester) async {
    await pumpFlow(tester);

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.focusNode?.hasFocus, isFalse);
  });

  testWidgets('savedProfile_prefillsTheFourStepFlow', (tester) async {
    await pumpFlow(
      tester,
      profile: const DashboardWelcomeProfile(
        brandUrl: 'shop.example.com',
        vertical: 'Jewelry',
        primaryUses: ['ads'],
        dropCadence: 'ongoing_drops',
        referral: 'google',
      ),
    );

    expect(find.text('shop.example.com'), findsOneWidget);
    expect(find.text('Jewelry'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 4'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('completeFlow_recordsEventBeforeSavingAndReplacesDashboard', (
    tester,
  ) async {
    final (repository, preferences) = await pumpFlow(tester);

    await tester.enterText(
      find.byType(TextField).first,
      ' HTTPS://WWW.ETSY.COM/Shop/Atlas/// ',
    );
    await tester.enterText(find.byType(TextField).at(1), 'Jewelry');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.ensureVisible(find.text('Ads'));
    await tester.pump();
    await tester.tap(find.text('Ads'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.ensureVisible(find.text('Ongoing drops'));
    await tester.pump();
    await tester.tap(find.text('Ongoing drops'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.ensureVisible(find.text('Google'));
    await tester.pump();
    await tester.tap(find.text('Google'));
    await tester.pump();
    await tester.tap(find.text('Enter your studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Dashboard home'), findsOneWidget);
    expect(repository.operations, [
      'event:welcome.intro_completed',
      'save_profile',
    ]);
    expect(repository.savedProfile?['brandUrl'], 'etsy.com/shop/atlas');
    expect(preferences.getBool('la_welcome_intro_done:user-1'), isTrue);
  });

  testWidgets('skipFromPartialFlow_doesNotSubmitLocalAnswers', (tester) async {
    final (repository, preferences) = await pumpFlow(tester);

    await tester.enterText(find.byType(TextField).first, 'example.com');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Skip for now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Dashboard home'), findsOneWidget);
    expect(repository.saveProfileCalls, 0);
    expect(repository.events, ['welcome.intro_skipped']);
    expect(preferences.getBool('la_welcome_intro_done:user-1'), isTrue);
  });
}
