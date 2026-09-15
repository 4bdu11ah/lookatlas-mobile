import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/guides/presentation/controllers/guides_controller.dart';
import 'package:look_atlas/features/guides/presentation/models/guides_screen_state.dart';
import 'package:look_atlas/features/guides/presentation/models/learning_guide_content.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part '../widgets/guides_widgets.dart';

class GuidesScreen extends ConsumerStatefulWidget {
  const GuidesScreen({this.initialTab, super.key});
  final String? initialTab;
  @override
  ConsumerState<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends ConsumerState<GuidesScreen> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(() {
        if (mounted) {
          ref
              .read(guidesControllerProvider.notifier)
              .selectTab(
                guideTabFromId(widget.initialTab) ?? GuideTab.gettingStarted,
              );
        }
      }),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(GuideTab tab) {
    ref.read(guidesControllerProvider.notifier).selectTab(tab);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.studioSchool);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(
      guidesControllerProvider.select((state) => state.selectedTab),
    );
    final content = learningGuideForId(switch (tab) {
      GuideTab.gettingStarted => 'getting-started',
      GuideTab.productPhotos => 'product-photos',
      GuideTab.models => 'models',
      GuideTab.shoots => 'jobs',
    });
    return Scaffold(
      backgroundColor: LearningCenterStyle.paper,
      appBar: CustomAppBar(
        title: 'Guides',
        showBackButton: true,
        onBack: _goBack,
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _GuidesHeader(),
                  _GuidesTabs(selected: tab, onSelected: _select),
                  const SizedBox(height: 24),
                  LearningKicker(content.kicker),
                  const SizedBox(height: 6),
                  Text(
                    content.title,
                    style: LearningCenterStyle.serif(
                      30,
                      height: 1.08,
                      tracking: -0.03,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(content.intro, style: LearningCenterStyle.body(13)),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 84),
            sliver: SliverList.separated(
              itemCount: content.blocks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 22),
              itemBuilder: (_, index) => _GuideBlock(
                content.blocks[index],
                onNavigate: (route) => unawaited(context.push<void>(route)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _backToSchool(BuildContext context) {
  if (context.canPop() &&
      GoRouterState.of(context).uri.queryParameters['from'] == 'school') {
    context.pop();
  } else {
    context.go(AppRoutes.studioSchool);
  }
}

class _GuidesHeader extends StatelessWidget {
  const _GuidesHeader();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const LearningKicker('Learning Center'),
      const SizedBox(height: 6),
      Text('Guides', style: LearningCenterStyle.serif(38)),
      const SizedBox(height: 6),
      Text(
        'Current instructions for the product library, model roster, shoot builder, and review room.',
        style: LearningCenterStyle.body(13),
      ),
      const SizedBox(height: 16),
      LearningAction(
        'Studio School',
        outlined: true,
        height: 42,
        onPressed: () => _backToSchool(context),
      ),
      const SizedBox(height: 24),
    ],
  );
}

class _GuidesTabs extends StatelessWidget {
  const _GuidesTabs({required this.selected, required this.onSelected});
  final GuideTab selected;
  final ValueChanged<GuideTab> onSelected;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LearningCenterStyle.line)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in GuideTab.values)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Semantics(
                button: true,
                selected: tab == selected,
                child: InkWell(
                  key: ValueKey('guide-tab-${tab.name}'),
                  onTap: () => onSelected(tab),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: tab == selected
                              ? LearningCenterStyle.ink
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tab.icon,
                          size: 15,
                          color: tab == selected
                              ? LearningCenterStyle.ink
                              : LearningCenterStyle.muted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          tab.label,
                          style: LearningCenterStyle.body(
                            12.5,
                            color: tab == selected
                                ? LearningCenterStyle.ink
                                : LearningCenterStyle.muted,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
