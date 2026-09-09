import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_profile_draft.dart';
import 'package:look_atlas/features/studio_school/domain/repositories/welcome_repository.dart';

class CompleteWelcomeProfileUseCase {
  const CompleteWelcomeProfileUseCase(this._repository);

  final WelcomeRepository _repository;

  Future<Result<void>> call({
    required String userId,
    required WelcomeProfileDraft profile,
    required bool skipped,
    required int step,
  }) async {
    if (skipped) {
      await _repository.recordEvent(
        userId,
        'welcome.intro_skipped',
        properties: {'step': step},
      );
      return const Ok(null);
    }
    await _repository.recordEvent(userId, 'welcome.intro_completed');
    return _repository.saveProfile(userId, profile);
  }
}
