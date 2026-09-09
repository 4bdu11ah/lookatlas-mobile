import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/errors/content_api_exception.dart';
import 'package:look_atlas/features/create_content/domain/repositories/content_repository.dart';

class SaveContentDraftUseCase {
  const SaveContentDraftUseCase(this._repository);

  final ContentRepository _repository;

  Future<ContentDraft> call({
    required ContentFormat format,
    required String? draftId,
    required ContentJson brief,
    required ContentJson patch,
    required void Function() onRemoteDraftMissing,
  }) async {
    try {
      return await _repository.save(format, draftId, patch);
    } on ContentApiException catch (error) {
      if (error.status != 404 || draftId == null) rethrow;
      onRemoteDraftMissing();
      return _repository.save(format, null, {...brief, ...patch});
    }
  }
}
