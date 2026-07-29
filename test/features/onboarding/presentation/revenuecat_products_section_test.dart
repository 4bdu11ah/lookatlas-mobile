import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/revenuecat_products_section.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  testWidgets('shows_revenuecat_subscriptions_and_one_time_product', (
    tester,
  ) async {
    StoreProduct? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SingleChildScrollView(
            child: RevenueCatProductsSection(
              products: const [
                _monthly,
                _proMonthly,
                _studioMonthly,
                _annual,
                _oneTime,
              ],
              purchasingProductId: null,
              onPurchase: (product) => selected = product,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Premium Monthly'), findsOneWidget);
    expect(find.text(r'$49.00/month'), findsOneWidget);
    expect(find.text('Pro Monthly'), findsOneWidget);
    expect(find.text('Studio Monthly'), findsOneWidget);
    expect(find.text('Annual'), findsNothing);
    expect(find.text('Subscribe'), findsNWidgets(3));
    expect(find.text('Download 15 photos'), findsOneWidget);
    expect(find.text(r'$8.99'), findsOneWidget);

    await tester.ensureVisible(find.text('Unlock photos'));
    await tester.tap(find.text('Unlock photos'));
    expect(selected?.identifier, 'onetime_download_hd');
  });

  testWidgets('shows_loading_and_retry_states', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: RevenueCatProductsSection(
            errorMessage: 'Plans are unavailable right now.',
            purchasingProductId: null,
            onPurchase: (_) {},
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Plans are unavailable right now.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: RevenueCatProductsSection(
            isLoading: true,
            purchasingProductId: null,
            onPurchase: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Loading plans...'), findsOneWidget);
  });
}

const _monthly = StoreProduct(
  'starter_monthly',
  '80 images every month.',
  'Premium Monthly',
  49,
  r'$49.00',
  'USD',
  productCategory: ProductCategory.subscription,
  subscriptionPeriod: 'P1M',
);
const _proMonthly = StoreProduct(
  'pro_monthly',
  '200 images every month.',
  'Pro Monthly',
  99,
  r'$99.00',
  'USD',
  productCategory: ProductCategory.subscription,
  subscriptionPeriod: 'P1M',
);
const _studioMonthly = StoreProduct(
  'studio_monthly',
  '600 images every month.',
  'Studio Monthly',
  199,
  r'$199.00',
  'USD',
  productCategory: ProductCategory.subscription,
  subscriptionPeriod: 'P1M',
);
const _annual = StoreProduct(
  'annual',
  'Annual subscription.',
  'Annual',
  499,
  r'$499.00',
  'USD',
  productCategory: ProductCategory.subscription,
  subscriptionPeriod: 'P1Y',
);
const _oneTime = StoreProduct(
  'onetime_download_hd',
  'Download this shoot in HD.',
  'Download 15 photos',
  8.99,
  r'$8.99',
  'USD',
  productCategory: ProductCategory.nonSubscription,
);
