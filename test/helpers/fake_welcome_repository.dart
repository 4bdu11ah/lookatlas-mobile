import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_repository.dart';

class FakeWelcomeRepository implements WelcomeRepository {
  FakeWelcomeRepository({
    WelcomeState? state,
    this.getFailure,
    this.startFailure,
    this.completeFailure,
    this.claimFailure,
    this.saveProfileFailure,
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
  final Failure? saveProfileFailure;
  final LessonClaimResult claimResult;

  int getCalls = 0;
  int startCalls = 0;
  int completeCalls = 0;
  int claimCalls = 0;
  int checklistClaimCalls = 0;
  int saveProfileCalls = 0;
  Map<String, Object>? savedProfile;
  final List<String> events = [];
  final List<String> operations = [];

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
      dashboard: currentState.dashboard,
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
      dashboard: currentState.dashboard,
    );
    return Ok(claimResult);
  }

  @override
  Future<void> clearCache(String userId) async {}

  @override
  Future<Result<DashboardChecklistClaim>> claimChecklist(String userId) async {
    checklistClaimCalls++;
    final dashboard = currentState.dashboard;
    if (dashboard != null) {
      currentState = WelcomeState(
        eligible: currentState.eligible,
        lessons: currentState.lessons,
        lessonsRewardClaimedAt: currentState.lessonsRewardClaimedAt,
        dashboard: dashboard.copyWith(checklistRewardClaimedAt: DateTime.now()),
      );
    }
    return const Result.ok(
      DashboardChecklistClaim(granted: 20, alreadyClaimed: false),
    );
  }

  @override
  Future<Result<void>> saveProfile(
    String userId,
    Map<String, Object> profile,
  ) async {
    saveProfileCalls++;
    savedProfile = profile;
    operations.add('save_profile');
    if (saveProfileFailure case final failure?) return Err(failure);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> recordEvent(
    String userId,
    String event, {
    Map<String, Object>? properties,
  }) async {
    events.add(event);
    operations.add('event:$event');
    return const Result.ok(null);
  }
}

WelcomeState fakeEligibleWelcomeState({
  Set<WelcomeLessonId> completed = const {},
  DateTime? rewardClaimedAt,
  DashboardWelcomeState? dashboard,
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
  dashboard: dashboard,
);

DashboardWelcomeState fakeDashboardWelcomeState({
  int completed = 3,
  DateTime? rewardClaimedAt,
  DashboardWelcomeCampaign? campaign,
  bool callBooked = false,
  bool flipDismissed = false,
  bool profileIncomplete = false,
  bool profileFullyEmpty = false,
}) => DashboardWelcomeState(
  steps: {
    for (final step in DashboardWelcomeStepId.values)
      step: step.index < completed,
  },
  checklistRewardClaimedAt: rewardClaimedAt,
  campaign: campaign,
  callBooked: callBooked,
  flipDismissed: flipDismissed,
  introSeen: true,
  profileIncomplete: profileIncomplete,
  profileFullyEmpty: profileFullyEmpty,
);
