part of '../screens/house_model_page.dart';

class _LibraryModelsSection extends ConsumerWidget {
  const _LibraryModelsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(
      houseModelControllerProvider.select(
        (state) => state.visibleLibraryModels,
      ),
    );
    final filteredCount = ref.watch(
      houseModelControllerProvider.select(
        (state) => state.filteredLibraryModels.length,
      ),
    );
    final expanded = ref.watch(
      houseModelControllerProvider.select((state) => state.expanded),
    );
    final isLoading = ref.watch(
      houseModelControllerProvider.select((state) => state.isLoading),
    );
    final showLoading = isLoading && visible.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          icon: Icons.auto_awesome,
          title: 'LookAtlas Models',
          subtitle: 'Ready-to-use professional models',
          trailing: showLoading
              ? null
              : _FilterButton(onTap: () => _showFilterSheet(context, ref)),
        ),
        if (!showLoading) const _ActiveFilters(),
        if (showLoading)
          const _HouseModelLibraryLoadingGrid()
        else if (visible.isEmpty)
          const _ModelEmptyState()
        else
          _ModelGrid(models: visible),
        if (!showLoading && filteredCount > 4 && !expanded) ...[
          const SizedBox(height: 16),
          AppOutlinedButton(
            key: const ValueKey('show-more-models'),
            label: 'Show more models',
            icon: Icons.keyboard_arrow_down,
            iconAlignment: IconAlignment.end,
            onPressed: ref.read(houseModelControllerProvider.notifier).showMore,
          ),
        ],
        if (!showLoading && filteredCount > 0) ...[
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
      houseModelControllerProvider.select((state) => state.userModels),
    );
    final isLoading = ref.watch(
      houseModelControllerProvider.select((state) => state.isLoading),
    );
    final isGeneratingAiModel = ref.watch(
      houseModelControllerProvider.select(
        (state) => state.isGeneratingAiModel,
      ),
    );
    final showLoading = (isLoading || isGeneratingAiModel) && models.isEmpty;
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
        if (isGeneratingAiModel) const _AiModelGenerationProgress(),
        if (showLoading)
          const _HouseModelUserLoadingList()
        else
          for (final model in models) ...[
            _UserModelCard(
              key: ValueKey('user-model-${model.id}'),
              model: model,
              onToast: onToast,
            ),
            const SizedBox(height: 12),
          ],
        if (!showLoading && models.isEmpty)
          _YourModelsEmptyState(
            onAdd: () => _showModelFormDialog(context, ref, onToast),
            onAi: () => _showAiSheet(context, ref, onToast),
          ),
      ],
    );
  }
}

class _AiModelGenerationProgress extends StatelessWidget {
  const _AiModelGenerationProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('ai-model-generation-progress'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Creating your AI model',
            style: TextStyle(fontWeight: AppTypography.semiBold),
          ),
          SizedBox(height: 6),
          Text(
            'Generating your four poses. This can take a few minutes.',
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(),
        ],
      ),
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
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: AppSquareIcon(
              Icons.groups_outlined,
              size: 64,
              iconSize: 29,
              iconColor: AppColors.neutral500,
              backgroundColor: AppColors.neutral100,
              borderColor: AppColors.neutral200,
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
          PrimaryButton(
            label: 'Add your first model',
            icon: Icons.people_alt_outlined,
            height: 50,
            onPressed: onAdd,
          ),
          const SizedBox(height: 9),
          AppOutlinedButton(
            label: 'Create with AI (20 credits)',
            icon: Icons.auto_awesome,
            height: 50,
            borderColor: AppColors.black,
            foregroundColor: AppColors.black,
            onPressed: onAi,
          ),
          const SizedBox(height: 15),
        ],
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
        AppSquareIcon(
          icon,
          size: 36,
          iconSize: 18,
          backgroundColor: soft ? AppColors.neutral100 : AppColors.black,
          iconColor: soft ? AppColors.neutral500 : AppColors.white,
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
      houseModelControllerProvider.select((state) => state.hasActiveFilters),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppOutlinedButton(
          key: const ValueKey('filter-models'),
          label: 'Filter',
          icon: Icons.filter_list,
          fitToContent: true,
          height: 36,
          iconSize: 15,
          onPressed: onTap,
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
      houseModelControllerProvider.select((state) => state.genderFilter),
    );
    final body = ref.watch(
      houseModelControllerProvider.select((state) => state.bodyFilter),
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
                    .read(houseModelControllerProvider.notifier)
                    .clearGenderFilter,
              ),
            if (body != null)
              _ActiveChip(
                label: body.label,
                onClear: ref
                    .read(houseModelControllerProvider.notifier)
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
