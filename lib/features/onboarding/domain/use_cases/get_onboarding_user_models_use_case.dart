import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetOnboardingUserModelsUseCase {
  const GetOnboardingUserModelsUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<List<OnboardingUserModel>>> call() =>
      _repository.fetchUserModels();
}
