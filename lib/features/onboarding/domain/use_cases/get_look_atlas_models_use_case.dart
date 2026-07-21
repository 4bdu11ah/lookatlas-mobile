import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetLookAtlasModelsUseCase {
  const GetLookAtlasModelsUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<List<LookAtlasModel>>> call() => _repository.fetchModels();
}
