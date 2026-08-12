part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

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
        onNavigate: (page) => _navigateDashboard(context, ref, page),
      ),
    );
  }
}

class _GuidesPage extends ConsumerStatefulWidget {
  const _GuidesPage({required this.onNavigate, this.initialTab});

  final ValueChanged<_DashboardPage> onNavigate;
  final String? initialTab;

  @override
  ConsumerState<_GuidesPage> createState() => _GuidesPageState();
}

class _GuidesPageState extends ConsumerState<_GuidesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final initialTab = _guideTabFromId(widget.initialTab);
    if (initialTab != null) {
      unawaited(
        Future<void>.microtask(() {
          if (mounted) {
            ref.read(_guidesControllerProvider.notifier).selectTab(initialTab);
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

  void _selectTab(_GuideTab tab) {
    ref.read(_guidesControllerProvider.notifier).selectTab(tab);
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      ),
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

  final ValueChanged<_GuideTab> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      _guidesControllerProvider.select((state) => state.selectedTab),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          for (final tab in _GuideTab.values) ...[
            _GuideTabButton(
              tab: tab,
              selected: tab == selected,
              onTap: () => onSelected(tab),
            ),
            if (tab != _GuideTab.values.last) const SizedBox(width: 4),
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

  final _GuideTab tab;
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

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(
      _guidesControllerProvider.select((state) => state.selectedTab),
    );
    return switch (tab) {
      _GuideTab.gettingStarted => _GettingStartedGuide(
        onNavigate: onNavigate,
      ),
      _GuideTab.productPhotos => _ProductPhotosGuide(
        onNavigate: onNavigate,
      ),
      _GuideTab.models => _ModelsGuide(onNavigate: onNavigate),
      _GuideTab.shoots => _ShootsGuide(onNavigate: onNavigate),
    };
  }
}
