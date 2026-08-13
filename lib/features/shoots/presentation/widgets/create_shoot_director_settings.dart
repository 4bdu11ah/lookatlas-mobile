part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _DirectorChoiceList extends StatelessWidget {
  const _DirectorChoiceList({
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        key: const ValueKey('director-choice-list'),
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final value = values[index];
          return InkWell(
            onTap: () => onSelect(value),
            child: Container(
              constraints: const BoxConstraints(minWidth: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              color: value == selected ? AppColors.black : AppColors.neutral100,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: value == selected
                      ? AppColors.white
                      : AppColors.neutral500,
                  fontSize: 11,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DemoReviewStep extends StatelessWidget {
  const _DemoReviewStep({required this.state});

  final _CreateShootState state;

  @override
  Widget build(BuildContext context) {
    final totalImages = state.demoDirectors.fold<int>(
      0,
      (total, config) => total + config.numberOfShots * config.variations,
    );
    return _Column(
      gap: 12,
      children: [
        const _CreateSectionHeader(
          title: 'Generate Demo',
          subtitle: 'Each director creates a separate shoot in one demo group',
        ),
        _FieldLabel('${state.demoDirectors.length} directors selected'),
        _Caption('$totalImages total images · HD (2K) · metered', fontSize: 12),
        _Caption(
          '${state.demoRequiredCredits} credits required',
          fontSize: 11,
        ),
        if (!state.canGenerateDemo)
          const _Caption(
            'Not enough credits for this demo configuration.',
            fontSize: 11,
          ),
        for (final config in state.demoDirectors)
          _Caption(
            '${state.directors.firstWhere((director) => director.id == config.directorId).name}: '
            '${config.numberOfShots} shots × ${config.variations} variations',
            fontSize: 11,
          ),
      ],
    );
  }
}
