import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:look_atlas/features/house_model/domain/repositories/house_models_repository.dart';

class CreateHouseModelUseCase {
  const CreateHouseModelUseCase(this._repository);

  final HouseModelsRepository _repository;

  Future<Result<void>> call(HouseModelDraft draft) {
    final failure = _validate(draft);
    return failure == null
        ? _repository.createModel(draft)
        : Future.value(Err(failure));
  }

  ValidationFailure? _validate(HouseModelDraft draft) {
    if (draft.name.trim().isEmpty) {
      return const ValidationFailure('Enter a model name.');
    }
    if (draft.gender.trim().isEmpty) {
      return const ValidationFailure('Select a gender.');
    }
    if (draft.heightCm < HouseModelDraft.minHeightCm ||
        draft.heightCm > HouseModelDraft.maxHeightCm) {
      return const ValidationFailure('Enter a height between 100 and 250 cm.');
    }
    if (draft.photos.length < HouseModelDraft.minPhotoCount) {
      return const ValidationFailure('Add at least one clear model photo.');
    }
    if (draft.photos.length > HouseModelDraft.maxPhotoCount) {
      return const ValidationFailure('You can upload up to 4 photos.');
    }
    return null;
  }
}
