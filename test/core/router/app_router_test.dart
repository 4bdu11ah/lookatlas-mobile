import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:look_atlas/features/workshop/presentation/screens/workshop_screen.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'jane@example.com');

  /// Builds the real app router against a fake auth session and pumps it.
  Future<GoRouter> pumpRouter(WidgetTester tester, {AppUser? user}) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: user),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
        onboardingStatusProvider.overrideWith(
          (ref) =>
              Future.error(StateError('Status unavailable in router test')),
        ),
        onboardingProductsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Uri currentUri(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri;

  group('logged out', () {
    testWidgets(
      'protected path redirects to sign-in preserving the deep link',
      (tester) async {
        final router = await pumpRouter(tester);

        router.go('/chat');
        await tester.pumpAndSettle();

        final uri = currentUri(router);
        expect(uri.path, '/sign-in');
        expect(uri.queryParameters['from'], '/chat');
        expect(find.byType(SignInScreen), findsOneWidget);
      },
    );

    testWidgets('public path is reachable without a redirect', (tester) async {
      final router = await pumpRouter(tester);

      router.go('/reset-password');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/reset-password');
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });

    testWidgets('onboarding redirects to sign-in', (tester) async {
      final router = await pumpRouter(tester);

      router.go(AppRoutes.onboarding);
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.signIn);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('paywall is public so anonymous users can purchase', (
      tester,
    ) async {
      final router = await pumpRouter(tester);

      router.go('/paywall');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/paywall');
      expect(find.byType(PaywallScreen), findsOneWidget);
    });
  });

  group('logged in', () {
    testWidgets('sign-in with a missing from opens onboarding', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/sign-in');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.onboarding);
      expect(find.byType(OnboardingWizardScreen), findsOneWidget);
    });

    testWidgets('sign-in with a non-path from opens onboarding', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/sign-in?from=https%3A%2F%2Fevil.example');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.onboarding);
      expect(find.byType(OnboardingWizardScreen), findsOneWidget);
    });

    testWidgets('paywall stays reachable when signed in', (tester) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/paywall');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/paywall');
      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('dashboard feature paths render the matching section', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      final cases = {
        AppRoutes.dashboardShoots: 'Shoots',
        AppRoutes.shootDetail: 'Tan Leather Bag',
        AppRoutes.dashboardProducts: 'Products',
        AppRoutes.dashboardModels: 'House Models',
        AppRoutes.dashboardBilling: 'Billing',
        AppRoutes.dashboardAccount: 'Settings',
        AppRoutes.dashboardSupport: 'Support',
        AppRoutes.dashboardGuides: 'Guides',
      };

      for (final entry in cases.entries) {
        router.go(entry.key);
        await tester.pumpAndSettle();

        expect(currentUri(router).path, entry.key);
        if (entry.key == AppRoutes.shootDetail) {
          expect(find.byType(ShootDetailScreen), findsOneWidget);
          expect(find.byType(DashboardFeatureScreen), findsNothing);
        } else {
          expect(find.byType(DashboardFeatureScreen), findsOneWidget);
        }
        expect(find.byType(Drawer), findsNothing);
        expect(find.byIcon(Icons.menu), findsNothing);
        expect(find.byType(CustomAppBar), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(CustomAppBar),
            matching: find.byIcon(Icons.arrow_back),
          ),
          findsOneWidget,
        );
        expect(find.text(entry.value), findsWidgets);
      }
    });

    testWidgets('create shoot path renders its standalone screen', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.createShoot);
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.createShoot);
      expect(find.byType(CreateShootScreen), findsOneWidget);
      expect(find.byType(DashboardFeatureScreen), findsNothing);
      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('Create Shoot'), findsWidgets);
    });

    testWidgets('workshop route renders as a standalone feature', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.workshop);
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.workshop);
      expect(find.byType(WorkshopScreen), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(
        find.textContaining('Reshape any photo with a sentence'),
        findsOneWidget,
      );
    });

    testWidgets('workshop guide opens and returns through GoRouter', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.workshop);
      await tester.pumpAndSettle();
      await tester.tap(find.text('HOW DOES THIS WORK?'));
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.workshopGuide);
      expect(find.byType(WorkshopGuideScreen), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('One image, one prompt, one credit.'), findsOneWidget);

      final restyle = find.text('Restyle a product');
      for (var i = 0; i < 5 && restyle.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(restyle, findsOneWidget);

      final gotIt = find.text('Got it', skipOffstage: false);
      await tester.scrollUntilVisible(
        gotIt,
        600,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.workshop);
      expect(find.byType(WorkshopScreen), findsOneWidget);
    });

    testWidgets('dashboard actions navigate through GoRouter paths', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to Models'));
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.dashboardModels);
      expect(find.text('House Models'), findsOneWidget);
    });

    testWidgets('guide actions navigate to their app routes', (tester) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.dashboardGuides);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('guide-tab-productPhotos')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Go to Products'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to Products'));
      await tester.pumpAndSettle();

      expect(currentUri(router).path, AppRoutes.dashboardProducts);
      expect(find.text('Products'), findsWidgets);
    });

    testWidgets('drawer pushes feature routes so back returns to dashboard', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dashboard-drawer-models')));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(find.byType(DashboardFeatureScreen), findsOneWidget);
      expect(find.text('House Models'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
