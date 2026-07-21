import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';

abstract interface class BillingApiRepository {
  Future<Result<List<BillingPlan>>> getPlans();

  Future<Result<CheckoutSession>> createCheckout({
    required String priceId,
    required Uri successUrl,
    required Uri cancelUrl,
    String? couponCode,
    bool useProUpsell = false,
  });

  Future<Result<CheckoutSession>> createOnetimeCheckout({
    required Uri successUrl,
    required Uri cancelUrl,
    String? fbEventId,
  });

  Future<Result<OnetimeVerification>> verifyOnetime(String sessionId);
  Future<Result<ProUpsellOffer?>> getProUpsellOffer();
}
