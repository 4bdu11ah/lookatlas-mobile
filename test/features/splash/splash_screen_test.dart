import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/router/app_router.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/activate_paywall_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:look_atlas/features/splash/presentation/screens/splash_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/shared/widgets/look_atlas_loader.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    AppUser? user,
    OnboardingStatus onboardingStatus = const OnboardingStatus(
      freeShootUsed: false,
      onboardingImages: [],
      hasCalibration: false,
    ),
  }) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: user),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
        dashboardRepositoryProvider.overrideWithValue(
          const FakeDashboardRepository(),
        ),
        onboardingStatusProvider.overrideWith(
          (ref) async => onboardingStatus,
        ),
        onboardingProductsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: container.read(routerProvider)),
      ),
    );
  }

  testWidgets('shows the particle wordmark loader at launch', (tester) async {
    await pumpApp(tester);
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LookAtlasLoader), findsOneWidget);
  });

  testWidgets('hands off to sign-in when signed out', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('sends a new signed-in user to onboarding', (tester) async {
    await pumpApp(
      tester,
      user: const AppUser(id: 'user-1', email: 'jane@example.com'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingWizardScreen), findsOneWidget);
  });

  testWidgets('sends a subscriber to dashboard', (tester) async {
    await pumpApp(
      tester,
      user: const AppUser(id: 'user-1', email: 'jane@example.com'),
      onboardingStatus: const OnboardingStatus(
        freeShootUsed: true,
        onboardingImages: [],
        hasCalibration: false,
        subscriptionStatus: 'active',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('sends a used free-shoot account to the plan screen', (
    tester,
  ) async {
    await pumpApp(
      tester,
      user: const AppUser(id: 'user-1', email: 'jane@example.com'),
      onboardingStatus: const OnboardingStatus(
        freeShootUsed: true,
        onboardingImages: [],
        hasCalibration: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActivatePaywallScreen), findsOneWidget);
  });
}
