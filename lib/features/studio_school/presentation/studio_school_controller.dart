import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_state.dart';
import 'package:look_atlas/services/service_providers.dart';

class StudioSchoolController extends Notifier<StudioSchoolLoadState> {
  String? _userId;
  int _loadGeneration = 0;
  bool _claiming = false;

  @override
  StudioSchoolLoadState build() {
    final previousUserId = _userId;
    _userId = ref.watch(authStateProvider).value?.id;
    if (previousUserId != null && previousUserId != _userId) {
      unawaited(
        ref.read(welcomeRepositoryProvider).clearCache(previousUserId),
      );
    }
    final generation = ++_loadGeneration;
    unawaited(Future<void>.microtask(() => _load(generation: generation)));
    return const SchoolLoading();
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    final current = state;
    state = switch (current) {
      SchoolReady(:final welcome) => SchoolReady(welcome, refreshing: true),
      SchoolOfflineCached(:final welcome) => SchoolOfflineCached(
        welcome,
        refreshing: true,
      ),
      _ => const SchoolLoading(),
    };
    await _load(generation: ++_loadGeneration, forceRefresh: forceRefresh);
  }

  Future<DateTime?> startLesson(WelcomeLessonId lessonId) async {
    final ready = _welcome;
    final userId = _userId;
    if (userId == null || ready == null || !ready.eligible) return null;
    final existing = ready.progressFor(lessonId).startedAt;

    final result = await ref
        .read(welcomeRepositoryProvider)
        .startLesson(userId, lessonId);
    if (result.valueOrNull case final startedAt?) {
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .track(
              'welcome.lesson_started',
              properties: {'lesson': lessonId.apiValue},
            ),
      );
      return startedAt;
    }
    return existing;
  }

  Future<LessonActionResult> completeLesson(WelcomeLessonId lessonId) async {
    final welcome = _welcome;
    final userId = _userId;
    if (welcome == null || !welcome.eligible || userId == null) {
      return const LessonActionResult(LessonActionKind.alreadyCompleted);
    }
    if (welcome.progressFor(lessonId).isCompleted) {
      return const LessonActionResult(LessonActionKind.alreadyCompleted);
    }

    final result = await ref
        .read(welcomeRepositoryProvider)
        .completeLesson(userId, lessonId);
    if (result.isOk) {
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .track(
              'welcome.lesson_completed',
              properties: {'lesson': lessonId.apiValue},
            ),
      );
      await refresh();
      return const LessonActionResult(LessonActionKind.completed);
    }
    final failure = result.failureOrNull!;
    final code = failure is NetworkFailure ? failure.code : null;
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            'welcome.lesson_completion_failed',
            properties: {
              'lesson': lessonId.apiValue,
              'code': ?code,
            },
          ),
    );
    if (code == 'NOT_SUBSCRIBER' || code == 'UNKNOWN_LESSON') {
      if (code == 'UNKNOWN_LESSON') {
        AppLogger.error(
          'Studio School lesson ID rejected: ${lessonId.apiValue}',
        );
      }
      await refresh();
    }
    return _lessonFailure(failure);
  }

  Future<RewardActionResult> claimReward() async {
    if (_claiming) {
      return const RewardActionResult(
        succeeded: false,
        message: 'Credit claim is already in progress.',
      );
    }
    final userId = _userId;
    final welcome = _welcome;
    if (userId == null || welcome == null || !welcome.canClaimReward) {
      return const RewardActionResult(
        succeeded: false,
        message: "One lesson isn't finished yet.",
      );
    }
    _claiming = true;
    final result = await ref
        .read(welcomeRepositoryProvider)
        .claimLessons(userId);
    _claiming = false;
    if (result.valueOrNull case final claim?) {
      if (claim.granted > 0) {
        unawaited(
          ref
              .read(analyticsServiceProvider)
              .track(
                'welcome.reward_claimed',
                properties: {'kind': 'lessons'},
              ),
        );
      }
      ref.invalidate(dashboardStatsProvider);
      await refresh();
      return RewardActionResult(
        succeeded: true,
        message: claim.alreadyClaimed
            ? 'Your lesson reward was already claimed.'
            : '20 free credits added.',
      );
    }
    final failure = result.failureOrNull!;
    final code = failure is NetworkFailure ? failure.code : null;
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            'welcome.reward_claim_failed',
            properties: {'code': ?code},
          ),
    );
    if (failure case NetworkFailure(code: 'LESSONS_INCOMPLETE')) {
      await refresh();
      return const RewardActionResult(
        succeeded: false,
        message: "One lesson isn't finished yet.",
      );
    }
    if (failure case NetworkFailure(code: 'NOT_SUBSCRIBER')) await refresh();
    return RewardActionResult(succeeded: false, message: failure.message);
  }

  WelcomeState? get _welcome => switch (state) {
    SchoolReady(:final welcome) ||
    SchoolOfflineCached(:final welcome) => welcome,
    _ => null,
  };

  Future<void> _load({
    required int generation,
    bool forceRefresh = false,
  }) async {
    final userId = _userId;
    if (userId == null) {
      if (generation == _loadGeneration) state = const SchoolReadOnly();
      return;
    }
    late final Result<WelcomeState> result;
    try {
      result = await ref
          .read(welcomeRepositoryProvider)
          .getState(userId, forceRefresh: forceRefresh);
    } on Object catch (error, stackTrace) {
      if (generation == _loadGeneration) {
        state = SchoolFailure(
          UnknownFailure(
            'Progress could not load. Please try again.',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
      return;
    }
    if (generation != _loadGeneration) return;
    state = result.fold(
      (welcome) {
        if (!welcome.eligible) return const SchoolReadOnly();
        if (welcome.isCached) return SchoolOfflineCached(welcome);
        return SchoolReady(welcome);
      },
      SchoolFailure.new,
    );
  }

  LessonActionResult _lessonFailure(Failure failure) {
    if (failure case NetworkFailure(code: 'TOO_FAST', :final details)) {
      final retryMs = (details['retryInMs'] as num?)?.toInt() ?? 1500;
      return LessonActionResult(
        LessonActionKind.tooFast,
        retryAfter: Duration(milliseconds: retryMs),
      );
    }
    if (failure case NetworkFailure(code: 'NOT_STARTED')) {
      return const LessonActionResult(LessonActionKind.notStarted);
    }
    return LessonActionResult(
      LessonActionKind.failed,
      message: failure.message,
    );
  }
}

final NotifierProvider<StudioSchoolController, StudioSchoolLoadState>
studioSchoolControllerProvider =
    NotifierProvider.autoDispose<StudioSchoolController, StudioSchoolLoadState>(
      StudioSchoolController.new,
    );
