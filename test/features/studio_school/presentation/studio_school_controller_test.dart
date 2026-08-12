import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_state.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';
import 'package:look_atlas/services/service_providers.dart';

import '../../../helpers/fake_welcome_repository.dart';

void main() {
  Future<ProviderContainer> containerFor(
    FakeWelcomeRepository repository,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWithValue(
          const AsyncData<AppUser?>(
            AppUser(id: 'user-1', email: 'jane@example.com'),
          ),
        ),
        welcomeRepositoryProvider.overrideWithValue(repository),
        analyticsServiceProvider.overrideWithValue(NoopAnalyticsService()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      studioSchoolControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test('load_ineligibleAccount_exposesReadOnlyState', () async {
    final container = await containerFor(FakeWelcomeRepository());

    expect(
      container.read(studioSchoolControllerProvider),
      isA<SchoolReadOnly>(),
    );
  });

  test('complete_serverSuccess_refreshesProgress', () async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(),
    );
    final container = await containerFor(repository);

    final result = await container
        .read(studioSchoolControllerProvider.notifier)
        .completeLesson(WelcomeLessonId.credits);

    expect(result.kind, LessonActionKind.completed);
    expect(repository.completeCalls, 1);
    final state = container.read(studioSchoolControllerProvider) as SchoolReady;
    expect(
      state.welcome.progressFor(WelcomeLessonId.credits).isCompleted,
      isTrue,
    );
  });

  test('complete_tooFast_usesAuthoritativeRetryDuration', () async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(),
      completeFailure: const NetworkFailure(
        'Too fast',
        statusCode: 409,
        code: 'TOO_FAST',
        details: {'retryInMs': 2750},
      ),
    );
    final container = await containerFor(repository);

    final result = await container
        .read(studioSchoolControllerProvider.notifier)
        .completeLesson(WelcomeLessonId.credits);

    expect(result.kind, LessonActionKind.tooFast);
    expect(result.retryAfter, const Duration(milliseconds: 2750));
  });

  test('claim_allLessonsComplete_claimsOnceAndRefreshes', () async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(
        completed: WelcomeLessonId.values.toSet(),
      ),
    );
    final container = await containerFor(repository);

    final result = await container
        .read(studioSchoolControllerProvider.notifier)
        .claimReward();

    expect(result.succeeded, isTrue);
    expect(repository.claimCalls, 1);
    expect(result.message, '20 free credits added.');
  });
}
