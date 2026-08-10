import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpSettings(
    WidgetTester tester, {
    AppUser? user = const AppUser(
      id: 'user-1',
      email: 'studio@lookatlas.com',
      companyName: 'Look Atlas Studio',
    ),
    Size size = const Size(390, 844),
    bool settle = true,
    bool holdLoading = false,
    bool failAuth = false,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: user),
          ),
          if (holdLoading)
            authStateProvider.overrideWithValue(
              const AsyncLoading<AppUser?>(),
            ),
          if (failAuth)
            authStateProvider.overrideWithValue(
              AsyncError<AppUser?>(Exception('auth failed'), StackTrace.empty),
            ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AccountSettingsScreen(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('settings page renders the reference account information', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Settings'), findsNWidgets(2));
    expect(
      find.text('Configure your account and application preferences'),
      findsOneWidget,
    );
    expect(find.text('Account Information'), findsOneWidget);
    expect(find.text('COMPANY NAME'), findsOneWidget);
    expect(find.text('Look Atlas Studio'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('studio@lookatlas.com'), findsOneWidget);
    expect(find.text('CURRENT PLAN'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text(r'$99/usd'), findsOneWidget);
    expect(find.text('MEMBER SINCE'), findsOneWidget);
    expect(find.text('January 10, 2026'), findsOneWidget);
  });

  testWidgets('settings page shows missing optional account values', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      user: const AppUser(id: 'user-1', email: 'studio@lookatlas.com'),
    );

    expect(find.text('-'), findsOneWidget);
    expect(find.text('studio@lookatlas.com'), findsOneWidget);
  });

  testWidgets('settings page initially renders four loading skeleton rows', (
    tester,
  ) async {
    await pumpSettings(tester, settle: false, holdLoading: true);

    expect(
      find.byKey(const ValueKey('settings-skeleton-row')),
      findsNWidgets(4),
    );
  });

  testWidgets('settings page renders the reference API error state', (
    tester,
  ) async {
    await pumpSettings(tester, failAuth: true);

    expect(find.text('Error Loading Settings'), findsOneWidget);
    expect(find.text('Failed to load settings'), findsOneWidget);
  });

  testWidgets('settings page fits the 320px audit width', (tester) async {
    await pumpSettings(tester, size: const Size(320, 720));

    expect(find.text('Account Information'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
