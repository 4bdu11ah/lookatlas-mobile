import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/house_model/data/data_sources/house_models_remote_data_source.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:look_atlas/features/house_model/domain/repositories/house_models_repository.dart';

class HouseModelsRepositoryImpl implements HouseModelsRepository {
  HouseModelsRepositoryImpl(
    this._remote, {
    Future<void> Function(Duration duration)? delay,
    this.pollInterval = const Duration(seconds: 4),
    this.retryInterval = const Duration(seconds: 6),
    this.maxPollAttempts = 150,
  }) : _delay = delay ?? Future<void>.delayed;

  final HouseModelsRemoteDataSource _remote;
  final Future<void> Function(Duration duration) _delay;
  final Duration pollInterval;
  final Duration retryInterval;
  final int maxPollAttempts;

  @override
  Future<Result<HouseModelCatalog>> loadCatalog() async {
    final results = await Future.wait([
      _remote.getLibraryModels(),
      _remote.getUserModels(),
    ]);
    final library = results[0];
    final users = results[1];
    if (library case Err(:final failure)) {
      return Err(failure);
    }
    if (users case Err(:final failure)) {
      return Err(failure);
    }
    return Ok(
      HouseModelCatalog(
        libraryModels: library.valueOrNull ?? const [],
        userModels: users.valueOrNull ?? const [],
      ),
    );
  }

  @override
  Future<Result<void>> createModel(HouseModelDraft draft) =>
      _remote.createModel(draft);

  @override
  Future<Result<void>> updateModel(
    String modelId,
    HouseModelDraft draft,
  ) => draft.photos.isEmpty
      ? _remote.patchModel(modelId, draft)
      : _remote.updateModel(modelId, draft);

  @override
  Future<Result<void>> deleteModel(String modelId) =>
      _remote.deleteModel(modelId);

  @override
  Future<Result<void>> deletePhoto(String modelId, int photoIndex) =>
      _remote.deletePhoto(modelId, photoIndex);

  @override
  Future<Result<void>> generateModel(AiHouseModelDraft draft) async {
    var result = await _remote.generateModel(draft);
    var generationId = result.valueOrNull?.id;
    if (generationId == null) {
      return Err(result.failureOrNull!);
    }
    for (var attempt = 0; attempt < maxPollAttempts; attempt++) {
      final generation = result.valueOrNull;
      if (generation != null) {
        generationId = generation.id;
        if (generation.status == HouseModelGenerationStatus.completed) {
          return const Ok(null);
        }
        if (generation.status == HouseModelGenerationStatus.failed) {
          return Err(
            AiFailure(
              generation.message ?? 'Model generation failed. Try again.',
            ),
          );
        }
        await _delay(pollInterval);
        result = await _remote.getGeneration(generation.id);
        continue;
      }

      final failure = result.failureOrNull!;
      if (failure is! NetworkFailure) return Err(failure);
      await _delay(retryInterval);
      result = await _remote.getGeneration(generationId!);
    }
    return const Err(
      AiFailure('Model generation is taking too long. Please try again.'),
    );
  }
}
