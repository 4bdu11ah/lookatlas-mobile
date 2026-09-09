enum SubscriptionProductType { subscription, nonSubscription }

class SubscriptionProduct {
  const SubscriptionProduct({
    required this.id,
    required this.description,
    required this.title,
    required this.price,
    required this.priceString,
    required this.currencyCode,
    required this.type,
    this.subscriptionPeriod,
  });

  final String id;
  final String description;
  final String title;
  final double price;
  final String priceString;
  final String currencyCode;
  final SubscriptionProductType type;
  final String? subscriptionPeriod;

  bool get isOneTime => type == SubscriptionProductType.nonSubscription;
  bool get isMonthly => !isOneTime && subscriptionPeriod == 'P1M';
}
