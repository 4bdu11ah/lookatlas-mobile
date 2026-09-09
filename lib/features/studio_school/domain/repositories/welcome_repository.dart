import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_profile_draft.dart';

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

  Future<Result<DashboardChecklistClaim>> claimChecklist(String userId);

  Future<Result<void>> saveProfile(
    String userId,
    WelcomeProfileDraft profile,
  );

  Future<Result<void>> recordEvent(
    String userId,
    String event, {
    Map<String, Object>? properties,
  });

  Future<void> clearCache(String userId);
}
