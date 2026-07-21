import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class UpdateProductAnglesUseCase {
  const UpdateProductAnglesUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<void>> call(String productId, Map<int, String?> angles) =>
      _repository.updateProductAngles(productId, angles);
}
