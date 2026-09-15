import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/learning_center_search_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/models/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/presentation/models/studio_school_catalog.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_lesson_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SchoolHeader extends StatelessWidget {
  const SchoolHeader({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 26),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LearningCenterStyle.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LearningKicker('Learning Center', icon: LucideIcons.sparkles),
        const SizedBox(height: 10),
        Text(
          'Make better work, faster.',
          style: LearningCenterStyle.serif(44, height: 0.98, tracking: -0.045),
        ),
        const SizedBox(height: 8),
        Text(
          'Short lessons and practical guides for stronger shoots. Find an answer, learn one thing, then get back to creating.',
          style: LearningCenterStyle.body(13),
        ),
        const SizedBox(height: 20),
        const _LearningSearch(),
      ],
    ),
  );
}

class _LearningSearch extends ConsumerStatefulWidget {
  const _LearningSearch();
  @override
  ConsumerState<_LearningSearch> createState() => _LearningSearchState();
}

class _LearningSearchState extends ConsumerState<_LearningSearch> {
  final _text = TextEditingController();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(learningCenterSearchProvider);
    ref.listen(learningCenterSearchProvider, (_, next) {
      if (next != _text.text) _text.text = next;
    });
    return SizedBox(
      height: 50,
      child: TextField(
        key: const ValueKey('learning-center-search'),
        controller: _text,
        onChanged: (value) =>
            ref.read(learningCenterSearchProvider.notifier).query = value,
        style: LearningCenterStyle.body(13, color: LearningCenterStyle.ink),
        decoration: InputDecoration(
          hintText: 'What do you want to learn?',
          hintStyle: LearningCenterStyle.body(
            13,
            color: const Color(0xFF94948D),
          ),
          filled: true,
          fillColor: LearningCenterStyle.paper,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 17,
            color: Color(0xFF81817A),
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(LucideIcons.x, size: 15),
                  onPressed: ref
                      .read(learningCenterSearchProvider.notifier)
                      .clear,
                ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: LearningCenterStyle.line),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: LearningCenterStyle.line),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: LearningCenterStyle.ink),
          ),
        ),
      ),
    );
  }
}

class SchoolSquareIcon extends StatelessWidget {
  const SchoolSquareIcon({
    required this.icon,
    this.size = 37,
    this.inverted = true,
    super.key,
  });
  final IconData icon;
  final double size;
  final bool inverted;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    color: inverted ? LearningCenterStyle.ink : LearningCenterStyle.soft,
    alignment: Alignment.center,
    child: learningLessonIconSvgs.containsKey(icon)
        ? SvgPicture.string(
            learningLessonIconSvgs[icon]!,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              inverted ? LearningCenterStyle.paper : LearningCenterStyle.ink,
              BlendMode.srcIn,
            ),
          )
        : Icon(
            icon,
            size: 16,
            color: inverted
                ? LearningCenterStyle.paper
                : LearningCenterStyle.ink,
          ),
  );
}

class LessonRewardBanner extends StatelessWidget {
  const LessonRewardBanner({
    required this.completedCount,
    required this.claimed,
    required this.canClaim,
    required this.claiming,
    required this.onClaim,
    this.nextLesson,
    this.onContinue,
    super.key,
  });
  final int completedCount;
  final bool claimed;
  final bool canClaim;
  final bool claiming;
  final VoidCallback onClaim;
  final LessonDefinition? nextLesson;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$completedCount of 6 lessons completed',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 21),
        decoration: BoxDecoration(
          color: claimed || completedCount == 6
              ? const Color(0xFF343229)
              : LearningCenterStyle.ink,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C181816),
              offset: Offset(0, 24),
              blurRadius: 70,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LearningKicker(
              'Continue learning',
              size: 13,
              height: 1.6,
              icon: LucideIcons.bookText,
              color: Color(0x8AFFFFFA),
            ),
            const SizedBox(height: 10),
            Text(
              _title,
              style: LearningCenterStyle.serif(
                34,
                color: LearningCenterStyle.paper,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _description,
              style: LearningCenterStyle.body(
                13,
                color: const Color(0xA6FFFFFA),
              ),
            ),
            const SizedBox(height: 20),
            _progress(),
            const SizedBox(height: 18),
            _action(),
          ],
        ),
      ),
    );
  }

  String get _title => claimed
      ? 'Six lessons down. Your reward is claimed.'
      : completedCount == 6
      ? 'Six lessons down. Your reward is ready.'
      : completedCount > 0
      ? (nextLesson ?? studioSchoolLessons.first).title
      : 'Start with the essentials.';
  String get _description => claimed
      ? '20 credits have been added directly to your balance.'
      : completedCount == 6
      ? 'Claim 20 credits now. They will be added directly to your balance.'
      : completedCount > 0
      ? (nextLesson ?? studioSchoolLessons.first).tagline
      : 'Six plain-English lessons cover credits, fixes, direction, refunds, and image rights.';

  Widget _action() => LearningAction(
    claiming
        ? 'Claiming'
        : claimed
        ? 'Review lessons'
        : completedCount == 6
        ? 'Claim 20 credits'
        : completedCount > 0
        ? 'Continue lesson'
        : 'Start first lesson',
    key: completedCount == 6 && !claimed
        ? const ValueKey('studio-school-claim')
        : const ValueKey('studio-school-continue'),
    height: 48,
    inverted: true,
    onPressed: claiming
        ? null
        : completedCount == 6 && !claimed
        ? canClaim
              ? onClaim
              : null
        : onContinue,
  );

  Widget _progress() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _progressMeta(),
      const SizedBox(height: 9),
      LinearProgressIndicator(
        value: completedCount / 6,
        minHeight: 3,
        color: LearningCenterStyle.paper,
        backgroundColor: const Color(0x2BFFFFFA),
      ),
      const SizedBox(height: 9),
      _progressNote(),
    ],
  );
  Widget _progressMeta() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'YOUR PROGRESS',
        style: LearningCenterStyle.body(
          11,
          height: 1.18,
          color: const Color(0x9EFFFFFA),
          weight: FontWeight.w700,
        ).copyWith(letterSpacing: 1.1),
      ),
      Text(
        '$completedCount OF 6',
        style: LearningCenterStyle.body(
          11,
          height: 1.18,
          color: LearningCenterStyle.paper,
          weight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _progressNote() => Row(
    children: [
      const Icon(
        LucideIcons.gift,
        size: 12,
        color: Color(0x94FFFFFA),
      ),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          claimed ? '20 credits earned.' : 'Finish all six to earn 20 credits.',
          style: LearningCenterStyle.body(
            11,
            height: 1.18,
            color: const Color(0x94FFFFFA),
          ),
        ),
      ),
    ],
  );
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${lesson.title}, ${completed ? 'Completed' : 'Start'}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('studio-school-${lesson.id.apiValue}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: LearningCenterStyle.line),
              top: position == 1
                  ? const BorderSide(color: LearningCenterStyle.line)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              SchoolSquareIcon(icon: lesson.icon),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LearningCenterStyle.serif(
                        21,
                        height: 1.05,
                        tracking: -0.025,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LearningCenterStyle.body(11, height: 1.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              if (completed)
                Container(
                  width: 23,
                  height: 23,
                  color: LearningCenterStyle.ink,
                  child: const Icon(
                    LucideIcons.check,
                    size: 13,
                    color: LearningCenterStyle.paper,
                  ),
                )
              else
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: LearningCenterStyle.muted,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
