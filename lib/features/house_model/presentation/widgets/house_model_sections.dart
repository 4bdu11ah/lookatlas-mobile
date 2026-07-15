part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _LibraryModelsSection extends ConsumerWidget {
  const _LibraryModelsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(
      _houseModelControllerProvider.select(
        (state) => state.visibleLibraryModels,
      ),
    );
    final filteredCount = ref.watch(
      _houseModelControllerProvider.select(
        (state) => state.filteredLibraryModels.length,
      ),
    );
    final expanded = ref.watch(
      _houseModelControllerProvider.select((state) => state.expanded),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          icon: Icons.auto_awesome,
          title: 'LookAtlas Models',
          subtitle: 'Ready-to-use professional models',
          trailing: _FilterButton(onTap: () => _showFilterSheet(context, ref)),
        ),
        const _ActiveFilters(),
        if (visible.isEmpty)
          const _ModelEmptyState()
        else
          _ModelGrid(models: visible),
        if (filteredCount > 4 && !expanded) ...[
          const SizedBox(height: 16),
          _ModelActionButton.ghost(
            key: const ValueKey('show-more-models'),
            label: 'Show more models',
            icon: Icons.keyboard_arrow_down,
            iconAlignment: IconAlignment.end,
            full: true,
            onTap: ref.read(_houseModelControllerProvider.notifier).showMore,
          ),
        ],
        if (filteredCount > 0) ...[
          const SizedBox(height: 14),
          Text(
            'Showing ${visible.length} of $filteredCount models',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
        ],
      ],
    );
  }
}

class _UserModelsSection extends ConsumerWidget {
  const _UserModelsSection({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(
      _houseModelControllerProvider.select((state) => state.userModels),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(
          icon: Icons.groups_outlined,
          soft: true,
          title: 'Your Models',
          subtitle: "Models you've created or uploaded",
        ),
        const SizedBox(height: 16),
        for (final model in models) ...[
          _UserModelCard(model: model, onToast: onToast),
          const SizedBox(height: 12),
        ],
        if (models.isEmpty)
          _YourModelsEmptyState(
            onAdd: () => _showModelFormSheet(context, ref, onToast),
            onAi: () => _showAiSheet(context, ref, onToast),
          ),
      ],
    );
  }
}

class _YourModelsEmptyState extends StatelessWidget {
  const _YourModelsEmptyState({required this.onAdd, required this.onAi});

  final VoidCallback onAdd;
  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: AppColors.inkAlpha05,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              border: Border.all(color: AppColors.neutral200),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.groups_outlined,
              size: 29,
              color: AppColors.neutral500,
            ),
          ),
          const Text(
            'No models added yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              height: 1.25,
              fontWeight: AppTypography.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: const Text(
              'Upload your first house model to get started with on-model image generation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.58,
                color: AppColors.neutral500,
              ),
            ),
          ),
          const SizedBox(height: 23),
          _EmptyStateButton(
            label: 'Add your first model',
            icon: Icons.people_alt_outlined,
            onTap: onAdd,
          ),
          const SizedBox(height: 9),
          _EmptyStateButton.secondary(
            label: 'Create with AI (20 credits)',
            icon: Icons.auto_awesome,
            onTap: onAi,
          ),
          const SizedBox(height: 15),
          // const Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Icon(
          //       Icons.photo_camera_outlined,
          //       size: 13,
          //       color: AppColors.neutral500,
          //     ),
          //     SizedBox(width: 6),
          //     Text(
          //       '3-5 clear photos work best',
          //       style: TextStyle(fontSize: 10, color: AppColors.neutral500),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

class _EmptyStateButton extends StatelessWidget {
  const _EmptyStateButton({
    required this.label,
    required this.icon,
    required this.onTap,
  }) : secondary = false;

  const _EmptyStateButton.secondary({
    required this.label,
    required this.icon,
    required this.onTap,
  }) : secondary = true;

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final bg = secondary ? AppColors.white : AppColors.black;
    final fg = secondary ? AppColors.black : AppColors.white;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: bg,
        shape: const Border.fromBorderSide(
          BorderSide(color: AppColors.black, width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: AppTypography.bold,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.soft = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          color: soft ? AppColors.neutral100 : AppColors.black,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: soft ? AppColors.neutral500 : AppColors.white,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _FilterButton extends ConsumerWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      _houseModelControllerProvider.select((state) => state.hasActiveFilters),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _ModelActionButton.ghost(
          key: const ValueKey('filter-models'),
          label: 'Filter',
          icon: Icons.filter_list,
          compact: true,
          onTap: onTap,
        ),
        if (active)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neutral50, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gender = ref.watch(
      _houseModelControllerProvider.select((state) => state.genderFilter),
    );
    final body = ref.watch(
      _houseModelControllerProvider.select((state) => state.bodyFilter),
    );
    if (gender == null && body == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (gender != null)
              _ActiveChip(
                label: gender.label,
                onClear: ref
                    .read(_houseModelControllerProvider.notifier)
                    .clearGenderFilter,
              ),
            if (body != null)
              _ActiveChip(
                label: body.label,
                onClear: ref
                    .read(_houseModelControllerProvider.notifier)
                    .clearBodyFilter,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: InkWell(
        onTap: onClear,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: AppColors.black,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: AppTypography.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 12, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}
