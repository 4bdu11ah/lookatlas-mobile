import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/subscription/data/models/subscription_product_model.dart';
import 'package:look_atlas/features/subscription/domain/entities/subscription_product.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  test('fromStoreProduct_preservesStoreDisplayAndPurchaseFields', () {
    const storeProduct = StoreProduct(
      'starter_monthly',
      '80 images every month.',
      'Premium Monthly',
      49,
      r'$49.00',
      'USD',
      productCategory: ProductCategory.subscription,
      subscriptionPeriod: 'P1M',
    );

    final product = SubscriptionProductModel.fromStoreProduct(storeProduct);

    expect(product.id, storeProduct.identifier);
    expect(product.title, storeProduct.title);
    expect(product.description, storeProduct.description);
    expect(product.price, storeProduct.price);
    expect(product.priceString, storeProduct.priceString);
    expect(product.currencyCode, storeProduct.currencyCode);
    expect(product.type, SubscriptionProductType.subscription);
    expect(product.subscriptionPeriod, storeProduct.subscriptionPeriod);
    expect(product.isMonthly, isTrue);
    expect(product.isOneTime, isFalse);
  });

  test('fromStoreProduct_preservesNonSubscriptionCategory', () {
    const storeProduct = StoreProduct(
      'download_hd',
      'Download in HD.',
      'Download',
      8.99,
      r'$8.99',
      'USD',
      productCategory: ProductCategory.nonSubscription,
    );

    final product = SubscriptionProductModel.fromStoreProduct(storeProduct);

    expect(product.type, SubscriptionProductType.nonSubscription);
    expect(product.isOneTime, isTrue);
    expect(product.isMonthly, isFalse);
  });
}
