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
import 'package:look_atlas/features/splash/presentation/screens/splash_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/shared/widgets/look_atlas_loader.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    AppUser? user,
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
          (ref) =>
              Future.error(StateError('Status unavailable in splash test')),
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

  testWidgets('hands off to home when signed in', (tester) async {
    await pumpApp(
      tester,
      user: const AppUser(id: 'user-1', email: 'jane@example.com'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
