import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetOnboardingProductsUseCase {
  const GetOnboardingProductsUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<List<OnboardingProduct>>> call() => _repository.fetchProducts();
}
