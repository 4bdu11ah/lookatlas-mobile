import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpBilling(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(id: 'user-1', email: 'dana@example.com'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardFeatureScreen.billing(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('billing page matches the mobile billing content', (
    tester,
  ) async {
    await pumpBilling(tester);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.text('Billing'), findsNWidgets(2));
    expect(
      find.text('Manage your subscription and view usage'),
      findsOneWidget,
    );
    expect(find.text('Usage This Month'), findsOneWidget);
    expect(find.text('137'), findsWidgets);
    expect(find.text('Remaining of 200 credits'), findsOneWidget);
    expect(find.text('Used 63 credits so far'), findsOneWidget);
    expect(find.text('Current Plan'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text(r'$99/month'), findsOneWidget);
    expect(find.text('Renews on Aug 1, 2026'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Billing History'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('Pro plan renewal'), findsOneWidget);
  });

  testWidgets('credit purchase updates quantity and completes', (tester) async {
    await pumpBilling(tester);

    await tester.tap(find.text('Buy More Credits'));
    await tester.pumpAndSettle();

    expect(find.text('Buy Credits'), findsOneWidget);
    expect(find.text('Top up your balance in a few clicks.'), findsOneWidget);
    expect(find.text('80 Credit Pack'), findsOneWidget);
    expect(find.text(r'$20.00'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('billing-credit-plus')));
    await tester.pump();

    expect(find.text('160'), findsOneWidget);
    expect(find.text(r'$40.00'), findsOneWidget);

    await tester.tap(find.text('Complete Purchase'));
    await tester.pumpAndSettle();

    expect(find.text('Credits added'), findsOneWidget);
    expect(find.textContaining('160 credits'), findsOneWidget);
  });

  testWidgets('billing history refresh completes', (tester) async {
    await pumpBilling(tester);

    await tester.scrollUntilVisible(
      find.text('Refresh'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Refresh'));
    await tester.pump();
    expect(find.text('Refresh'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Refresh'), findsOneWidget);
  });

  testWidgets('plan cycle and upgrade confirmation update current plan', (
    tester,
  ) async {
    await pumpBilling(tester);

    await tester.tap(find.text('Modify'));
    await tester.pumpAndSettle();
    expect(find.text('Modify Subscription'), findsOneWidget);

    await tester.tap(find.text('Yearly'));
    await tester.pump();
    expect(find.text(r'$82.50'), findsOneWidget);
    expect(find.text('Switch to yearly'), findsOneWidget);

    final businessPlan = find.byKey(
      const ValueKey('billing-plan-business'),
    );
    await tester.ensureVisible(businessPlan);
    await tester.tap(businessPlan);
    await tester.pumpAndSettle();
    expect(find.text('Upgrade to Business'), findsWidgets);
    expect(find.textContaining(r'$1,790'), findsWidgets);

    await tester.tap(find.text('Confirm upgrade'));
    await tester.pumpAndSettle();
    expect(find.text('Plan updated'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('billing-plan-success-close')));
    await tester.pumpAndSettle();
    expect(find.text('Business'), findsOneWidget);
    expect(find.text(r'$149.17/month'), findsOneWidget);
  });

  testWidgets('cancellation survey schedules cancellation', (tester) async {
    await pumpBilling(tester);

    await tester.tap(find.text('Modify'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel Subscription'));
    await tester.pumpAndSettle();

    expect(find.text("We're sorry to see you go"), findsOneWidget);
    await tester.tap(find.text('Too expensive'));
    await tester.enterText(
      find.byType(TextField),
      'Need a smaller monthly option.',
    );
    await tester.ensureVisible(find.text('Confirm Cancellation'));
    await tester.tap(find.text('Confirm Cancellation'));
    await tester.pumpAndSettle();

    expect(find.text('Cancellation Scheduled'), findsOneWidget);
    expect(find.textContaining("You'll keep access until"), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('billing-cancel-success-close')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cancelling'), findsOneWidget);
    expect(find.text('Access until Aug 1, 2026'), findsOneWidget);
  });

  testWidgets('billing page and dialogs fit the 320px audit width', (
    tester,
  ) async {
    await pumpBilling(tester, size: const Size(320, 844));

    await tester.tap(find.text('Buy More Credits'));
    await tester.pumpAndSettle();
    expect(find.text('Complete Purchase'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    final modify = find.text('Modify');
    await tester.ensureVisible(modify);
    await tester.tap(modify);
    await tester.pumpAndSettle();

    expect(find.text('Modify Subscription'), findsOneWidget);
  });
}
