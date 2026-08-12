import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/studio_school/domain/lesson_definition.dart';

class SchoolHeader extends StatelessWidget {
  const SchoolHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SchoolSquareIcon(icon: Icons.school_outlined, size: 48),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Studio School',
                style: TextStyle(
                  fontSize: 30,
                  height: 1,
                  letterSpacing: -1.2,
                  fontWeight: AppTypography.bold,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Short lessons, each under a minute. Get more out of every credit.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SchoolSquareIcon extends StatelessWidget {
  const SchoolSquareIcon({
    required this.icon,
    this.size = 40,
    this.inverted = true,
    super.key,
  });

  final IconData icon;
  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: inverted ? AppColors.black : AppColors.neutral100,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size * 0.48,
        color: inverted ? AppColors.white : AppColors.black,
      ),
    );
  }
}

class LessonRewardBanner extends StatelessWidget {
  const LessonRewardBanner({
    required this.completedCount,
    required this.claimed,
    required this.canClaim,
    required this.claiming,
    required this.onClaim,
    super.key,
  });

  final int completedCount;
  final bool claimed;
  final bool canClaim;
  final bool claiming;
  final VoidCallback onClaim;

  String get _title {
    if (claimed) return 'All lessons done. 20 free credits earned.';
    if (completedCount == 6) {
      return 'All lessons done. Claim your 20 free credits.';
    }
    return 'Finish all 6 lessons and get 20 free credits.';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$completedCount of 6 lessons completed',
      child: ColoredBox(
        color: AppColors.black,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.card_giftcard_outlined,
                    color: AppColors.white,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PROGRESS',
                    style: TextStyle(
                      color: AppColors.whiteAlpha50,
                      fontSize: 9,
                      letterSpacing: 1.8,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    '$completedCount of 6 lessons',
                    style: const TextStyle(
                      color: AppColors.whiteAlpha70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                minHeight: 3,
                value: completedCount / 6,
                color: AppColors.white,
                backgroundColor: AppColors.whiteAlpha20,
              ),
              if (completedCount == 6 && !claimed) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    key: const ValueKey('studio-school-claim'),
                    onPressed: canClaim && !claiming ? onClaim : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.black,
                      disabledBackgroundColor: AppColors.neutral400,
                      shape: const RoundedRectangleBorder(),
                    ),
                    icon: claiming
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.card_giftcard_outlined, size: 18),
                    label: Text(claiming ? 'Claiming' : 'Claim 20 credits'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LessonTile extends StatelessWidget {
  const LessonTile({
    required this.lesson,
    required this.position,
    required this.completed,
    required this.onTap,
    super.key,
  });

  final LessonDefinition lesson;
  final int position;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = completed ? 'Completed' : 'Start';
    return Semantics(
      button: true,
      label: '${lesson.title}, ${lesson.cards.length} cards, $status',
      child: Material(
        color: completed ? AppColors.neutral150 : AppColors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.neutral200),
        ),
        child: InkWell(
          key: ValueKey('studio-school-${lesson.id.apiValue}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SchoolSquareIcon(icon: lesson.icon),
                    Row(
                      children: [
                        Text(
                          position.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: AppColors.neutral400,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        if (completed) ...[
                          const SizedBox(width: 6),
                          const SchoolSquareIcon(
                            icon: Icons.check,
                            size: 24,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.tagline,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(height: 1, color: AppColors.neutral200),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${lesson.cards.length} CARDS · 1 MIN',
                      style: _footerStyle,
                    ),
                    Text(
                      completed ? 'COMPLETED' : 'START',
                      style: _footerStyle.copyWith(
                        color: completed
                            ? AppColors.black
                            : AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _footerStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 9,
    letterSpacing: 0.8,
    fontWeight: AppTypography.bold,
  );
}
