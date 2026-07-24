import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<void>> call() => _repository.completeOnboarding();
}
