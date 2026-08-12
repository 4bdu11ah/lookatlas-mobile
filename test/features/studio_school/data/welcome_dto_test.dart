import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/studio_school/data/welcome_dto.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';

void main() {
  test('state_eligiblePayload_mapsCanonicalLessonProgress', () {
    final state = WelcomeDto.state({
      'eligible': true,
      'lessons': [
        {
          'id': 'image_rights',
          'startedAt': '2026-08-11T10:00:00Z',
          'completedAt': '2026-08-11T10:00:25Z',
        },
      ],
      'lessonsRewardClaimedAt': null,
    });

    final progress = state.progressFor(WelcomeLessonId.imageRights);
    expect(state.eligible, isTrue);
    expect(progress.startedAt, DateTime.utc(2026, 8, 11, 10));
    expect(progress.isCompleted, isTrue);
  });

  test('state_unknownLesson_ignoresUntrustedCatalogEntry', () {
    final state = WelcomeDto.state({
      'eligible': true,
      'lessons': [
        {'id': 'not_allowed', 'completedAt': '2026-08-11T10:00:25Z'},
      ],
    });

    expect(state.lessons, isEmpty);
    expect(state.completedCount, 0);
  });

  test('state_nonSubscriber_returnsReadOnlyContract', () {
    final state = WelcomeDto.state({'eligible': false});

    expect(state.eligible, isFalse);
    expect(state.canClaimReward, isFalse);
  });

  test('claim_response_mapsIdempotentResult', () {
    final result = WelcomeDto.claim({
      'granted': 0,
      'alreadyClaimed': true,
    });

    expect(result.granted, 0);
    expect(result.alreadyClaimed, isTrue);
  });
}
