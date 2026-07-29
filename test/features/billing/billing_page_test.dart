import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/billing/di/billing_api_providers.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../helpers/fake_repositories.dart';

const _monthlyProducts = [
  StoreProduct(
    'starter_monthly',
    '100 photos every month.',
    'Starter',
    49,
    r'$49.00',
    'USD',
    productCategory: ProductCategory.subscription,
    subscriptionPeriod: 'P1M',
  ),
  StoreProduct(
    'pro_monthly',
    '200 photos every month.',
    'Pro',
    99,
    r'$99.00',
    'USD',
    productCategory: ProductCategory.subscription,
    subscriptionPeriod: 'P1M',
  ),
  StoreProduct(
    'studio_monthly',
    '600 photos every month.',
    'Studio',
    199,
    r'$199.00',
    'USD',
    productCategory: ProductCategory.subscription,
    subscriptionPeriod: 'P1M',
  ),
  StoreProduct(
    'annual',
    'Annual subscription.',
    'Annual',
    499,
    r'$499.00',
    'USD',
    productCategory: ProductCategory.subscription,
    subscriptionPeriod: 'P1Y',
  ),
];

final _proStatus = SubscriptionStatus(
  isPremium: true,
  activeEntitlements: const ['premium'],
  entitlementId: 'premium',
  productId: 'pro_monthly',
  expiresAt: DateTime.utc(2026, 8),
  willRenew: true,
);

final _studioStatus = SubscriptionStatus(
  isPremium: true,
  activeEntitlements: const ['premium'],
  entitlementId: 'premium',
  productId: 'studio_monthly',
  expiresAt: DateTime.utc(2026, 8),
  willRenew: true,
);

final _history = [
  BillingHistoryEntry(
    occurredAt: DateTime.utc(2026, 7, 1, 9, 14),
    description: 'Pro plan renewal',
    amount: 99,
    currencyCode: 'USD',
    credits: 200,
    balance: 200,
  ),
];

class _RecordingSubscriptionRepository extends FakeSubscriptionRepository {
  _RecordingSubscriptionRepository({SubscriptionStatus? status})
    : super(products: _monthlyProducts, status: status ?? _proStatus);

  StoreProduct? purchasedProduct;
  Result<List<StoreProduct>>? productsResult;

  @override
  Future<Result<List<StoreProduct>>> fetchProducts() async =>
      productsResult ?? super.fetchProducts();

  @override
  Future<Result<SubscriptionStatus>> purchase(StoreProduct product) {
    purchasedProduct = product;
    return super.purchase(product);
  }
}

void main() {
  late _RecordingSubscriptionRepository subscriptions;
  late int historyLoads;

  setUp(() {
    subscriptions = _RecordingSubscriptionRepository();
    historyLoads = 0;
    addTearDown(subscriptions.dispose);
  });

  Future<void> pumpBilling(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    _RecordingSubscriptionRepository? subscriptionRepository,
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
          subscriptionRepositoryProvider.overrideWithValue(
            subscriptionRepository ?? subscriptions,
          ),
          dashboardStatsProvider.overrideWith(
            (ref) async => const DashboardStats(
              credits: 137,
              creditsTotal: 200,
              creditsUsed: 63,
              totalRenders: 0,
              activeJobs: 0,
              completedJobs: 0,
            ),
          ),
          billingHistoryProvider.overrideWith((ref) async {
            historyLoads++;
            return _history;
          }),
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
    expect(find.text(r'$99.00/month'), findsOneWidget);
    expect(find.textContaining('Renews on'), findsOneWidget);

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
    expect(historyLoads, 1);

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
    expect(historyLoads, 2);
  });

  testWidgets('billing lists monthly RevenueCat plans and purchases one', (
    tester,
  ) async {
    await pumpBilling(tester);

    await tester.tap(find.text('Change plan'));
    await tester.pumpAndSettle();
    expect(find.text('Modify Subscription'), findsOneWidget);
    expect(find.textContaining('monthly plan'), findsOneWidget);
    expect(find.text('Yearly'), findsNothing);
    expect(find.text('Annual'), findsNothing);
    expect(find.text('Starter'), findsOneWidget);
    expect(find.text('Pro'), findsWidgets);
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text(r'$49.00/month'), findsOneWidget);
    expect(find.text(r'$99.00/month'), findsWidgets);
    expect(find.text(r'$199.00/month'), findsOneWidget);

    subscriptions.purchaseResult = Result.ok(_studioStatus);
    final studioPlan = find.byKey(
      const ValueKey('billing-plan-studio_monthly'),
    );
    await tester.ensureVisible(studioPlan);
    await tester.tap(
      find.descendant(of: studioPlan, matching: find.text('Switch plan')),
    );
    await tester.pumpAndSettle();
    expect(subscriptions.purchasedProduct?.identifier, 'studio_monthly');
    expect(find.text('Subscription updated.'), findsOneWidget);
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text(r'$199.00/month'), findsOneWidget);
  });

  testWidgets('current annual RevenueCat product shows annual price', (
    tester,
  ) async {
    final annualSubscriptions = _RecordingSubscriptionRepository(
      status: SubscriptionStatus(
        isPremium: true,
        activeEntitlements: const ['premium'],
        entitlementId: 'premium',
        productId: 'annual',
        expiresAt: DateTime.utc(2027, 8),
        willRenew: true,
      ),
    );
    addTearDown(annualSubscriptions.dispose);

    await pumpBilling(
      tester,
      subscriptionRepository: annualSubscriptions,
    );

    expect(find.text('Annual'), findsOneWidget);
    expect(find.text(r'$499.00/year'), findsOneWidget);
  });

  testWidgets('subscription purchase failure stays in the dialog', (
    tester,
  ) async {
    subscriptions.purchaseResult = const Result.err(
      SubscriptionFailure('Purchase failed. Please try again.'),
    );
    await pumpBilling(tester);

    await tester.tap(find.text('Change plan'));
    await tester.pumpAndSettle();
    final studioPlan = find.byKey(
      const ValueKey('billing-plan-studio_monthly'),
    );
    await tester.ensureVisible(studioPlan);
    await tester.tap(
      find.descendant(of: studioPlan, matching: find.text('Switch plan')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modify Subscription'), findsOneWidget);
    expect(find.text('Purchase failed. Please try again.'), findsOneWidget);
  });

  testWidgets('RevenueCat product failure can be retried', (tester) async {
    subscriptions.productsResult = const Result.err(
      SubscriptionFailure('Products are unavailable.'),
    );
    await pumpBilling(tester);
    await tester.pumpAndSettle();

    expect(find.text('Current subscription is unavailable.'), findsOneWidget);

    subscriptions.productsResult = const Result.ok(_monthlyProducts);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text(r'$99.00/month'), findsOneWidget);
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

    final modify = find.text('Change plan');
    await tester.ensureVisible(modify);
    await tester.tap(modify);
    await tester.pumpAndSettle();

    expect(find.text('Modify Subscription'), findsOneWidget);
  });
}
