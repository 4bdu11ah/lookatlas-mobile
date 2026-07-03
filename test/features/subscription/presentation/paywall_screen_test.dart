import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_router.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:look_atlas/features/home/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:look_atlas/features/subscription/presentation/screens/paywall_screen.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'jane@example.com');

  late FakeSubscriptionRepository subscriptions;

  setUp(() {
    subscriptions = FakeSubscriptionRepository(packages: [fakePackage()]);
    addTearDown(subscriptions.dispose);
  });

  /// Pumps the real app router with fake repositories and opens the paywall.
  ///
  /// [push] opens it imperatively over the current screen (how home and
  /// settings link to it); the default `go` sets the location URI, which
  /// imperative pushes leave untouched, so URI assertions stay meaningful.
  Future<GoRouter> pumpPaywall(
    WidgetTester tester, {
    AppUser? user,
    bool push = false,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: user),
        ),
        subscriptionRepositoryProvider.overrideWithValue(subscriptions),
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
    if (push) {
      unawaited(router.push('/paywall'));
    } else {
      router.go('/paywall');
    }
    await tester.pumpAndSettle();
    return router;
  }

  Uri currentUri(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri;

  testWidgets(
    'anonymous purchase navigates to sign-up with a home deep link',
    (tester) async {
      final router = await pumpPaywall(tester);

      await tester.tap(find.text('Subscribe'));
      await tester.pumpAndSettle();

      final uri = currentUri(router);
      expect(uri.path, '/sign-up');
      expect(uri.queryParameters['from'], '/');
      expect(find.byType(SignUpScreen), findsOneWidget);
      expect(
        find.text(
          'Purchase successful. Create an account to secure your '
          'subscription.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('logged-in purchase pops back to the previous screen', (
    tester,
  ) async {
    await pumpPaywall(tester, user: user, push: true);

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.text('You are now premium.'), findsOneWidget);
  });

  testWidgets('purchase failure shows the message and stays on the paywall', (
    tester,
  ) async {
    subscriptions.purchaseResult = const Result.err(
      SubscriptionFailure(
        'We could not complete the purchase. Please try again.',
      ),
    );
    final router = await pumpPaywall(tester);

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    expect(currentUri(router).path, '/paywall');
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(
      find.text('We could not complete the purchase. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('cancelled purchase stays on the paywall without a snackbar', (
    tester,
  ) async {
    subscriptions.purchaseResult = const Result.err(
      SubscriptionFailure('Purchase cancelled.', userCancelled: true),
    );
    final router = await pumpPaywall(tester);

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    expect(currentUri(router).path, '/paywall');
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('premium users see renewal info instead of plans', (
    tester,
  ) async {
    subscriptions = FakeSubscriptionRepository(
      status: SubscriptionStatus(
        isPremium: true,
        activeEntitlements: const ['premium'],
        entitlementId: 'premium',
        productId: 'product_monthly',
        expiresAt: DateTime.utc(2026, 8),
        willRenew: true,
        managementUrl: 'https://apps.apple.com/account/subscriptions',
      ),
    );
    addTearDown(subscriptions.dispose);
    await pumpPaywall(tester, user: user);

    expect(find.text('You are premium'), findsOneWidget);
    expect(find.textContaining('Renews on'), findsOneWidget);
    expect(
      find.text('https://apps.apple.com/account/subscriptions'),
      findsOneWidget,
    );
    expect(find.text('Subscribe'), findsNothing);
  });
}
