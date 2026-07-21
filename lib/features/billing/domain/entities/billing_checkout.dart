import 'package:flutter/foundation.dart';

@immutable
class BillingPlan {
  const BillingPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.yearlyPrice,
    required this.monthlyCredits,
    required this.features,
    required this.excludedFeatures,
    required this.priceId,
    required this.yearlyPriceId,
    required this.popular,
    this.tagline,
  });

  final String id;
  final String name;
  final String? tagline;
  final double price;
  final double yearlyPrice;
  final int monthlyCredits;
  final List<String> features;
  final List<String> excludedFeatures;
  final String priceId;
  final String yearlyPriceId;
  final bool popular;
}

@immutable
class CheckoutSession {
  const CheckoutSession({required this.url, this.mode});

  final Uri url;
  final String? mode;
}

enum OnetimePaymentStatus { pending, paid, failed, refunded }

@immutable
class OnetimeVerification {
  const OnetimeVerification({
    required this.status,
    this.jobId,
    this.offerExpiresAt,
  });

  final OnetimePaymentStatus status;
  final String? jobId;
  final DateTime? offerExpiresAt;
}

@immutable
class ProUpsellOffer {
  const ProUpsellOffer({
    required this.active,
    required this.accepted,
    this.expiresAt,
  });

  final bool active;
  final bool accepted;
  final DateTime? expiresAt;
}
