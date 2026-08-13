import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/studio_school/domain/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/credit_calculator.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

class LessonPlayerCardBody extends StatelessWidget {
  const LessonPlayerCardBody({
    required this.card,
    required this.tryLink,
    required this.onTry,
    super.key,
  });

  final LessonCardDefinition card;
  final SchoolLink? tryLink;
  final ValueChanged<String> onTry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              card.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral500,
              ),
            ),
            if (card.hasCalculator) const CreditCalculator(),
            if (tryLink case final link?) ...[
              const SizedBox(height: 18),
              Semantics(
                link: true,
                child: TextButton.icon(
                  onPressed: () => onTry(link.location),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.black,
                    padding: EdgeInsets.zero,
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(
                    link.label,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LessonPlayerFooter extends StatelessWidget {
  const LessonPlayerFooter({
    required this.showPrevious,
    required this.isFinal,
    required this.countdown,
    required this.timerRequired,
    required this.completionAllowed,
    required this.saving,
    required this.error,
    required this.onPrevious,
    required this.onNext,
    required this.onDone,
    required this.onRetryStart,
    super.key,
  });

  final bool showPrevious;
  final bool isFinal;
  final ValueListenable<Duration> countdown;
  final bool timerRequired;
  final bool completionAllowed;
  final bool saving;
  final String? error;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onDone;
  final VoidCallback onRetryStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error case final message?) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.dangerDark,
                  ),
                ),
              ),
              if (message.contains('could not start'))
                TextButton(
                  onPressed: onRetryStart,
                  child: const Text('Retry'),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ValueListenableBuilder<Duration>(
          valueListenable: countdown,
          builder: (_, remaining, _) => _FooterActions(
            showPrevious: showPrevious,
            isFinal: isFinal,
            doneEnabled:
                !saving &&
                completionAllowed &&
                (!timerRequired || remaining == Duration.zero),
            completionAllowed: completionAllowed,
            saving: saving,
            remaining: remaining,
            onPrevious: onPrevious,
            onNext: onNext,
            onDone: onDone,
          ),
        ),
      ],
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.showPrevious,
    required this.isFinal,
    required this.doneEnabled,
    required this.completionAllowed,
    required this.saving,
    required this.remaining,
    required this.onPrevious,
    required this.onNext,
    required this.onDone,
  });

  final bool showPrevious;
  final bool isFinal;
  final bool doneEnabled;
  final bool completionAllowed;
  final bool saving;
  final Duration remaining;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final seconds = remaining.inMilliseconds <= 0
        ? 0
        : (remaining.inMilliseconds / 1000).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showPrevious)
          AppOutlinedButton(
            label: 'Previous',
            icon: Icons.arrow_back,
            iconSize: 18,
            height: 35,
            fitToContent: true,
            onPressed: onPrevious,
          )
        else
          const SizedBox.shrink(),
        if (showPrevious) const SizedBox(width: 8),
        if (!isFinal)
          PrimaryButton(
            label: 'Next',
            icon: Icons.arrow_forward,
            iconAlignment: IconAlignment.end,
            iconSize: 18,
            height: 35,
            fitToContent: true,
            onPressed: onNext,
          )
        else
          Semantics(
            label: doneEnabled
                ? 'Complete lesson'
                : completionAllowed
                ? 'Done available in $seconds seconds'
                : 'Reconnect to complete lesson',
            button: true,
            child: PrimaryButton(
              key: const ValueKey('studio-school-done'),
              label: seconds > 0 ? 'Done ($seconds)' : 'Done',
              isLoading: saving,
              fitToContent: true,
              height: 35,
              onPressed: doneEnabled ? onDone : null,
            ),
          ),
      ],
    );
  }
}

class LessonSuccess extends StatelessWidget {
  const LessonSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 48,
              child: ColoredBox(
                color: AppColors.black,
                child: Icon(Icons.check, color: AppColors.white),
              ),
            ),
            SizedBox(height: 13),
            Text(
              'Lesson done.',
              style: TextStyle(fontWeight: AppTypography.bold),
            ),
          ],
        ),
      ),
    );
  }
}
