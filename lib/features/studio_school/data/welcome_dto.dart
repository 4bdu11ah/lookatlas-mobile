import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
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
      dashboard: _dashboard(json),
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
    if (state.dashboard case final dashboard?)
      'dashboard': _dashboardJson(dashboard),
  };

  static DashboardWelcomeState? _dashboard(Map<String, dynamic> root) {
    final raw = root['dashboard'] ?? root['onboarding'] ?? root;
    if (raw is! Map<String, dynamic>) return null;
    final checklist = raw['checklist'];
    final rawSteps =
        raw['steps'] ??
        raw['checklistSteps'] ??
        (checklist is Map ? checklist['steps'] : null);
    if (rawSteps is! Map && rawSteps is! List) return null;
    final steps = {for (final id in DashboardWelcomeStepId.values) id: false};
    var calibrationOptional = false;
    if (rawSteps is Map) {
      for (final entry in rawSteps.entries) {
        final id = DashboardWelcomeStepId.fromApi(entry.key.toString());
        if (id != null) steps[id] = entry.value == true;
      }
      calibrationOptional = rawSteps['calibrationOptional'] == true;
      if (calibrationOptional) {
        steps[DashboardWelcomeStepId.calibration] = true;
      }
    } else {
      for (final item in rawSteps as List) {
        if (item is! Map) continue;
        final id = DashboardWelcomeStepId.fromApi(
          (item['id'] ?? item['key'] ?? '').toString(),
        );
        if (id != null) steps[id] = item['completed'] == true;
      }
    }
    final campaignRaw = raw['campaign'];
    DashboardWelcomeCampaign? campaign;
    if (campaignRaw is Map<String, dynamic>) {
      final jobId = campaignRaw['firstCompletedJobId'] ?? campaignRaw['jobId'];
      if (jobId is String && jobId.isNotEmpty) {
        campaign = DashboardWelcomeCampaign(
          jobId: jobId,
          keptImages: (campaignRaw['keptImages'] as num?)?.toInt() ?? 0,
          images: _campaignImages(campaignRaw['images']),
        );
      }
    }
    final profile = _profile(raw['profile']);
    return DashboardWelcomeState(
      steps: Map.unmodifiable(steps),
      checklistRewardClaimedAt: _date(
        raw['checklistRewardClaimedAt'] ??
            raw['checklist_reward_claimed_at'] ??
            (checklist is Map
                ? checklist['rewardClaimedAt'] ?? checklist['reward_claimed_at']
                : null),
      ),
      campaign: campaign,
      callBooked: raw['callBooked'] as bool? ?? false,
      flipDismissed: raw['flipDismissed'] as bool? ?? false,
      introSeen: raw['introSeen'] as bool? ?? false,
      calibrationOptional: calibrationOptional,
      profileIncomplete:
          raw['profileIncomplete'] as bool? ?? (profile?.isIncomplete ?? false),
      profileFullyEmpty:
          raw['profileFullyEmpty'] as bool? ?? (profile?.isFullyEmpty ?? false),
      profile: profile ?? const DashboardWelcomeProfile(),
    );
  }

  static Map<String, dynamic> _dashboardJson(DashboardWelcomeState state) => {
    'steps': {
      for (final entry in state.steps.entries) entry.key.name: entry.value,
      'calibrationOptional': state.calibrationOptional,
    },
    'checklistRewardClaimedAt': state.checklistRewardClaimedAt
        ?.toUtc()
        .toIso8601String(),
    'callBooked': state.callBooked,
    'flipDismissed': state.flipDismissed,
    'introSeen': state.introSeen,
    'profileIncomplete': state.profileIncomplete,
    'profileFullyEmpty': state.profileFullyEmpty,
    'profile': {
      'brandUrl': state.profile.brandUrl,
      'vertical': state.profile.vertical,
      'primaryUses': state.profile.primaryUses,
      'dropCadence': state.profile.dropCadence,
      'referral': state.profile.referral,
      'referralOther': state.profile.referralOther,
    },
    if (state.campaign case final campaign?)
      'campaign': {
        'jobId': campaign.jobId,
        'keptImages': campaign.keptImages,
        'images': campaign.images,
      },
  };

  static List<String> _campaignImages(Object? value) => [
    for (final image in value is List ? value : const [])
      if (image is String)
        image
      else if (image is Map && (image['url'] ?? image['src']) is String)
        (image['url'] ?? image['src']) as String,
  ];

  static DashboardWelcomeProfile? _profile(Object? value) {
    if (value is! Map) return null;
    final uses = value['primaryUses'] ?? value['primary_uses'];
    return DashboardWelcomeProfile(
      brandUrl:
          (value['brandUrl'] ?? value['brand_url'])?.toString().trim() ?? '',
      vertical: value['vertical']?.toString().trim() ?? '',
      primaryUses: [
        for (final use in uses is List ? uses : const [])
          if (use is String && use.isNotEmpty) use,
      ],
      dropCadence:
          (value['dropCadence'] ?? value['drop_cadence'] ?? value['cadence'])
              ?.toString()
              .trim(),
      referral: value['referral']?.toString().trim(),
      referralOther:
          (value['referralOther'] ?? value['referral_other'])
              ?.toString()
              .trim() ??
          '',
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Map<String, dynamic> _map(dynamic data) =>
      data is Map<String, dynamic> ? data : const {};
}
