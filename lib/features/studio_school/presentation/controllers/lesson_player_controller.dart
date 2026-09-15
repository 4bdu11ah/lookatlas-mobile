import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/connectivity/connectivity_provider.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_state.dart';
import 'package:look_atlas/features/studio_school/presentation/models/studio_school_catalog.dart';
import 'package:riverpod/misc.dart';

final lessonClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class LessonPlayerState {
  const LessonPlayerState({
    this.cardIndex = 0,
    this.saving = false,
    this.completed = false,
    this.readyAt,
    this.error,
  });

  final int cardIndex;
  final bool saving;
  final bool completed;
  final DateTime? readyAt;
  final String? error;

  LessonPlayerState copyWith({
    int? cardIndex,
    bool? saving,
    bool? completed,
    DateTime? readyAt,
    String? error,
    bool clearError = false,
  }) => LessonPlayerState(
    cardIndex: cardIndex ?? this.cardIndex,
    saving: saving ?? this.saving,
    completed: completed ?? this.completed,
    readyAt: readyAt ?? this.readyAt,
    error: clearError ? null : error ?? this.error,
  );
}

class LessonPlayerController extends Notifier<LessonPlayerState> {
  LessonPlayerController(this.lessonId);

  static const minimumView = Duration(milliseconds: 20500);
  final WelcomeLessonId lessonId;
  bool _starting = false;

  @override
  LessonPlayerState build() {
    ref.listen(studioSchoolControllerProvider, (_, next) {
      if (next is SchoolReady) _startIfNeeded();
    });
    ref.listen(connectionStatusProvider, (_, online) {
      if (online) _startIfNeeded();
    });
    unawaited(Future<void>.microtask(start));
    return const LessonPlayerState();
  }

  void _startIfNeeded() {
    if (state.readyAt == null && !state.completed) unawaited(start());
  }

  Future<void> start() async {
    if (!ref.mounted || _starting) return;
    final school = ref.read(studioSchoolControllerProvider);
    final welcome = switch (school) {
      SchoolReady(:final welcome) ||
      SchoolOfflineCached(:final welcome) => welcome,
      _ => null,
    };
    if (welcome == null || welcome.progressFor(lessonId).isCompleted) return;
    if (!ref.read(connectionStatusProvider)) {
      state = state.copyWith(error: 'Reconnect to save lesson progress.');
      return;
    }
    _starting = true;
    final startedAt = await ref
        .read(studioSchoolControllerProvider.notifier)
        .startLesson(lessonId);
    _starting = false;
    if (!ref.mounted) return;
    state = startedAt == null
        ? state.copyWith(
            error: 'Progress could not start. Check your connection.',
          )
        : state.copyWith(readyAt: startedAt.add(minimumView), clearError: true);
  }

  void previous() {
    if (state.cardIndex > 0 && !state.saving) {
      state = state.copyWith(cardIndex: state.cardIndex - 1);
    }
  }

  void next() {
    final count = studioSchoolLessons
        .firstWhere((lesson) => lesson.id == lessonId)
        .cards
        .length;
    if (state.cardIndex < count - 1 && !state.saving) {
      state = state.copyWith(cardIndex: state.cardIndex + 1);
    }
  }

  Future<void> complete({required bool tracked}) async {
    if (state.saving || state.completed) return;
    if (!tracked) {
      state = state.copyWith(completed: true);
      return;
    }
    if (!ref.read(connectionStatusProvider)) return;
    final readyAt = state.readyAt;
    if (readyAt == null || ref.read(lessonClockProvider)().isBefore(readyAt)) {
      return;
    }
    state = state.copyWith(saving: true, clearError: true);
    final result = await ref
        .read(studioSchoolControllerProvider.notifier)
        .completeLesson(lessonId);
    if (!ref.mounted) return;
    switch (result.kind) {
      case LessonActionKind.completed:
      case LessonActionKind.alreadyCompleted:
        state = state.copyWith(saving: false, completed: true);
      case LessonActionKind.tooFast:
        final retry = result.retryAfter ?? const Duration(seconds: 2);
        state = state.copyWith(
          saving: false,
          readyAt: ref.read(lessonClockProvider)().add(retry),
          error:
              'Almost there. Give it ${(retry.inMilliseconds / 1000).ceil()} more seconds.',
        );
      case LessonActionKind.notStarted:
        state = state.copyWith(
          saving: false,
          readyAt: ref.read(lessonClockProvider)().add(minimumView),
          error: 'Start the lesson first.',
        );
        await start();
      case LessonActionKind.failed:
        state = state.copyWith(
          saving: false,
          error: result.message ?? 'Progress could not be saved. Try again.',
        );
    }
  }
}

final NotifierProviderFamily<
  LessonPlayerController,
  LessonPlayerState,
  WelcomeLessonId
>
lessonPlayerControllerProvider = NotifierProvider.autoDispose
    .family<LessonPlayerController, LessonPlayerState, WelcomeLessonId>(
      LessonPlayerController.new,
    );

final StreamProviderFamily<Duration, WelcomeLessonId> lessonRemainingProvider =
    StreamProvider.autoDispose.family<Duration, WelcomeLessonId>((ref, id) {
      final readyAt = ref.watch(
        lessonPlayerControllerProvider(id).select((state) => state.readyAt),
      );
      final now = ref.watch(lessonClockProvider);
      Duration remaining() {
        if (readyAt == null) return LessonPlayerController.minimumView;
        final duration = readyAt.difference(now());
        return duration.isNegative ? Duration.zero : duration;
      }

      return Stream<Duration>.multi((controller) {
        controller.add(remaining());
        final timer = Timer.periodic(
          const Duration(milliseconds: 250),
          (_) => controller.add(remaining()),
        );
        controller.onCancel = timer.cancel;
      });
    });
