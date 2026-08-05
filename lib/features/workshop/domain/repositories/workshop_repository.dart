import 'dart:typed_data';

import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';

abstract interface class WorkshopRepository {
  Future<Result<WorkshopWorkspace>> load();
  Future<Result<WorkshopGeneration?>> getActive();
  Future<Result<List<WorkshopGeneration>>> getGenerations();
  Future<Result<WorkshopGeneration>> generate(
    WorkshopGenerateRequest request,
  );
  Future<Result<WorkshopGeneration>> getGeneration(String generationId);
  Future<Result<void>> deleteGeneration(String generationId);
  Future<Result<Uint8List>> downloadImage(String imageUrl);
}
