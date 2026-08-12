import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';

abstract final class WelcomeDto {
  static WelcomeState state(dynamic data, {bool isCached = false}) {
    final json = _map(data);
    final eligible = json['eligible'] as bool? ?? false;
    final progress = <WelcomeLessonId, WelcomeLessonProgress>{};
    for (final item in json['lessons'] as List? ?? const []) {
      if (item is! Map<String, dynamic>) continue;
      final rawId = item['id'];
      final id = rawId is String ? WelcomeLessonId.fromApi(rawId) : null;
      if (id == null) continue;
      progress[id] = WelcomeLessonProgress(
        id: id,
        startedAt: _date(item['startedAt'] ?? item['started_at']),
        completedAt: _date(item['completedAt'] ?? item['completed_at']),
      );
    }
    return WelcomeState(
      eligible: eligible,
      lessons: Map.unmodifiable(progress),
      lessonsRewardClaimedAt: _date(
        json['lessonsRewardClaimedAt'] ?? json['lessons_reward_claimed_at'],
      ),
      isCached: isCached,
    );
  }

  static DateTime timestamp(dynamic data, String key) {
    final value = _date(_map(data)[key]);
    if (value == null) {
      throw FormatException('Welcome response did not include $key.');
    }
    return value;
  }

  static LessonClaimResult claim(dynamic data) {
    final json = _map(data);
    return LessonClaimResult(
      granted: (json['granted'] as num?)?.toInt() ?? 0,
      alreadyClaimed: json['alreadyClaimed'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> toJson(WelcomeState state) => {
    'eligible': state.eligible,
    'lessons': [
      for (final id in WelcomeLessonId.values)
        if (state.lessons[id] case final lesson?)
          {
            'id': id.apiValue,
            'startedAt': lesson.startedAt?.toUtc().toIso8601String(),
            'completedAt': lesson.completedAt?.toUtc().toIso8601String(),
          },
    ],
    'lessonsRewardClaimedAt': state.lessonsRewardClaimedAt
        ?.toUtc()
        .toIso8601String(),
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Map<String, dynamic> _map(dynamic data) =>
      data is Map<String, dynamic> ? data : const {};
}
