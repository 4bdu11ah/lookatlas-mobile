import 'package:flutter/foundation.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';

enum WelcomeLessonId {
  credits('credits'),
  workshop('workshop'),
  directors('directors'),
  refunds('refunds'),
  imageRights('image_rights'),
  rollover('rollover');

  const WelcomeLessonId(this.apiValue);

  final String apiValue;

  static WelcomeLessonId? fromApi(String value) {
    for (final id in values) {
      if (id.apiValue == value) return id;
    }
    return null;
  }
}

@immutable
class WelcomeLessonProgress {
  const WelcomeLessonProgress({
    required this.id,
    this.startedAt,
    this.completedAt,
  });

  final WelcomeLessonId id;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;
}

@immutable
class WelcomeState {
  const WelcomeState({
    required this.eligible,
    required this.lessons,
    this.lessonsRewardClaimedAt,
    this.isCached = false,
    this.dashboard,
  });

  const WelcomeState.readOnly()
    : eligible = false,
      lessons = const {},
      lessonsRewardClaimedAt = null,
      isCached = false,
      dashboard = null;

  final bool eligible;
  final Map<WelcomeLessonId, WelcomeLessonProgress> lessons;
  final DateTime? lessonsRewardClaimedAt;
  final bool isCached;
  final DashboardWelcomeState? dashboard;

  int get completedCount =>
      lessons.values.where((lesson) => lesson.isCompleted).length;

  bool get canClaimReward =>
      eligible &&
      completedCount == WelcomeLessonId.values.length &&
      lessonsRewardClaimedAt == null &&
      !isCached;

  WelcomeLessonProgress progressFor(WelcomeLessonId id) =>
      lessons[id] ?? WelcomeLessonProgress(id: id);

  WelcomeState copyWith({bool? isCached}) => WelcomeState(
    eligible: eligible,
    lessons: lessons,
    lessonsRewardClaimedAt: lessonsRewardClaimedAt,
    isCached: isCached ?? this.isCached,
    dashboard: dashboard,
  );
}

@immutable
class LessonClaimResult {
  const LessonClaimResult({
    required this.granted,
    required this.alreadyClaimed,
  });

  final int granted;
  final bool alreadyClaimed;
}
