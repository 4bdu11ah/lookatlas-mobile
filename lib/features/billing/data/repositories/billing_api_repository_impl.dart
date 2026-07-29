import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/billing/data/data_sources/billing_remote_data_source.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';
import 'package:look_atlas/features/billing/domain/repositories/billing_api_repository.dart';

class BillingApiRepositoryImpl implements BillingApiRepository {
  const BillingApiRepositoryImpl(this._remote);

  final BillingRemoteDataSource _remote;

  @override
  Future<Result<List<BillingPlan>>> getPlans() => _remote.getPlans();

  @override
  Future<Result<List<BillingHistoryEntry>>> getHistory() =>
      _remote.getHistory();

  @override
  Future<Result<CheckoutSession>> createCheckout({
    required String priceId,
    required Uri successUrl,
    required Uri cancelUrl,
    String? couponCode,
    bool useProUpsell = false,
  }) => _remote.createCheckout({
    'priceId': priceId,
    'successUrl': successUrl.toString(),
    'cancelUrl': cancelUrl.toString(),
    'couponCode': ?couponCode,
    'allowPromoField': false,
    'useProUpsell': useProUpsell,
  });

  @override
  Future<Result<CheckoutSession>> createOnetimeCheckout({
    required Uri successUrl,
    required Uri cancelUrl,
    String? fbEventId,
  }) => _remote.createOnetimeCheckout({
    'successUrl': successUrl
        .toString()
        .replaceAll('%7B', '{')
        .replaceAll('%7D', '}'),
    'cancelUrl': cancelUrl.toString(),
    'fbEventId': ?fbEventId,
  });

  @override
  Future<Result<OnetimeVerification>> verifyOnetime(String sessionId) =>
      _remote.verifyOnetime(sessionId);

  @override
  Future<Result<ProUpsellOffer?>> getProUpsellOffer() =>
      _remote.getProUpsellOffer();
}
