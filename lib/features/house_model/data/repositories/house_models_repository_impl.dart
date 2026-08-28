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
  Future<Result<void>> createModel(HouseModelDraft draft) {
    final failure = _validateNewModel(draft);
    if (failure != null) return Future.value(Err<void>(failure));
    return _remote.createModel(draft);
  }

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
  Future<Result<void>> deletePhoto(String modelId, String photoId) =>
      _remote.deletePhoto(modelId, photoId);

  Failure? _validateNewModel(HouseModelDraft draft) {
    if (draft.name.trim().isEmpty) {
      return const ValidationFailure('Enter a model name.');
    }
    if (draft.gender.trim().isEmpty) {
      return const ValidationFailure('Select a gender.');
    }
    if (draft.heightCm < HouseModelDraft.minHeightCm ||
        draft.heightCm > HouseModelDraft.maxHeightCm) {
      return const ValidationFailure(
        'Enter a height between 100 and 250 cm.',
      );
    }
    if (draft.photos.length < HouseModelDraft.minPhotoCount) {
      return const ValidationFailure('Add at least one clear model photo.');
    }
    if (draft.photos.length > HouseModelDraft.maxPhotoCount) {
      return const ValidationFailure('You can upload up to 4 photos.');
    }
    return null;
  }

  @override
  Future<Result<HouseModelGeneration>> startModelGeneration(
    AiHouseModelDraft draft,
  ) => _remote.generateModel(draft);

  @override
  Future<Result<void>> waitForModelGeneration(
    HouseModelGeneration generation,
  ) async {
    var result = Result.ok(generation);
    var generationId = generation.id;
    for (var attempt = 0; attempt < maxPollAttempts; attempt++) {
      final currentGeneration = result.valueOrNull;
      if (currentGeneration != null) {
        generationId = currentGeneration.id;
        if (currentGeneration.status == HouseModelGenerationStatus.completed) {
          return const Ok(null);
        }
        if (currentGeneration.status == HouseModelGenerationStatus.failed) {
          return Err(
            AiFailure(
              currentGeneration.message ??
                  'Model generation failed. Try again.',
            ),
          );
        }
        await _delay(pollInterval);
        result = await _remote.getGeneration(currentGeneration.id);
        continue;
      }

      final failure = result.failureOrNull!;
      if (failure is! NetworkFailure) return Err(failure);
      await _delay(retryInterval);
      result = await _remote.getGeneration(generationId);
    }
    return const Err(
      AiFailure('Model generation is taking too long. Please try again.'),
    );
  }

  @override
  Future<Result<void>> generateModel(AiHouseModelDraft draft) async {
    final started = await startModelGeneration(draft);
    final generation = started.valueOrNull;
    if (generation == null) return Err(started.failureOrNull!);
    return waitForModelGeneration(generation);
  }
}
