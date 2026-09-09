import 'package:look_atlas/features/subscription/domain/entities/subscription_product.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

abstract final class SubscriptionProductModel {
  static SubscriptionProduct fromStoreProduct(StoreProduct product) =>
      SubscriptionProduct(
        id: product.identifier,
        description: product.description,
        title: product.title,
        price: product.price,
        priceString: product.priceString,
        currencyCode: product.currencyCode,
        type: product.productCategory == ProductCategory.nonSubscription
            ? SubscriptionProductType.nonSubscription
            : SubscriptionProductType.subscription,
        subscriptionPeriod: product.subscriptionPeriod,
      );
}
