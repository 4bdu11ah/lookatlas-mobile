import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/revenuecat_products_section.dart';
import 'package:look_atlas/features/subscription/domain/entities/subscription_product.dart';

void main() {
  testWidgets('shows_revenuecat_subscriptions_and_one_time_product', (
    tester,
  ) async {
    SubscriptionProduct? selected;
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
    expect(selected?.id, 'onetime_download_hd');
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

const _monthly = SubscriptionProduct(
  id: 'starter_monthly',
  description: '80 images every month.',
  title: 'Premium Monthly',
  price: 49,
  priceString: r'$49.00',
  currencyCode: 'USD',
  type: SubscriptionProductType.subscription,
  subscriptionPeriod: 'P1M',
);
const _proMonthly = SubscriptionProduct(
  id: 'pro_monthly',
  description: '200 images every month.',
  title: 'Pro Monthly',
  price: 99,
  priceString: r'$99.00',
  currencyCode: 'USD',
  type: SubscriptionProductType.subscription,
  subscriptionPeriod: 'P1M',
);
const _studioMonthly = SubscriptionProduct(
  id: 'studio_monthly',
  description: '600 images every month.',
  title: 'Studio Monthly',
  price: 199,
  priceString: r'$199.00',
  currencyCode: 'USD',
  type: SubscriptionProductType.subscription,
  subscriptionPeriod: 'P1M',
);
const _annual = SubscriptionProduct(
  id: 'annual',
  description: 'Annual subscription.',
  title: 'Annual',
  price: 499,
  priceString: r'$499.00',
  currencyCode: 'USD',
  type: SubscriptionProductType.subscription,
  subscriptionPeriod: 'P1Y',
);
const _oneTime = SubscriptionProduct(
  id: 'onetime_download_hd',
  description: 'Download this shoot in HD.',
  title: 'Download 15 photos',
  price: 8.99,
  priceString: r'$8.99',
  currencyCode: 'USD',
  type: SubscriptionProductType.nonSubscription,
);
