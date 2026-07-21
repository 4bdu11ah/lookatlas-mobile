import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class StartFreeShootUseCase {
  const StartFreeShootUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<StartShootResponse>> call(StartShootRequest request) {
    if (request.productId.isEmpty || request.modelId.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Product and model are required.')),
      );
    }
    return _repository.startShoot(request);
  }
}
