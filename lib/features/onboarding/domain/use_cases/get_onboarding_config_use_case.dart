import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetOnboardingConfigUseCase {
  const GetOnboardingConfigUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<OnboardingAppConfig>> call() => _repository.fetchAppConfig();
}
