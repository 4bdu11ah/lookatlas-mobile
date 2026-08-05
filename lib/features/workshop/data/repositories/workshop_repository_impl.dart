import 'dart:typed_data';

import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/workshop/data/data_sources/workshop_remote_data_source.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/domain/repositories/workshop_repository.dart';

class WorkshopRepositoryImpl implements WorkshopRepository {
  const WorkshopRepositoryImpl(this._remote);

  final WorkshopRemoteDataSource _remote;

  @override
  Future<Result<WorkshopWorkspace>> load() async {
    final responses = await Future.wait([
      _remote.getActive(),
      _remote.getGenerations(),
    ]);
    final active = responses[0] as Result<WorkshopGeneration?>;
    final history = responses[1] as Result<List<WorkshopGeneration>>;
    if (active case Err(:final failure)) return Err(failure);
    if (history case Err(:final failure)) return Err(failure);
    return Ok(
      WorkshopWorkspace(
        active: active.valueOrNull,
        history: history.valueOrNull!,
      ),
    );
  }

  @override
  Future<Result<WorkshopGeneration?>> getActive() => _remote.getActive();

  @override
  Future<Result<List<WorkshopGeneration>>> getGenerations() =>
      _remote.getGenerations();

  @override
  Future<Result<WorkshopGeneration>> generate(
    WorkshopGenerateRequest request,
  ) => _remote.generate(request);

  @override
  Future<Result<WorkshopGeneration>> getGeneration(String generationId) =>
      _remote.getGeneration(generationId);

  @override
  Future<Result<void>> deleteGeneration(String generationId) =>
      _remote.deleteGeneration(generationId);

  @override
  Future<Result<Uint8List>> downloadImage(String imageUrl) =>
      _remote.downloadImage(imageUrl);
}
