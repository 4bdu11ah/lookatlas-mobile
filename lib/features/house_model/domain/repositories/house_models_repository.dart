import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';

abstract interface class HouseModelsRepository {
  Future<Result<HouseModelCatalog>> loadCatalog();

  Future<Result<void>> createModel(HouseModelDraft draft);

  Future<Result<void>> updateModel(String modelId, HouseModelDraft draft);

  Future<Result<void>> deleteModel(String modelId);

  Future<Result<void>> deletePhoto(String modelId, String photoId);

  Future<Result<HouseModelGeneration>> startModelGeneration(
    AiHouseModelDraft draft,
  );

  Future<Result<void>> waitForModelGeneration(HouseModelGeneration generation);

  Future<Result<void>> generateModel(AiHouseModelDraft draft);
}
