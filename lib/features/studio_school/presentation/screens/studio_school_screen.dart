import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/connectivity/connectivity_provider.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/guides/presentation/models/learning_guide_content.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/learning_center_search_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/studio_school_state.dart';
import 'package:look_atlas/features/studio_school/presentation/models/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/presentation/models/studio_school_catalog.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/deep_guide_tile.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_support.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/lesson_player_dialog.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_components.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_notice.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';

class StudioSchoolScreen extends ConsumerStatefulWidget {
  const StudioSchoolScreen({this.entrySource = 'deep_link', super.key});
  final String entrySource;
  @override
  ConsumerState<StudioSchoolScreen> createState() => _StudioSchoolScreenState();
}

class _StudioSchoolScreenState extends ConsumerState<StudioSchoolScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            'welcome.school_opened',
            properties: {'source': widget.entrySource},
          ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref
            .read(studioSchoolControllerProvider.notifier)
            .refresh(forceRefresh: false),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: LearningCenterStyle.paper,
    appBar: CustomAppBar(
      title: 'Learning Center',
      showBackButton: true,
      onBack: _goBack,
    ),
    body: RefreshIndicator(
      onRefresh: ref.read(studioSchoolControllerProvider.notifier).refresh,
      child: _LearningHub(
        onLesson: _openLesson,
        onGuide: _openGuide,
        onClaim: _claimReward,
      ),
    ),
  );

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _openLesson(LessonDefinition lesson) async {
    final state = ref.read(studioSchoolControllerProvider);
    final welcome = welcomeFromSchool(state);
    final location = await showStudioLessonPlayer(
      context,
      lesson: lesson,
      welcome: welcome,
      online: ref.read(connectionStatusProvider),
    );
    if (!mounted || location == null) return;
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            'welcome.lesson_try_link',
            properties: {'lesson': lesson.id.apiValue},
          ),
    );
    unawaited(context.push<void>(location));
  }

  void _openGuide(DeepGuideDefinition guide) {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            'welcome.deep_guide_opened',
            properties: {'guide': guide.tabId},
          ),
    );
    unawaited(
      context.push<void>(
        Uri(
          path: AppRoutes.dashboardGuides,
          queryParameters: {'tab': guide.tabId, 'from': 'school'},
        ).toString(),
      ),
    );
  }

  Future<void> _claimReward() async {
    if (ref.read(learningRewardClaimingProvider)) return;
    ref.read(learningRewardClaimingProvider.notifier).claiming = true;
    try {
      final result = await ref
          .read(studioSchoolControllerProvider.notifier)
          .claimReward();
      if (!mounted) return;
      if (result.succeeded) {
        unawaited(HapticFeedback.mediumImpact());
        AppSnackBar.showSuccess(context, result.message);
      } else {
        AppSnackBar.showError(context, result.message);
      }
    } finally {
      if (mounted) {
        ref.read(learningRewardClaimingProvider.notifier).claiming = false;
      }
    }
  }
}

WelcomeState? welcomeFromSchool(StudioSchoolLoadState state) => switch (state) {
  SchoolReady(:final welcome) || SchoolOfflineCached(:final welcome) => welcome,
  _ => null,
};

class _LearningHub extends ConsumerWidget {
  const _LearningHub({
    required this.onLesson,
    required this.onGuide,
    required this.onClaim,
  });
  final ValueChanged<LessonDefinition> onLesson;
  final ValueChanged<DeepGuideDefinition> onGuide;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(learningCenterSearchProvider).trim();
    final welcome = welcomeFromSchool(
      ref.watch(studioSchoolControllerProvider),
    );
    final lessons = _filteredLessons(query);
    final guides = _filteredGuides(query);
    final count = lessons.length + guides.length;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
          sliver: SliverToBoxAdapter(child: SchoolHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: query.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _LearningProgress(
                      onLesson: onLesson,
                      onClaim: onClaim,
                    ),
                  )
                : _searchSummary(query, count),
          ),
        ),
        if (lessons.isNotEmpty) _lessonSection(lessons, welcome),
        if (guides.isNotEmpty) _guideSection(guides),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 84),
          sliver: SliverToBoxAdapter(
            child: count == 0
                ? const LearningSearchEmpty()
                : const LearningCenterSupport(),
          ),
        ),
      ],
    );
  }

  List<LessonDefinition> _filteredLessons(String query) => studioSchoolLessons
      .where(
        (lesson) => matchesLearningSearch([
          lesson.title,
          lesson.tagline,
          lesson.id.apiValue,
          for (final card in lesson.cards) ...[card.title, card.body],
          lesson.tryLink?.label ?? '',
        ], query),
      )
      .toList();
  List<DeepGuideDefinition> _filteredGuides(String query) => studioSchoolGuides
      .where(
        (guide) => matchesLearningSearch([
          guide.title,
          guide.description,
          guide.kicker,
          guide.tabId,
          guideSearchText(guide.tabId),
        ], query),
      )
      .toList();

  Widget _searchSummary(String query, int count) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$count ${count == 1 ? 'result' : 'results'} for ',
            style: LearningCenterStyle.body(12),
          ),
          TextSpan(
            text: '“$query”',
            style: LearningCenterStyle.body(
              13.5,
              color: LearningCenterStyle.ink,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _lessonSection(
    List<LessonDefinition> lessons,
    WelcomeState? welcome,
  ) => SliverMainAxisGroup(
    slivers: [
      const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: LearningSectionHeading(
            kicker: 'One useful idea at a time',
            title: 'One-minute essentials',
            body: 'Short enough to finish now. Useful enough to save a reshoot later.',
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: lessons.length,
          itemBuilder: (_, index) => LessonTile(
            lesson: lessons[index],
            position: index + 1,
            completed:
                welcome?.progressFor(lessons[index].id).isCompleted ?? false,
            onTap: () => onLesson(lessons[index]),
          ),
        ),
      ),
    ],
  );

  Widget _guideSection(List<DeepGuideDefinition> guides) => SliverMainAxisGroup(
    slivers: [
      const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: LearningSectionHeading(
            kicker: 'When you want the full picture',
            title: 'Practical guides',
            body: 'Step-by-step help for the work you do most often.',
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: guides.length,
          itemBuilder: (_, index) => DecoratedBox(
            decoration: BoxDecoration(
              border: index == 0
                  ? const Border(
                      top: BorderSide(color: LearningCenterStyle.line),
                    )
                  : null,
            ),
            child: DeepGuideTile(
              guide: guides[index],
              onTap: () => onGuide(guides[index]),
            ),
          ),
        ),
      ),
    ],
  );
}

String guideSearchText(String tab) => learningGuideForId(tab).searchText;

class _LearningProgress extends ConsumerWidget {
  const _LearningProgress({required this.onLesson, required this.onClaim});
  final ValueChanged<LessonDefinition> onLesson;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studioSchoolControllerProvider);
    final welcome = welcomeFromSchool(state);
    if (state is SchoolLoading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state is SchoolFailure) {
      return SchoolNotice(
        title: "Progress couldn't load",
        body: 'Lessons remain readable. Try again to load current progress.',
        onRetry: () => unawaited(
          ref.read(studioSchoolControllerProvider.notifier).refresh(),
        ),
      );
    }
    final next = studioSchoolLessons.firstWhere(
      (lesson) => !(welcome?.progressFor(lesson.id).isCompleted ?? false),
      orElse: () => studioSchoolLessons.first,
    );
    return Column(
      children: [
        LessonRewardBanner(
          completedCount: welcome?.completedCount ?? 0,
          claimed: welcome?.lessonsRewardClaimedAt != null,
          canClaim:
              state is SchoolReady &&
              (welcome?.canClaimReward ?? false) &&
              ref.watch(connectionStatusProvider),
          claiming: ref.watch(learningRewardClaimingProvider),
          nextLesson: next,
          onContinue: () => onLesson(next),
          onClaim: onClaim,
        ),
        if (state is SchoolReadOnly)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SchoolNotice(
              title: 'Learn without tracked progress',
              body: 'Lessons and practical guides are available. Completion and rewards require an eligible account.',
            ),
          ),
        if (state is SchoolOfflineCached)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SchoolNotice(
              title: 'Showing saved progress',
              body: 'Reconnect and refresh before completing lessons or claiming credits.',
            ),
          ),
      ],
    );
  }
}
