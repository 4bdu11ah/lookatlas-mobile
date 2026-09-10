import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/guides/presentation/controllers/guides_controller.dart';
import 'package:look_atlas/features/guides/presentation/models/guides_screen_state.dart';
import 'package:look_atlas/shared/widgets/app_dotted_border.dart';
import 'package:look_atlas/shared/widgets/app_feature_scaffold.dart';

part '../tabs/getting_started_guide.dart';
part '../tabs/models_guide.dart';
part '../tabs/product_photos_guide.dart';
part '../tabs/shoots_guide.dart';
part '../widgets/guides_widgets.dart';

class GuidesScreen extends ConsumerWidget {
  const GuidesScreen({this.initialTab, super.key});

  final String? initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFeatureScaffold(
      backgroundColor: AppColors.neutral50,
      title: 'Guides',
      child: _GuidesPage(
        initialTab: initialTab,
        onNavigate: (route) => unawaited(context.push<void>(route)),
      ),
    );
  }
}

class _GuidesPage extends ConsumerStatefulWidget {
  const _GuidesPage({required this.onNavigate, this.initialTab});

  final ValueChanged<String> onNavigate;
  final String? initialTab;

  @override
  ConsumerState<_GuidesPage> createState() => _GuidesPageState();
}

class _GuidesPageState extends ConsumerState<_GuidesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final initialTab = guideTabFromId(widget.initialTab);
    if (initialTab != null) {
      unawaited(
        Future<void>.microtask(() {
          if (mounted) {
            ref.read(guidesControllerProvider.notifier).selectTab(initialTab);
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectTab(GuideTab tab) {
    ref.read(guidesControllerProvider.notifier).selectTab(tab);
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _GuidesPageHeader(),
        const SizedBox(height: 32),
        _GuidesTabs(onSelected: _selectTab),
        const SizedBox(height: 32),
        _GuideTabContent(onNavigate: widget.onNavigate),
      ],
    );
  }
}

class _GuidesPageHeader extends StatelessWidget {
  const _GuidesPageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guides',
          style: TextStyle(
            fontSize: 30,
            height: 1.2,
            fontWeight: AppTypography.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Everything you need to master Look Atlas and create stunning on-model product photography.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _GuidesTabs extends ConsumerWidget {
  const _GuidesTabs({required this.onSelected});

  final ValueChanged<GuideTab> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      guidesControllerProvider.select((state) => state.selectedTab),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          for (final tab in GuideTab.values) ...[
            _GuideTabButton(
              tab: tab,
              selected: tab == selected,
              onTap: () => onSelected(tab),
            ),
            if (tab != GuideTab.values.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _GuideTabButton extends StatelessWidget {
  const _GuideTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final GuideTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tab.label,
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('guide-tab-${tab.name}'),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.black : AppColors.transparent,
                width: 2,
              ),
            ),
          ),
          child: ExcludeSemantics(
            child: Icon(
              tab.icon,
              size: 16,
              color: selected ? AppColors.black : AppColors.neutral500,
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideTabContent extends ConsumerWidget {
  const _GuideTabContent({required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(
      guidesControllerProvider.select((state) => state.selectedTab),
    );
    return switch (tab) {
      GuideTab.gettingStarted => _GettingStartedGuide(
        onNavigate: onNavigate,
      ),
      GuideTab.productPhotos => _ProductPhotosGuide(
        onNavigate: onNavigate,
      ),
      GuideTab.models => _ModelsGuide(onNavigate: onNavigate),
      GuideTab.shoots => _ShootsGuide(onNavigate: onNavigate),
    };
  }
}
