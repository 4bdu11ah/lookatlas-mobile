import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/connectivity/connectivity_provider.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/lesson_player_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/credit_calculator.dart';

import '../../../helpers/fake_welcome_repository.dart';

class _TimedRepository extends FakeWelcomeRepository {
  _TimedRepository(this.startedAt, {super.completeFailure})
    : super(state: fakeEligibleWelcomeState());
  final DateTime startedAt;
  @override
  Future<Result<DateTime>> startLesson(
    String userId,
    WelcomeLessonId id,
  ) async {
    startCalls++;
    return startFailure == null ? Ok(startedAt) : Err(startFailure!);
  }
}

class _DelayedWelcomeRepository extends _TimedRepository {
  _DelayedWelcomeRepository(super.startedAt);
  final loaded = Completer<Result<WelcomeState>>();

  @override
  Future<Result<WelcomeState>> getState(
    String userId, {
    bool forceRefresh = false,
  }) => loaded.future;
}

void main() {
  var clock = DateTime.utc(2026, 9, 15);
  setUp(() => clock = DateTime.utc(2026, 9, 15));

  Future<ProviderContainer> containerFor(
    _TimedRepository repository, {
    bool online = true,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWithValue(
          const AsyncData(AppUser(id: 'user-1', email: 'jane@example.com')),
        ),
        welcomeRepositoryProvider.overrideWithValue(repository),
        connectionStatusProvider.overrideWithValue(online),
        lessonClockProvider.overrideWithValue(() => clock),
      ],
    );
    addTearDown(container.dispose);
    container.listen(studioSchoolControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    container.listen(
      lessonPlayerControllerProvider(WelcomeLessonId.credits),
      (_, _) {},
    );
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test('player_progressLoadsAfterOpening_startsTracking', () async {
    final repository = _DelayedWelcomeRepository(clock);
    final container = await containerFor(repository);
    expect(repository.startCalls, 0);

    repository.loaded.complete(Ok(fakeEligibleWelcomeState()));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repository.startCalls, 1);
    expect(
      container
          .read(lessonPlayerControllerProvider(WelcomeLessonId.credits))
          .readyAt,
      clock.add(LessonPlayerController.minimumView),
    );
  });

  test('player_connectionRestored_startsTracking', () async {
    final repository = _TimedRepository(clock);
    final container = await containerFor(repository, online: false);
    expect(repository.startCalls, 0);

    container.updateOverrides([
      authStateProvider.overrideWithValue(
        const AsyncData(AppUser(id: 'user-1', email: 'jane@example.com')),
      ),
      welcomeRepositoryProvider.overrideWithValue(repository),
      connectionStatusProvider.overrideWithValue(true),
      lessonClockProvider.overrideWithValue(() => clock),
    ]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repository.startCalls, 1);
    expect(
      container
          .read(lessonPlayerControllerProvider(WelcomeLessonId.credits))
          .readyAt,
      clock.add(LessonPlayerController.minimumView),
    );
  });

  test('player_beforeMinimumDuration_doesNotComplete', () async {
    final repository = _TimedRepository(clock);
    final container = await containerFor(repository);
    clock = clock.add(const Duration(seconds: 20));
    await container
        .read(lessonPlayerControllerProvider(WelcomeLessonId.credits).notifier)
        .complete(tracked: true);
    expect(repository.completeCalls, 0);
    expect(
      container
          .read(lessonPlayerControllerProvider(WelcomeLessonId.credits))
          .completed,
      isFalse,
    );
  });

  test('player_atPaddedMinimumDuration_savesCompletion', () async {
    final repository = _TimedRepository(clock);
    final container = await containerFor(repository);
    clock = clock.add(LessonPlayerController.minimumView);
    await container
        .read(lessonPlayerControllerProvider(WelcomeLessonId.credits).notifier)
        .complete(tracked: true);
    expect(repository.completeCalls, 1);
    expect(
      container
          .read(lessonPlayerControllerProvider(WelcomeLessonId.credits))
          .completed,
      isTrue,
    );
  });

  test('player_serverTooFast_usesRetryDuration', () async {
    final repository = _TimedRepository(
      clock,
      completeFailure: const NetworkFailure(
        'Lesson viewed too quickly',
        code: 'TOO_FAST',
        details: {'retryInMs': 7500},
      ),
    );
    final container = await containerFor(repository);
    clock = clock.add(const Duration(seconds: 21));
    await container
        .read(lessonPlayerControllerProvider(WelcomeLessonId.credits).notifier)
        .complete(tracked: true);
    final state = container.read(
      lessonPlayerControllerProvider(WelcomeLessonId.credits),
    );
    expect(state.readyAt, clock.add(const Duration(milliseconds: 7500)));
    expect(state.error, 'Almost there. Give it 8 more seconds.');
    expect(state.completed, isFalse);
  });

  test('player_serverNotStarted_startsAgain', () async {
    final repository = _TimedRepository(
      clock,
      completeFailure: const NetworkFailure(
        'Start the lesson first',
        code: 'NOT_STARTED',
      ),
    );
    final container = await containerFor(repository);
    clock = clock.add(const Duration(seconds: 21));
    await container
        .read(lessonPlayerControllerProvider(WelcomeLessonId.credits).notifier)
        .complete(tracked: true);
    expect(repository.startCalls, 2);
    expect(
      container
          .read(lessonPlayerControllerProvider(WelcomeLessonId.credits))
          .saving,
      isFalse,
    );
  });

  test('player_offline_doesNotSendCompletion', () async {
    final repository = _TimedRepository(clock);
    final container = await containerFor(repository, online: false);
    await container
        .read(lessonPlayerControllerProvider(WelcomeLessonId.credits).notifier)
        .complete(tracked: true);
    expect(repository.startCalls, 0);
    expect(repository.completeCalls, 0);
  });

  test('player_cardNavigation_staysWithinLesson', () async {
    final container = await containerFor(_TimedRepository(clock));
    final controller = container.read(
      lessonPlayerControllerProvider(WelcomeLessonId.credits).notifier,
    )..previous();
    expect(
      container
          .read(lessonPlayerControllerProvider(WelcomeLessonId.credits))
          .cardIndex,
      0,
    );
    for (var i = 0; i < 8; i++) {
      controller.next();
    }
    expect(
      container
          .read(lessonPlayerControllerProvider(WelcomeLessonId.credits))
          .cardIndex,
      3,
    );
    controller.previous();
    expect(
      container
          .read(lessonPlayerControllerProvider(WelcomeLessonId.credits))
          .cardIndex,
      2,
    );
  });

  test('calculator_defaults_mapsAllResolutionCosts', () {
    const state = CreditCalculatorState();
    expect(
      [
        state.images,
        state.standardCredits,
        state.hdCredits,
        state.fourKCredits,
        state.businessPacedCredits,
      ],
      [15, 15, 30, 45, 0],
    );
  });

  test('calculator_input_clampsToSliderBounds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(creditCalculatorProvider, (_, _) {});
    container.read(creditCalculatorProvider.notifier)
      ..setShots(20)
      ..setVariations(-2);
    final state = container.read(creditCalculatorProvider);
    expect(state.shots, 10);
    expect(state.variations, 1);
    expect(state.images, 10);
  });
}
