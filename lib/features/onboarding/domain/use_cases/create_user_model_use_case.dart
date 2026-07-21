import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class CreateUserModelUseCase {
  const CreateUserModelUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<String>> call(UserModelDraft draft) {
    if (draft.photos.isEmpty || draft.photos.length > 5) {
      return Future.value(
        const Err(ValidationFailure('Select between 1 and 5 model photos.')),
      );
    }
    return _repository.createUserModel(draft);
  }
}
