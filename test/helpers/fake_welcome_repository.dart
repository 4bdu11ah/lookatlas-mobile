import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_repository.dart';

class FakeWelcomeRepository implements WelcomeRepository {
  FakeWelcomeRepository({
    WelcomeState? state,
    this.getFailure,
    this.startFailure,
    this.completeFailure,
    this.claimFailure,
    this.claimResult = const LessonClaimResult(
      granted: 20,
      alreadyClaimed: false,
    ),
  }) : currentState = state ?? const WelcomeState.readOnly();

  WelcomeState currentState;
  final Failure? getFailure;
  final Failure? startFailure;
  final Failure? completeFailure;
  final Failure? claimFailure;
  final LessonClaimResult claimResult;

  int getCalls = 0;
  int startCalls = 0;
  int completeCalls = 0;
  int claimCalls = 0;

  @override
  Future<Result<WelcomeState>> getState(
    String userId, {
    bool forceRefresh = false,
  }) async {
    getCalls++;
    if (getFailure case final failure?) return Err(failure);
    return Ok(currentState);
  }

  @override
  Future<Result<DateTime>> startLesson(
    String userId,
    WelcomeLessonId lessonId,
  ) async {
    startCalls++;
    if (startFailure case final failure?) {
      return Err(failure);
    }
    return Ok(DateTime.now().subtract(const Duration(minutes: 1)));
  }

  @override
  Future<Result<DateTime>> completeLesson(
    String userId,
    WelcomeLessonId lessonId,
  ) async {
    completeCalls++;
    if (completeFailure case final failure?) {
      return Err(failure);
    }
    final completedAt = DateTime.now();
    final lessons = Map<WelcomeLessonId, WelcomeLessonProgress>.of(
      currentState.lessons,
    );
    lessons[lessonId] = WelcomeLessonProgress(
      id: lessonId,
      startedAt: lessons[lessonId]?.startedAt,
      completedAt: completedAt,
    );
    currentState = WelcomeState(
      eligible: currentState.eligible,
      lessons: lessons,
      lessonsRewardClaimedAt: currentState.lessonsRewardClaimedAt,
    );
    return Ok(completedAt);
  }

  @override
  Future<Result<LessonClaimResult>> claimLessons(String userId) async {
    claimCalls++;
    if (claimFailure case final failure?) {
      return Err(failure);
    }
    currentState = WelcomeState(
      eligible: currentState.eligible,
      lessons: currentState.lessons,
      lessonsRewardClaimedAt: DateTime.now(),
    );
    return Ok(claimResult);
  }

  @override
  Future<void> clearCache(String userId) async {}
}

WelcomeState fakeEligibleWelcomeState({
  Set<WelcomeLessonId> completed = const {},
  DateTime? rewardClaimedAt,
}) => WelcomeState(
  eligible: true,
  lessons: {
    for (final id in WelcomeLessonId.values)
      id: WelcomeLessonProgress(
        id: id,
        startedAt: DateTime(2026, 8, 11),
        completedAt: completed.contains(id)
            ? DateTime(2026, 8, 11, 0, 1)
            : null,
      ),
  },
  lessonsRewardClaimedAt: rewardClaimedAt,
);
