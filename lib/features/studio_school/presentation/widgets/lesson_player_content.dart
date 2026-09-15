import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/lesson_player_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/models/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/credit_calculator.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LessonPlayerCardBody extends StatelessWidget {
  const LessonPlayerCardBody({
    required this.card,
    required this.tryLink,
    required this.onTry,
    required this.index,
    required this.count,
    super.key,
  });
  final LessonCardDefinition card;
  final SchoolLink? tryLink;
  final ValueChanged<String> onTry;
  final int index;
  final int count;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(22, 42, 22, 36),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LearningKicker('Idea ${index + 1} of $count'),
        const SizedBox(height: 14),
        Text(
          card.title,
          style: LearningCenterStyle.serif(43, height: 0.98, tracking: -0.04),
        ),
        const SizedBox(height: 14),
        Text(card.body, style: LearningCenterStyle.body(14.5, height: 1.72)),
        if (card.hasCalculator) const CreditCalculator(),
        if (tryLink case final link?)
          Padding(
            padding: const EdgeInsets.only(top: 26),
            child: TextButton.icon(
              onPressed: () => onTry(link.location),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: LearningCenterStyle.ink,
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(LucideIcons.arrowRight, size: 14),
              label: Text(
                link.label,
                style: LearningCenterStyle.body(
                  11,
                  color: LearningCenterStyle.ink,
                  weight: FontWeight.w700,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
      ],
    ),
  );
}

class LessonPlayerFooter extends ConsumerWidget {
  const LessonPlayerFooter({
    required this.lessonId,
    required this.state,
    required this.isFinal,
    required this.timerRequired,
    required this.online,
    required this.actions,
    super.key,
  });
  final WelcomeLessonId lessonId;
  final LessonPlayerState state;
  final bool isFinal;
  final bool timerRequired;
  final bool online;
  final ({
    VoidCallback previous,
    VoidCallback next,
    VoidCallback done,
    VoidCallback retry,
  })
  actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = timerRequired
        ? ref.watch(lessonRemainingProvider(lessonId)).asData?.value ??
              LessonPlayerController.minimumView
        : Duration.zero;
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    final enabled =
        !state.saving &&
        (!timerRequired ||
            (online && state.readyAt != null && remaining == Duration.zero));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: LearningCenterStyle.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.error != null) _error(),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _status(seconds),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 42,
                    child: LearningAction(
                      '',
                      outlined: true,
                      height: 42,
                      icon: LucideIcons.chevronLeft,
                      onPressed: state.cardIndex > 0 && !state.saving
                          ? actions.previous
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isFinal)
                    LearningAction(
                      'Next',
                      height: 42,
                      icon: LucideIcons.chevronRight,
                      onPressed: state.saving ? null : actions.next,
                    )
                  else
                    _completeAction(remaining, seconds, enabled),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _error() => Row(
    children: [
      Expanded(
        child: Text(
          state.error!,
          style: LearningCenterStyle.body(
            11,
            color: const Color(0xFFB42318),
          ),
        ),
      ),
      if (state.error!.contains('could not start'))
        TextButton(
          onPressed: actions.retry,
          child: const Text('Retry'),
        ),
    ],
  );

  Widget _status(int seconds) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        LucideIcons.clock,
        size: 14,
        color: LearningCenterStyle.muted,
      ),
      const SizedBox(width: 7),
      Text(
        seconds > 0
            ? 'Take a moment. ${seconds}s left.'
            : 'Ready when you are.',
        style: LearningCenterStyle.body(11),
      ),
    ],
  );

  Widget _completeAction(Duration remaining, int seconds, bool enabled) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (timerRequired && seconds > 0)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              value:
                  (1 -
                          remaining.inMilliseconds /
                              LessonPlayerController.minimumView.inMilliseconds)
                      .clamp(0, 1),
              strokeWidth: 3,
              color: LearningCenterStyle.ink,
            ),
          ),
        ),
      LearningAction(
        state.saving ? 'Saving' : 'Complete lesson',
        key: const ValueKey('studio-school-done'),
        height: 42,
        icon: LucideIcons.check,
        onPressed: enabled ? actions.done : null,
      ),
    ],
  );
}

class LessonSuccess extends StatelessWidget {
  const LessonSuccess({
    required this.onNext,
    required this.onClose,
    required this.saved,
    required this.tryLink,
    required this.onTry,
    super.key,
  });
  final VoidCallback? onNext;
  final VoidCallback onClose;
  final bool saved;
  final SchoolLink? tryLink;
  final ValueChanged<String> onTry;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          Container(
            width: 51,
            height: 51,
            color: LearningCenterStyle.ink,
            child: const Icon(
              LucideIcons.check,
              size: 22,
              color: LearningCenterStyle.paper,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            saved ? 'PROGRESS SAVED' : 'LESSON REVIEWED',
            style: LearningCenterStyle.body(
              11,
              weight: FontWeight.w700,
            ).copyWith(letterSpacing: 1.65),
          ),
          const SizedBox(height: 12),
          Text(
            'Lesson complete.',
            style: LearningCenterStyle.serif(43, tracking: -0.04),
          ),
          const SizedBox(height: 12),
          Text(
            'You can come back to this lesson any time. Your next useful answer is ready when you are.',
            textAlign: TextAlign.center,
            style: LearningCenterStyle.body(12.5),
          ),
          const SizedBox(height: 26),
          if (onNext != null)
            SizedBox(
              width: double.infinity,
              child: LearningAction('Next lesson', onPressed: onNext),
            ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: LearningAction(
              'Back to Learning Center',
              outlined: true,
              icon: null,
              onPressed: onClose,
            ),
          ),
          if (tryLink case final link?)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: LearningAction(
                link.label,
                outlined: true,
                onPressed: () => onTry(link.location),
              ),
            ),
        ],
      ),
    ),
  );
}
