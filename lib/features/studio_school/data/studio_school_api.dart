import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/studio_school/data/welcome_dto.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';

abstract interface class StudioSchoolApi {
  Future<Result<WelcomeState>> getState();
  Future<Result<DateTime>> startLesson(WelcomeLessonId lessonId);
  Future<Result<DateTime>> completeLesson(WelcomeLessonId lessonId);
  Future<Result<LessonClaimResult>> claimLessons();
}

class StudioSchoolApiImpl implements StudioSchoolApi {
  const StudioSchoolApiImpl(this._api);

  final ApiService _api;

  @override
  Future<Result<WelcomeState>> getState() => _api.get<WelcomeState>(
    ApiEndpoints.welcomeState,
    decoder: WelcomeDto.state,
  );

  @override
  Future<Result<DateTime>> startLesson(WelcomeLessonId lessonId) =>
      _api.post<DateTime>(
        ApiEndpoints.welcomeLessonStart(lessonId.apiValue),
        decoder: (data) => WelcomeDto.timestamp(data, 'startedAt'),
      );

  @override
  Future<Result<DateTime>> completeLesson(WelcomeLessonId lessonId) =>
      _api.post<DateTime>(
        ApiEndpoints.welcomeLessonComplete(lessonId.apiValue),
        decoder: (data) => WelcomeDto.timestamp(data, 'completedAt'),
      );

  @override
  Future<Result<LessonClaimResult>> claimLessons() =>
      _api.post<LessonClaimResult>(
        ApiEndpoints.welcomeClaimLessons,
        decoder: WelcomeDto.claim,
      );
}
