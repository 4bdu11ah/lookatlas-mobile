import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class UpdateOnboardingProductUseCase {
  const UpdateOnboardingProductUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<void>> call(String productId, ProductDraft draft) =>
      _repository.updateProduct(productId, draft);
}
