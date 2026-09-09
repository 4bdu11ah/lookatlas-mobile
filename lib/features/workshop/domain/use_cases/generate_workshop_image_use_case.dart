import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/domain/repositories/workshop_repository.dart';

class GenerateWorkshopImageUseCase {
  const GenerateWorkshopImageUseCase(this._repository);

  final WorkshopRepository _repository;

  Result<WorkshopGenerateRequest> prepare({
    required WorkshopBaseImage? base,
    required List<WorkshopSample> references,
    required String prompt,
    required WorkshopEditMode mode,
  }) {
    if (base == null) {
      return const Err(ValidationFailure('Upload a base image first.'));
    }
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      return const Err(
        ValidationFailure('Write a prompt describing the edit you want.'),
      );
    }
    if (prompt.length > WorkshopState.maxPromptLength) {
      return const Err(
        ValidationFailure('Prompt must be 1000 characters or fewer.'),
      );
    }
    final bytes = base.bytes;
    if (bytes == null) {
      return const Err(
        ValidationFailure(
          'We lost track of your uploaded images. Please try again — '
          'your credit was refunded.',
        ),
      );
    }
    return Ok(
      WorkshopGenerateRequest(
        base: WorkshopUpload(
          bytes: bytes,
          fileName: base.fileName ?? 'workshop-base.jpg',
        ),
        references: [
          for (final reference in references)
            WorkshopUpload(
              bytes: reference.bytes,
              fileName: reference.fileName,
            ),
        ],
        prompt: normalizedPrompt,
        mode: mode,
      ),
    );
  }

  Future<Result<WorkshopGeneration>> execute(
    WorkshopGenerateRequest request,
  ) => _repository.generate(request);
}
