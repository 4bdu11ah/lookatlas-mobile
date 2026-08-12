part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _DirectorStep extends StatelessWidget {
  const _DirectorStep({
    required this.directors,
    required this.settings,
    required this.selected,
    required this.catalog,
    required this.demoMode,
    required this.demoDirectors,
    required this.onSelect,
    required this.onDemoDirectorChanged,
    required this.onSettingsChanged,
    required this.onPortfolio,
    required this.onUpgrade,
  });

  final List<ShootLook> directors;
  final ShootSettings settings;
  final int selected;
  final ShootCreateCatalog? catalog;
  final bool demoMode;
  final List<DemoDirectorConfig> demoDirectors;
  final ValueChanged<int> onSelect;
  final ValueChanged<DemoDirectorConfig> onDemoDirectorChanged;
  final ValueChanged<ShootSettings> onSettingsChanged;
  final ValueChanged<int> onPortfolio;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final director = directors.isEmpty
        ? null
        : directors[selected.clamp(0, directors.length - 1)];
    return _Column(
      gap: 24,
      children: [
        const _CreateSectionHeader(
          title: 'Choose Your Creative Director',
          subtitle:
              "Select what you're creating and who should direct the shoot",
        ),
        const _FieldLabel('What are you creating?'),
        _UseCaseGrid(
          selected: const [
            'pdp',
            'social',
            'lookbook',
            'campaign',
            'marketplace',
          ].indexOf(settings.useCase).clamp(0, 4),
          onSelect: (index) => onSettingsChanged(
            settings.copyWith(
              useCase: const [
                'pdp',
                'social',
                'lookbook',
                'campaign',
                'marketplace',
              ][index],
            ),
          ),
        ),
        _FieldLabel(
          demoMode ? 'Select directors (one or more)' : 'Select a Director',
        ),
        if (demoMode)
          const _Caption(
            'Each director becomes one section of the demo, so the client can '
            'see their products in several styles.',
            fontSize: 11,
          ),
        _DirectorGrid(
          directors: directors,
          selectedIndices: demoMode
              ? {
                  for (final (index, director) in directors.indexed)
                    if (demoDirectors.any(
                      (config) => config.directorId == director.id,
                    ))
                      index,
                }
              : {selected},
          onSelect: onSelect,
          onPreview: onPortfolio,
        ),
        if (demoMode && demoDirectors.isNotEmpty)
          for (final config in demoDirectors)
            _DemoDirectorBudget(
              config: config,
              director: directors.firstWhere(
                (director) => director.id == config.directorId,
              ),
              onChanged: onDemoDirectorChanged,
              onRemove: () => onSelect(
                directors.indexWhere(
                  (director) => director.id == config.directorId,
                ),
              ),
            ),
        if (demoMode && demoDirectors.isNotEmpty)
          AppTextField(
            fieldKey: const ValueKey('create-director-brief'),
            labelText: 'Brief the directors (optional)',
            hintText: 'Tell every director the direction for this shoot.',
            minLines: 3,
            maxLines: 4,
            onChanged: (value) => onSettingsChanged(
              settings.copyWith(directorFeedback: value),
            ),
          ),
        if (demoMode && demoDirectors.isNotEmpty)
          const _Caption(
            'Shared by every director in this demo. Each one plans their '
            'shots with this brief in their own style.',
            fontSize: 11,
          ),
        if (!demoMode && director != null) ...[
          _DirectorBrief(
            director: director,
            onChanged: (value) => onSettingsChanged(
              settings.copyWith(directorFeedback: value),
            ),
          ),
          if (director.id == 'heirloom-children')
            _HeirloomStylingFields(
              values: settings.stylingNotes,
              onChanged: (values) => onSettingsChanged(
                settings.copyWith(stylingNotes: values),
              ),
            ),
        ],
        if (!demoMode && (catalog?.relaxEnabled ?? false))
          _UnlimitedDirectorCard(
            plan: catalog?.plan ?? '',
            eligible: catalog?.isUnlimitedEligible ?? false,
            onUpgrade: onUpgrade,
          ),
        _DirectorResolution(
          settings: settings,
          catalog: catalog,
          demoMode: demoMode,
          onChanged: onSettingsChanged,
        ),
        _DirectorAdditionalSettings(
          settings: settings,
          catalog: catalog,
          demoMode: demoMode,
          onChanged: onSettingsChanged,
        ),
      ],
    );
  }
}

class _DemoDirectorBudget extends StatelessWidget {
  const _DemoDirectorBudget({
    required this.config,
    required this.director,
    required this.onChanged,
    required this.onRemove,
  });

  final DemoDirectorConfig config;
  final ShootLook director;
  final ValueChanged<DemoDirectorConfig> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final maxShots = director.id == 'fine-jewelry' ? 7 : 8;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: AppColors.neutral50,
        child: _Column(
          gap: 10,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${director.name} · ${director.subtitle}',
                    style: const TextStyle(fontWeight: AppTypography.bold),
                  ),
                ),
                TextButton(onPressed: onRemove, child: const Text('Remove')),
              ],
            ),
            _Caption('Shots: ${config.numberOfShots}', fontSize: 10),
            Slider(
              min: 1,
              max: maxShots.toDouble(),
              divisions: maxShots - 1,
              value: config.numberOfShots.toDouble(),
              onChanged: (value) => onChanged(
                config.copyWith(numberOfShots: value.round()),
              ),
            ),
            const _Caption('Variations / shot', fontSize: 10),
            _DirectorChoiceWrap(
              values: const ['1', '2', '3', '4', '5'],
              selected: '${config.variations}',
              onSelect: (value) => onChanged(
                config.copyWith(variations: int.parse(value)),
              ),
            ),
            _Caption(
              '${config.numberOfShots * config.variations} images from this director',
              fontSize: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectorBrief extends StatelessWidget {
  const _DirectorBrief({required this.director, required this.onChanged});

  final ShootLook director;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: const ValueKey('create-director-brief'),
      labelText: 'Brief ${director.name} (optional)',
      hintText:
          'Tell ${director.name} any specific direction for your shoot. '
          'E.g., “Focus on the texture”, “Make it feel summery”, '
          '“Emphasize the craftsmanship”…',
      minLines: 3,
      maxLines: 4,
      onChanged: onChanged,
    );
  }
}

class _HeirloomStylingFields extends StatelessWidget {
  const _HeirloomStylingFields({
    required this.values,
    required this.onChanged,
  });

  final Map<String, String> values;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  Widget build(BuildContext context) {
    const fields = [
      ('clothingStyle', 'Clothing style', 'Wool and cotton dresses'),
      ('dressLength', 'Dress length', 'Just below the knee'),
      ('socksOrTights', 'Socks or tights', 'Knee-high cotton socks'),
      ('hairstyle', 'Hairstyle', 'Worn down with a simple headband'),
      ('other', 'Other notes (accessories, etc.)', 'Accessories and shoes'),
    ];
    return Semantics(
      liveRegion: true,
      child: _Column(
        gap: 11,
        children: [
          const _FieldLabel('Styling for Beatrice Hartley (optional)'),
          const _Caption(
            "Paste the client's per-style wardrobe spec. Each box overrides "
            "this director's default for that item; leave a box blank to keep "
            'the default. Location, scene, and mood are unaffected.',
            fontSize: 11,
          ),
          for (final field in fields)
            AppTextField(
              fieldKey: ValueKey('create-styling-${field.$1}'),
              labelText: field.$2,
              hintText: field.$3,
              minLines: 2,
              maxLines: 3,
              onChanged: (value) => onChanged({...values, field.$1: value}),
            ),
        ],
      ),
    );
  }
}

class _UnlimitedDirectorCard extends StatelessWidget {
  const _UnlimitedDirectorCard({
    required this.plan,
    required this.eligible,
    required this.onUpgrade,
  });

  final String plan;
  final bool eligible;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final business = plan == 'enterprise';
    final title = business
        ? 'Unlimited photos at priority speed'
        : 'Unlimited photos';
    final description = business
        ? 'Included in your plan, at priority speed. Photos arrive a few '
              'minutes apart while the shoot finishes in the background.'
        : eligible
        ? 'Included in your plan. Photos arrive roughly every 15 to 20 '
              'minutes and continue in the background.'
        : 'Stop counting credits. Included on Pro and Business.';
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: eligible ? null : onUpgrade,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('∞', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: AppTypography.bold),
                    ),
                    const SizedBox(height: 4),
                    _Caption(description, fontSize: 11),
                  ],
                ),
              ),
              if (!eligible) const Icon(Icons.lock_outline, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectorResolution extends StatelessWidget {
  const _DirectorResolution({
    required this.settings,
    required this.catalog,
    required this.demoMode,
    required this.onChanged,
  });

  final ShootSettings settings;
  final ShootCreateCatalog? catalog;
  final bool demoMode;
  final ValueChanged<ShootSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final eligible = catalog?.isUnlimitedEligible ?? false;
    final business = catalog?.plan == 'enterprise';
    final sizes = demoMode
        ? const ['1K', '2K', '4K']
        : eligible
        ? const ['2K', '4K']
        : const ['1K', '2K', '4K'];
    final helper = demoMode
        ? 'Demo shoots use HD (2K)'
        : eligible
        ? business
              ? '2K and 4K included, unlimited'
              : 'Unlimited photos are HD (2K). 4K is a Business feature.'
        : 'Higher resolution uses more credits';
    return _Column(
      gap: 10,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Resolution'),
            const Spacer(),
            Flexible(child: _Caption(helper, fontSize: 10)),
          ],
        ),
        Row(
          children: [
            for (final (index, size) in sizes.indexed) ...[
              if (index > 0) const SizedBox(width: 7),
              Expanded(
                child: _ResolutionOption(
                  size: size,
                  selected: settings.imageSize == size,
                  disabled:
                      (demoMode && size != '2K') || (size == '4K' && !business),
                  included: !demoMode && eligible && (size == '2K' || business),
                  onTap: () {
                    final useRelax =
                        !demoMode && eligible && (size == '2K' || business);
                    onChanged(
                      settings.copyWith(
                        imageSize: size,
                        lane: useRelax ? ShootLane.relax : ShootLane.fast,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ResolutionOption extends StatelessWidget {
  const _ResolutionOption({
    required this.size,
    required this.selected,
    required this.disabled,
    required this.included,
    required this.onTap,
  });

  final String size;
  final bool selected;
  final bool disabled;
  final bool included;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (size) {
      '1K' => 'Standard (1K)',
      '4K' => 'Ultra HD (4K)',
      _ => 'HD (2K)',
    };
    final credits = switch (size) {
      '1K' => 1,
      '4K' => 3,
      _ => 2,
    };
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? AppColors.neutral50 : AppColors.white,
            border: Border.all(
              color: selected ? AppColors.black : AppColors.neutral200,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 5),
              _Caption(
                disabled
                    ? 'Business plan'
                    : included
                    ? 'Included, unlimited'
                    : '$credits credit${credits == 1 ? '' : 's'} / image',
                fontSize: 9,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectorAdditionalSettings extends StatelessWidget {
  const _DirectorAdditionalSettings({
    required this.settings,
    required this.catalog,
    required this.demoMode,
    required this.onChanged,
  });

  final ShootSettings settings;
  final ShootCreateCatalog? catalog;
  final bool demoMode;
  final ValueChanged<ShootSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final maxShots = settings.directorId == 'fine-jewelry' ? 7 : 8;
    final ratios = (catalog?.supportedAspectRatios ?? const ['4:5'])
        .take(4)
        .toList();
    const backgrounds = [
      ('studio', 'Studio'),
      ('studio_dark', 'Studio Dark'),
      ('street', 'Street'),
      ('home', 'Home'),
      ('ai_decide', 'Let AI Decide'),
    ];
    return _Column(
      gap: 12,
      children: [
        const _FieldLabel('Additional Settings'),
        if (!demoMode) ...[
          const _Caption('Number of Shots', fontSize: 11),
          Row(
            children: [
              Expanded(
                child: Slider(
                  key: const ValueKey('create-shot-count'),
                  min: 1,
                  max: maxShots.toDouble(),
                  divisions: maxShots - 1,
                  value: settings.numberOfShots.clamp(1, maxShots).toDouble(),
                  onChanged: (value) => onChanged(
                    settings.copyWith(numberOfShots: value.round()),
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                child: Text('${settings.numberOfShots.clamp(1, maxShots)}'),
              ),
            ],
          ),
        ],
        const _Caption('Aspect Ratio', fontSize: 11),
        _DirectorChoiceWrap(
          values: ratios,
          selected: settings.aspectRatio,
          onSelect: (value) => onChanged(settings.copyWith(aspectRatio: value)),
        ),
        if (!demoMode) ...[
          const _Caption('Variations per Shot', fontSize: 11),
          _DirectorChoiceWrap(
            values: const ['1', '2', '3', '4', '5'],
            selected: '${settings.variations}',
            onSelect: (value) =>
                onChanged(settings.copyWith(variations: int.parse(value))),
          ),
          _Caption(
            '${settings.numberOfShots * settings.variations} total images\n'
            'AI generation can occasionally produce unexpected results. '
            'Multiple variations give you options to choose from. '
            'We recommend 3 or more.',
            fontSize: 10,
          ),
        ],
        const _Caption('Background Preference', fontSize: 11),
        _DirectorChoiceWrap(
          values: [for (final background in backgrounds) background.$2],
          selected: backgrounds
              .firstWhere(
                (item) => item.$1 == settings.background,
                orElse: () => backgrounds.last,
              )
              .$2,
          onSelect: (value) => onChanged(
            settings.copyWith(
              background: backgrounds.firstWhere((item) => item.$2 == value).$1,
            ),
          ),
        ),
      ],
    );
  }
}
