import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';

abstract interface class WelcomeRepository {
  Future<Result<WelcomeState>> getState(
    String userId, {
    bool forceRefresh = false,
  });

  Future<Result<DateTime>> startLesson(
    String userId,
    WelcomeLessonId lessonId,
  );

  Future<Result<DateTime>> completeLesson(
    String userId,
    WelcomeLessonId lessonId,
  );

  Future<Result<LessonClaimResult>> claimLessons(String userId);

  Future<void> clearCache(String userId);
}
