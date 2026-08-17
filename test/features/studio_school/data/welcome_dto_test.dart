import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
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

  test('state_dashboardPayload_mapsChecklistAndCampaignConditions', () {
    final state = WelcomeDto.state({
      'eligible': true,
      'dashboard': {
        'steps': {
          'product': true,
          'calibration': true,
          'angles': false,
          'model': false,
          'direction': false,
          'first_shoot': false,
        },
        'callBooked': true,
        'campaign': {
          'firstCompletedJobId': 'job-1',
          'keptImages': 0,
          'images': ['https://example.com/one.jpg'],
        },
      },
    });

    expect(state.dashboard?.completedCount, 2);
    expect(state.dashboard?.steps[DashboardWelcomeStepId.angles], isFalse);
    expect(state.dashboard?.callBooked, isTrue);
    expect(state.dashboard?.campaign?.jobId, 'job-1');
  });

  test('state_canonicalDashboardSteps_mapExistingProductAsComplete', () {
    final state = WelcomeDto.state({
      'eligible': true,
      'dashboard': {
        'steps': {
          'addProduct': true,
          'calibrate': false,
          'pickAngles': false,
          'createModel': false,
          'chooseDirection': false,
          'runShoot': false,
        },
      },
    });

    expect(
      state.dashboard?.steps[DashboardWelcomeStepId.product],
      isTrue,
    );
    expect(state.dashboard?.completedCount, 1);
  });

  test('state_canonicalDashboardSteps_mapAllSixCompletionFields', () {
    final state = WelcomeDto.state({
      'eligible': true,
      'dashboard': {
        'steps': {
          'addProduct': true,
          'calibrate': true,
          'pickAngles': true,
          'createModel': true,
          'chooseDirection': true,
          'runShoot': true,
        },
      },
    });

    expect(state.dashboard?.steps, {
      DashboardWelcomeStepId.product: true,
      DashboardWelcomeStepId.calibration: true,
      DashboardWelcomeStepId.angles: true,
      DashboardWelcomeStepId.model: true,
      DashboardWelcomeStepId.direction: true,
      DashboardWelcomeStepId.firstShoot: true,
    });
    expect(state.dashboard?.checklistComplete, isTrue);
  });

  test('state_cachedDashboard_roundTripsAllConditionFields', () {
    final source = WelcomeDto.state({
      'eligible': true,
      'dashboard': {
        'steps': {
          'product': true,
          'calibrationOptional': true,
          'angles': true,
          'model': true,
          'direction': true,
          'firstShoot': true,
        },
        'profileIncomplete': true,
        'profileFullyEmpty': true,
      },
    });

    final restored = WelcomeDto.state(WelcomeDto.toJson(source));

    expect(restored.dashboard?.checklistComplete, isTrue);
    expect(restored.dashboard?.profileIncomplete, isTrue);
    expect(restored.dashboard?.profileFullyEmpty, isTrue);
  });

  test('state_profilePayload_mapsPrefillAndDropCadence', () {
    final state = WelcomeDto.state({
      'eligible': true,
      'dashboard': {
        'steps': <String, bool>{},
        'profile': {
          'brandUrl': 'shop.example.com',
          'vertical': 'Jewelry',
          'primaryUses': ['ads', 'social'],
          'dropCadence': 'ongoing_drops',
          'referral': 'google',
        },
      },
    });

    expect(state.dashboard?.profile.brandUrl, 'shop.example.com');
    expect(state.dashboard?.profile.primaryUses, ['ads', 'social']);
    expect(state.dashboard?.profile.dropCadence, 'ongoing_drops');
    expect(state.dashboard?.profileIncomplete, isFalse);
  });
}
