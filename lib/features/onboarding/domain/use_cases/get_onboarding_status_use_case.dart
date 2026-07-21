import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetOnboardingStatusUseCase {
  const GetOnboardingStatusUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<OnboardingStatus>> call() => _repository.fetchStatus();
}
