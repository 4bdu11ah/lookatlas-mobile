import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_router.dart';
import 'package:look_atlas/features/ai/presentation/screens/chat_screen.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:look_atlas/features/home/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/presentation/screens/paywall_screen.dart';

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
    testWidgets('sign-in with a valid from follows the deep link', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/sign-in?from=/chat');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/chat');
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('sign-in with a missing from falls back to home', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/sign-in');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/');
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('sign-in with a non-path from falls back to home', (
      tester,
    ) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/sign-in?from=https%3A%2F%2Fevil.example');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/');
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('protected path renders without a redirect', (tester) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/chat');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/chat');
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('paywall stays reachable when signed in', (tester) async {
      final router = await pumpRouter(tester, user: user);

      router.go('/paywall');
      await tester.pumpAndSettle();

      expect(currentUri(router).path, '/paywall');
      expect(find.byType(PaywallScreen), findsOneWidget);
    });
  });
}
