import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/connectivity/connectivity_provider.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/lesson_player_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_state.dart';
import 'package:look_atlas/features/studio_school/presentation/models/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/presentation/models/studio_school_catalog.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/lesson_player_content.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_components.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart';

Future<String?> showStudioLessonPlayer(
  BuildContext context, {
  required LessonDefinition lesson,
  required WelcomeState? welcome,
  required bool online,
}) => showAppDialog<String>(
  context: context,
  builder: (_) =>
      StudioLessonPlayer(lesson: lesson, welcome: welcome, online: online),
);

class _LessonChainController extends Notifier<WelcomeLessonId> {
  _LessonChainController(this.initial);
  final WelcomeLessonId initial;
  @override
  WelcomeLessonId build() => initial;
  WelcomeLessonId get lessonId => state;
  set lessonId(WelcomeLessonId id) => state = id;
}

final NotifierProviderFamily<
  _LessonChainController,
  WelcomeLessonId,
  WelcomeLessonId
>
_lessonChainProvider = NotifierProvider.autoDispose
    .family<_LessonChainController, WelcomeLessonId, WelcomeLessonId>(
      _LessonChainController.new,
    );

class StudioLessonPlayer extends ConsumerStatefulWidget {
  const StudioLessonPlayer({
    required this.lesson,
    required this.welcome,
    required this.online,
    super.key,
  });
  final LessonDefinition lesson;
  final WelcomeState? welcome;
  final bool online;
  @override
  ConsumerState<StudioLessonPlayer> createState() => _StudioLessonPlayerState();
}

class _StudioLessonPlayerState extends ConsumerState<StudioLessonPlayer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(
        lessonRemainingProvider(
          ref.read(_lessonChainProvider(widget.lesson.id)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(_lessonChainProvider(widget.lesson.id));
    final lesson = studioSchoolLessons.firstWhere((lesson) => lesson.id == id);
    final state = ref.watch(lessonPlayerControllerProvider(id));
    final controller = ref.read(lessonPlayerControllerProvider(id).notifier);
    final school = ref.watch(studioSchoolControllerProvider);
    final welcome = switch (school) {
      SchoolReady(:final welcome) ||
      SchoolOfflineCached(:final welcome) => welcome,
      _ => widget.welcome,
    };
    final tracked =
        welcome?.eligible == true &&
        !(welcome?.progressFor(id).isCompleted ?? false);
    final isFinal = state.cardIndex == lesson.cards.length - 1;
    ref.listen(
      lessonPlayerControllerProvider(id).select((state) => state.completed),
      (_, completed) {
        if (completed) unawaited(HapticFeedback.mediumImpact());
      },
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.pop(context),
      },
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _ReaderHeader(lesson: lesson, cardIndex: state.cardIndex),
            _LessonProgress(
              count: lesson.cards.length,
              active: state.cardIndex,
            ),
            Expanded(
              child: state.completed
                  ? LessonSuccess(
                      saved: welcome?.eligible == true,
                      onNext: id == studioSchoolLessons.last.id
                          ? null
                          : () => _advance(lesson),
                      onClose: () => Navigator.pop(context),
                      tryLink: lesson.tryLink,
                      onTry: (location) => Navigator.pop(context, location),
                    )
                  : LessonPlayerCardBody(
                      card: lesson.cards[state.cardIndex],
                      index: state.cardIndex,
                      count: lesson.cards.length,
                      tryLink: isFinal ? lesson.tryLink : null,
                      onTry: (location) => Navigator.pop(context, location),
                    ),
            ),
            if (!state.completed)
              LessonPlayerFooter(
                lessonId: id,
                state: state,
                isFinal: isFinal,
                timerRequired:
                    tracked || (school is SchoolLoading && welcome == null),
                online: ref.watch(connectionStatusProvider),
                actions: (
                  previous: controller.previous,
                  next: controller.next,
                  done: () => unawaited(controller.complete(tracked: tracked)),
                  retry: () => unawaited(controller.start()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _advance(LessonDefinition lesson) {
    ref.read(_lessonChainProvider(widget.lesson.id).notifier).lessonId =
        studioSchoolLessons[studioSchoolLessons.indexOf(lesson) + 1].id;
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({required this.lesson, required this.cardIndex});
  final LessonDefinition lesson;
  final int cardIndex;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 68),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LearningCenterStyle.line)),
    ),
    child: Row(
      children: [
        SchoolSquareIcon(icon: lesson.icon, size: 35),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LearningCenterStyle.body(
                  13,
                  color: LearningCenterStyle.ink,
                  weight: FontWeight.w700,
                ),
              ),
              Text(
                'ONE-MINUTE ESSENTIAL',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LearningCenterStyle.body(
                  11,
                  height: 1.2,
                  weight: FontWeight.w700,
                ).copyWith(letterSpacing: 1.32),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${cardIndex + 1} / ${lesson.cards.length}',
          style: LearningCenterStyle.body(11),
        ),
        const SizedBox(width: 9),
        SizedBox.square(
          dimension: 34,
          child: IconButton(
            tooltip: 'Close lesson',
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              LucideIcons.x,
              size: 17,
              color: LearningCenterStyle.muted,
            ),
          ),
        ),
      ],
    ),
  );
}

class _LessonProgress extends StatelessWidget {
  const _LessonProgress({required this.count, required this.active});
  final int count;
  final int active;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
    child: Row(
      children: [
        for (var index = 0; index < count; index++)
          Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.only(right: index == count - 1 ? 0 : 4),
              color: index <= active
                  ? LearningCenterStyle.ink
                  : const Color(0xFFDFDED7),
            ),
          ),
      ],
    ),
  );
}
