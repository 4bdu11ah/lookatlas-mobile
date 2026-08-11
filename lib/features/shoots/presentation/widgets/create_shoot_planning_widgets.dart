part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _PlanningStep extends StatelessWidget {
  const _PlanningStep({
    required this.isPlanned,
    required this.isPlanning,
    required this.shots,
    required this.selectedShots,
    required this.onPlan,
    required this.onToggle,
    required this.onCustom,
  });

  final bool isPlanned;
  final bool isPlanning;
  final List<PlannedShootShot> shots;
  final Set<int> selectedShots;
  final VoidCallback onPlan;
  final ValueChanged<int> onToggle;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    if (!isPlanned) {
      return _Column(
        gap: 14,
        children: [
          const _CreateSectionHeader(
            title: 'Shot Planning',
            subtitle: 'Your selected director will plan this shoot',
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 20),
            color: AppColors.neutral50,
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, size: 28),
                const SizedBox(height: 14),
                const _SectionTitle('Plan unique shots with AI'),
                const SizedBox(height: 6),
                const _Caption(
                  'Uses your product, model, director, and current settings.',
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  key: const ValueKey('plan-shoot-button'),
                  label: 'Plan My Shoot',
                  icon: Icons.auto_awesome,
                  fitToContent: true,
                  isLoading: isPlanning,
                  onPressed: onPlan,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return _Column(
      gap: 11,
      children: [
        const _CreateSectionHeader(
          title: 'Shot Planning',
          subtitle: 'Review and select the generated shot plan',
        ),
        Text(
          '${selectedShots.length}/${shots.length} shots selected',
          style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shots.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final shot = shots[index];
            return _PlannedShot(
              title: shot.title,
              body: shot.description,
              selected: selectedShots.contains(index),
              onTap: () => onToggle(index),
            );
          },
        ),
        AppOutlinedButton(
          label: 'Add Custom Shot',
          icon: Icons.add,
          onPressed: onCustom,
        ),
        AppOutlinedButton(
          label: 'Re-Plan Shots',
          icon: Icons.refresh,
          onPressed: onPlan,
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state, required this.onLaneChanged});

  final _CreateShootState state;
  final ValueChanged<ShootLane> onLaneChanged;

  @override
  Widget build(BuildContext context) {
    return _Column(
      gap: 12,
      children: [
        _CreateSectionHeader(
          title: state.isDemo ? 'Review Demo Shoot' : 'Review & Generate',
          subtitle: state.isDemo
              ? 'One job per director in a single client demo'
              : 'Confirm your shoot settings',
        ),
        _ReviewGrid(state: state),
        const _Alert(
          kind: _AlertKind.info,
          text: 'Each selected shot is generated in every requested variation.',
        ),
        if (state.canUseUnlimited && !state.isDemo) ...[
          const _FieldLabel('Generation speed'),
          _SegmentedChoices(
            choices: const ['Instant · Credits', 'Unlimited · Included'],
            selected: state.settings.lane.index,
            onSelect: (index) => onLaneChanged(ShootLane.values[index]),
          ),
        ],
        _CreditSummary(state: state),
        if (!state.canGenerate && state.settings.lane == ShootLane.fast)
          const _Alert(
            kind: _AlertKind.warn,
            text: 'Not enough credits. Reduce images or choose Unlimited.',
          ),
      ],
    );
  }
}

class _PlannedShot extends StatelessWidget {
  const _PlannedShot({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.neutral100 : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.black : AppColors.neutral200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: selected ? AppColors.black : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.black),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_CardTitle(title), _Caption(body)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewGrid extends StatelessWidget {
  const _ReviewGrid({required this.state});

  final _CreateShootState state;

  @override
  Widget build(BuildContext context) {
    final selection = state.selection;
    final productNames = state.selectedProducts
        .map((item) => item.name)
        .join(' + ');
    final modelNames = state.selectedModels.indexed
        .map(
          (item) =>
              '${item.$2.name} · ${item.$1 == 0 ? 'Primary' : 'Secondary ${item.$1}'}',
        )
        .join('\n');
    final demoDirectors = [
      for (final id in state.selectedDirectorIds)
        '${state.directors.firstWhere((item) => item.id == id).name} · ${state.demoConfigs[id]?.numberOfShots ?? 5} × ${state.demoConfigs[id]?.variations ?? 2}',
    ].join('\n');
    final items = [
      (
        'Products (${state.selectedProducts.length})',
        productNames.isEmpty ? 'Not selected' : productNames,
        selection?.product.imageUrl ?? '',
      ),
      (
        'Models (${state.selectedModels.length})',
        modelNames.isEmpty ? 'Not selected' : modelNames,
        selection?.model.imageUrl ?? '',
      ),
      (
        state.isDemo
            ? 'Directors (${state.selectedDirectorIds.length})'
            : 'Shots × Variations',
        state.isDemo
            ? demoDirectors
            : '${state.chosenShots.length} shots × ${state.settings.variations}',
        '',
      ),
      (
        'Settings',
        '${state.settings.useCase.toUpperCase()} · ${state.settings.aspectRatio} · ${state.settings.imageSize}',
        '',
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.neutral100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Caption(item.$1),
              const SizedBox(height: 7),
              if (item.$3.isNotEmpty)
                Row(
                  children: [
                    _AssetBox(item.$3, width: 42, height: 42),
                    const SizedBox(width: 8),
                    Expanded(child: _CardTitle(item.$2)),
                  ],
                )
              else
                _CardTitle(item.$2),
            ],
          ),
        );
      },
    );
  }
}

class _CreditSummary extends StatelessWidget {
  const _CreditSummary({required this.state});

  final _CreateShootState state;

  @override
  Widget build(BuildContext context) {
    final multiplier = _creditMultiplier(state.settings.imageSize);
    final requiredCredits = state.requiredCredits;
    final unlimited = state.settings.lane == ShootLane.relax;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        border: Border.all(color: AppColors.successBorder, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(
                  unlimited ? 'Included with Unlimited' : 'Credits Required',
                ),
                _Caption(
                  state.isDemo
                      ? '${state.demoTotalImages} images × 2 credits'
                      : '${state.chosenShots.length} shots × '
                            '${state.settings.variations} variations × $multiplier',
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                unlimited ? 'Included' : '$requiredCredits',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: AppTypography.bold,
                ),
              ),
              Text(
                '${state.catalog?.availableCredits ?? 0} available',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.successDarker,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

int _creditMultiplier(String imageSize) => switch (imageSize) {
  '4K' => 3,
  '2K' => 2,
  _ => 1,
};
