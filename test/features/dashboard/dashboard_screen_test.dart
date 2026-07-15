import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpDashboard(WidgetTester tester, {AppUser? user}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user:
                  user ??
                  const AppUser(id: 'user-1', email: 'jane@example.com'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );
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
    expect(find.text('Summer drop hero shoot'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Manage Models'), findsOneWidget);
    expect(find.text('Upload Products'), findsOneWidget);
    expect(find.text('Workshop'), findsOneWidget);
    expect(find.text('New Shoot'), findsOneWidget);
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          // Sign-out detaches the identity from subscriptions; the real
          // repository needs platform channels.
          subscriptionRepositoryProvider.overrideWithValue(
            FakeSubscriptionRepository(),
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
  });
}
