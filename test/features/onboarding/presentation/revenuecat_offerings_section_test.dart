import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/revenuecat_offerings_section.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  testWidgets('shows_revenuecat_subscriptions_and_one_time_product', (
    tester,
  ) async {
    Package? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: RevenueCatOfferingsSection(
            packages: const [_monthly, _oneTime],
            purchasingPackageId: null,
            onPurchase: (package) => selected = package,
          ),
        ),
      ),
    );

    expect(find.text('Premium Monthly'), findsOneWidget);
    expect(find.text(r'$49.00'), findsOneWidget);
    expect(find.text('Download 15 photos'), findsOneWidget);
    expect(find.text(r'$8.99'), findsOneWidget);

    await tester.tap(find.text('Unlock photos'));
    expect(selected?.identifier, 'one_time');
  });
}

const _context = PresentedOfferingContext('default', null, null);
const _monthly = Package(
  'monthly',
  PackageType.monthly,
  StoreProduct(
    'starter_monthly',
    '80 images every month.',
    'Premium Monthly',
    49,
    r'$49.00',
    'USD',
    productCategory: ProductCategory.subscription,
  ),
  _context,
);
const _oneTime = Package(
  'one_time',
  PackageType.lifetime,
  StoreProduct(
    'onetime_download_hd',
    'Download this shoot in HD.',
    'Download 15 photos',
    8.99,
    r'$8.99',
    'USD',
    productCategory: ProductCategory.nonSubscription,
  ),
  _context,
);
