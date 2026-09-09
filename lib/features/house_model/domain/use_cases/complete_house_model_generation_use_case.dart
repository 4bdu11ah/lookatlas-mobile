import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:look_atlas/features/house_model/domain/repositories/house_models_repository.dart';

class CompleteHouseModelGenerationUseCase {
  const CompleteHouseModelGenerationUseCase(this._repository);

  final HouseModelsRepository _repository;

  Future<Result<HouseModelCatalog>> call(
    HouseModelGeneration generation,
  ) async {
    final completed = await _repository.waitForModelGeneration(generation);
    final failure = completed.failureOrNull;
    if (failure != null) return Err(failure);
    return _repository.loadCatalog();
  }
}
