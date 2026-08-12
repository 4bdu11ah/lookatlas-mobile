import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/connectivity/connectivity_provider.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/studio_school/domain/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/domain/studio_school_catalog.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_state.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/deep_guide_tile.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/lesson_player_dialog.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_components.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/school_notice.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/studio_school_drawer.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';

class StudioSchoolScreen extends ConsumerStatefulWidget {
  const StudioSchoolScreen({this.entrySource = 'deep_link', super.key});

  final String entrySource;

  @override
  ConsumerState<StudioSchoolScreen> createState() => _StudioSchoolScreenState();
}

class _StudioSchoolScreenState extends ConsumerState<StudioSchoolScreen>
    with WidgetsBindingObserver {
  final ValueNotifier<bool> _claiming = ValueNotifier(false);

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
    _claiming.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studioSchoolControllerProvider);
    final online = ref.watch(connectionStatusProvider);
    final welcome = _welcomeFrom(state);
    final user = ref.watch(authStateProvider).value;
    final name = user?.companyName?.trim();
    final source = name != null && name.isNotEmpty ? name : user?.email;
    final initial = source == null || source.isEmpty
        ? 'A'
        : source[0].toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      drawer: const StudioSchoolDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SchoolAppBar(initial: initial),
            Expanded(
              child: RefreshIndicator(
                onRefresh: ref
                    .read(studioSchoolControllerProvider.notifier)
                    .refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                      sliver: SliverToBoxAdapter(child: SchoolHeader()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ProgressSection(
                          state: state,
                          claiming: _claiming,
                          online: online,
                          onClaim: _claimReward,
                          onRetry: ref
                              .read(studioSchoolControllerProvider.notifier)
                              .refresh,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      sliver: SliverList.separated(
                        itemCount: studioSchoolLessons.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final lesson = studioSchoolLessons[index];
                          return LessonTile(
                            lesson: lesson,
                            position: index + 1,
                            completed:
                                welcome?.progressFor(lesson.id).isCompleted ??
                                false,
                            onTap: () => _openLesson(lesson, welcome, online),
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 34, 16, 32),
                      sliver: SliverToBoxAdapter(
                        child: _DeepGuides(onOpen: _openGuide),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLesson(
    LessonDefinition lesson,
    WelcomeState? welcome,
    bool online,
  ) async {
    final location = await showStudioLessonPlayer(
      context,
      lesson: lesson,
      welcome: welcome,
      online: online,
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
          queryParameters: {'tab': guide.tabId},
        ).toString(),
      ),
    );
  }

  Future<void> _claimReward() async {
    if (_claiming.value) return;
    _claiming.value = true;
    final result = await ref
        .read(studioSchoolControllerProvider.notifier)
        .claimReward();
    _claiming.value = false;
    if (!mounted) return;
    if (result.succeeded) {
      AppSnackBar.showSuccess(context, result.message);
    } else {
      AppSnackBar.showError(context, result.message);
    }
  }
}

WelcomeState? _welcomeFrom(StudioSchoolLoadState state) => switch (state) {
  SchoolReady(:final welcome) || SchoolOfflineCached(:final welcome) => welcome,
  _ => null,
};

class _SchoolAppBar extends StatelessWidget {
  const _SchoolAppBar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Open navigation',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => unawaited(
              context.push<void>(AppRoutes.dashboardAccount),
            ),
            child: Container(
              width: 36,
              height: 36,
              color: AppColors.black,
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.state,
    required this.claiming,
    required this.online,
    required this.onClaim,
    required this.onRetry,
  });

  final StudioSchoolLoadState state;
  final ValueListenable<bool> claiming;
  final bool online;
  final VoidCallback onClaim;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (state) {
    SchoolLoading() => const SizedBox(
      height: 124,
      child: ColoredBox(
        color: AppColors.neutral100,
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
    SchoolReadOnly() => const SchoolNotice(
      title: 'Learn without tracked progress',
      body:
          'Lessons and deep guides are available, but completion and the '
          '20-credit subscriber reward are not tracked for this account.',
    ),
    SchoolFailure() => SchoolNotice(
      title: "Progress couldn't load",
      body: 'Lessons remain readable. Try again to load current progress.',
      onRetry: onRetry,
    ),
    SchoolOfflineCached(:final welcome) => Column(
      children: [
        LessonRewardBanner(
          completedCount: welcome.completedCount,
          claimed: welcome.lessonsRewardClaimedAt != null,
          canClaim: false,
          claiming: false,
          onClaim: onClaim,
        ),
        const SizedBox(height: 12),
        SchoolNotice(
          title: 'Showing saved progress',
          body:
              'Reconnect and refresh before completing lessons or claiming credits.',
          onRetry: onRetry,
        ),
      ],
    ),
    SchoolReady(:final welcome) => ValueListenableBuilder<bool>(
      valueListenable: claiming,
      builder: (_, isClaiming, _) => LessonRewardBanner(
        completedCount: welcome.completedCount,
        claimed: welcome.lessonsRewardClaimedAt != null,
        canClaim: welcome.canClaimReward && online,
        claiming: isClaiming,
        onClaim: onClaim,
      ),
    ),
  };
}

class _DeepGuides extends StatelessWidget {
  const _DeepGuides({required this.onOpen});

  final ValueChanged<DeepGuideDefinition> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Deep guides',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Step by step with screenshots, for when you want the full detail.',
          style: TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
        const SizedBox(height: 15),
        for (final guide in studioSchoolGuides) ...[
          DeepGuideTile(guide: guide, onTap: () => onOpen(guide)),
          if (guide != studioSchoolGuides.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
