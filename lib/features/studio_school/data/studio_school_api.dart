import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/studio_school/data/welcome_dto.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';

abstract interface class StudioSchoolApi {
  Future<Result<WelcomeState>> getState();
  Future<Result<DateTime>> startLesson(WelcomeLessonId lessonId);
  Future<Result<DateTime>> completeLesson(WelcomeLessonId lessonId);
  Future<Result<LessonClaimResult>> claimLessons();
  Future<Result<DashboardChecklistClaim>> claimChecklist();
  Future<Result<void>> saveProfile(Map<String, Object> profile);
  Future<Result<void>> recordEvent(
    String event,
    Map<String, Object>? properties,
  );
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

  @override
  Future<Result<DashboardChecklistClaim>> claimChecklist() =>
      _api.post<DashboardChecklistClaim>(
        ApiEndpoints.welcomeClaimChecklist,
        decoder: (data) {
          final json = data is Map<String, dynamic>
              ? data
              : const <String, dynamic>{};
          return DashboardChecklistClaim(
            granted: (json['granted'] as num?)?.toInt() ?? 0,
            alreadyClaimed: json['alreadyClaimed'] as bool? ?? false,
          );
        },
      );

  @override
  Future<Result<void>> saveProfile(Map<String, Object> profile) =>
      _api.post<void>(
        ApiEndpoints.welcomeProfile,
        data: profile,
        decoder: (_) {},
      );

  @override
  Future<Result<void>> recordEvent(
    String event,
    Map<String, Object>? properties,
  ) => _api.post<void>(
    ApiEndpoints.welcomeEvent,
    data: {'event': event, 'properties': ?properties},
    decoder: (_) {},
  );
}
