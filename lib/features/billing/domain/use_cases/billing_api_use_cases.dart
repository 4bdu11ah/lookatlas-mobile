import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';
import 'package:look_atlas/features/billing/domain/repositories/billing_api_repository.dart';

class GetBillingPlansUseCase {
  const GetBillingPlansUseCase(this._repository);
  final BillingApiRepository _repository;
  Future<Result<List<BillingPlan>>> call() => _repository.getPlans();
}

class GetBillingHistoryUseCase {
  const GetBillingHistoryUseCase(this._repository);
  final BillingApiRepository _repository;
  Future<Result<List<BillingHistoryEntry>>> call() => _repository.getHistory();
}

class CreateBillingCheckoutUseCase {
  const CreateBillingCheckoutUseCase(this._repository);
  final BillingApiRepository _repository;
  Future<Result<CheckoutSession>> call({
    required String priceId,
    required Uri successUrl,
    required Uri cancelUrl,
    bool useProUpsell = false,
  }) => _repository.createCheckout(
    priceId: priceId,
    successUrl: successUrl,
    cancelUrl: cancelUrl,
    useProUpsell: useProUpsell,
  );
}

class CreateOnetimeCheckoutUseCase {
  const CreateOnetimeCheckoutUseCase(this._repository);
  final BillingApiRepository _repository;
  Future<Result<CheckoutSession>> call({
    required Uri successUrl,
    required Uri cancelUrl,
    String? fbEventId,
  }) => _repository.createOnetimeCheckout(
    successUrl: successUrl,
    cancelUrl: cancelUrl,
    fbEventId: fbEventId,
  );
}

class VerifyOnetimeUseCase {
  const VerifyOnetimeUseCase(this._repository);
  final BillingApiRepository _repository;
  Future<Result<OnetimeVerification>> call(String sessionId) =>
      _repository.verifyOnetime(sessionId);
}

class GetProUpsellOfferUseCase {
  const GetProUpsellOfferUseCase(this._repository);
  final BillingApiRepository _repository;
  Future<Result<ProUpsellOffer?>> call() => _repository.getProUpsellOffer();
}
