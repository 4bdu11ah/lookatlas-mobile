import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class CreateOnboardingProductUseCase {
  const CreateOnboardingProductUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<String>> call(ProductDraft draft) {
    if (draft.name.trim().isEmpty || draft.sku.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Product name and SKU are required.')),
      );
    }
    if (draft.photos.length < 2 || draft.photos.length > 4) {
      return Future.value(
        const Err(ValidationFailure('Select between 2 and 4 product photos.')),
      );
    }
    if (draft.viewAngles.length != draft.photos.length ||
        draft.viewAngles.any((angle) => angle == null || angle.isEmpty)) {
      return Future.value(
        const Err(ValidationFailure('Tag every product photo with an angle.')),
      );
    }
    return _repository.createProduct(draft);
  }
}
