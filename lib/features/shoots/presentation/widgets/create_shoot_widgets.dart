part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

const _productOptions = [
  ('Tan Leather Bag', 'BAG-104', '$_img/showcase-bag-before.jpg'),
  ('Gold Heels', 'SH-302', '$_img/showcase-shoes-before.jpg'),
  ('Classic Frames', 'SG-228', '$_img/showcase-sunglasses-before.jpg'),
  ('Silk Dress', 'DR-880', '$_img/showcase-dress-before.jpg'),
  ('Silver Necklace', 'NK-415', '$_img/showcase-necklace-before.jpg'),
  ('Cotton Tee', 'TS-610', '$_img/showcase-tshirt-before.jpg'),
  ('Mini Bag', 'BAG-221', '$_img/showcase-bag-after.jpg'),
  ('Tinted Shades', 'SG-540', '$_img/showcase-sunglasses-after.jpg'),
];

const _modelOptions = [
  ('Mila', 'Female', '$_img/showcase-dress-after.jpg'),
  ('Kai', 'Male', '$_img/showcase-tshirt-after.jpg'),
  ('Ava', 'Female', '$_img/showcase-dress-after.jpg'),
  ('Rose', 'Female', '$_img/showcase-bag-after.jpg'),
];

const _directorOptions = [
  ('Alex Chen', 'Clean Professional', '$_img/showcase-tshirt-after.jpg'),
  ('Isabella Romano', 'Luxury Editorial', '$_img/showcase-dress-after.jpg'),
  ('Marcus Vega', 'Bold & Dramatic', '$_img/showcase-shoes-after.jpg'),
  ('Jordan Kim', 'Street Energy', '$_img/showcase-sunglasses-after.jpg'),
  ('Suki Tanaka', 'Minimalist', '$_img/showcase-bag-after.jpg'),
  ('Emma Santos', 'Lifestyle Natural', '$_img/showcase-necklace-after.jpg'),
];

const _plannedShots = [
  ('Cafe Arrival', 'Natural walking shot entering a bright cafe.'),
  ('Table Detail', 'Close framing on the bag hardware and stitching.'),
  ('Window Portrait', 'Waist-up portrait in soft window light.'),
  ('Street Crossing', 'Confident full-body movement shot.'),
  ('Quiet Product Moment', 'Seated composition with product foregrounded.'),
];

class _CreateShootHeader extends StatelessWidget {
  const _CreateShootHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'New Shoot',
              style: TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: AppTypography.bold,
              ),
            ),
            _Badge('AI Director', kind: _BadgeKind.dark),
          ],
        ),
        SizedBox(height: 4),
        _Caption('AI Director handles everything for you'),
      ],
    );
  }
}

class _CreateSectionHeader extends StatelessWidget {
  const _CreateSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 4),
        _Caption(subtitle),
      ],
    );
  }
}

class _ProductStep extends StatefulWidget {
  const _ProductStep({
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  State<_ProductStep> createState() => _ProductStepState();
}

class _ProductStepState extends State<_ProductStep> {
  static const _pageSize = 4;

  int _pageIndex = 0;

  void _changePage(int pageIndex) {
    setState(() => _pageIndex = pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = (_productOptions.length / _pageSize).ceil();
    final firstProductIndex = _pageIndex * _pageSize;
    final proposedLastIndex = firstProductIndex + _pageSize;
    final lastProductIndex = proposedLastIndex < _productOptions.length
        ? proposedLastIndex
        : _productOptions.length;
    final visibleProducts = _productOptions.sublist(
      firstProductIndex,
      lastProductIndex,
    );
    final selectedOnPage = widget.selected - firstProductIndex;

    return _Stack(
      gap: 12,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _CreateSectionHeader(
                title: 'Select Product',
                subtitle: 'Choose the product you want to photograph',
              ),
            ),
            AppOutlinedButton(
              label: 'Add New Product',
              icon: Icons.add,
              fitToContent: true,
              height: 36,
              onPressed: widget.onAdd,
            ),
          ],
        ),
        const AppTextField(
          fieldKey: ValueKey('create-product-search'),
          hintText: 'Search by name or SKU...',
          textInputAction: TextInputAction.search,
          leading: Icon(Icons.search, size: 20),
        ),
        _SelectedRoster(
          count: '1/3 products',
          name: _productOptions[widget.selected].$1,
          asset: _productOptions[widget.selected].$3,
        ),
        _SelectionGrid(
          items: visibleProducts,
          selected: selectedOnPage,
          square: true,
          onSelect: (index) => widget.onSelect(firstProductIndex + index),
        ),
        if (pageCount > 1)
          _ProductPagination(
            pageIndex: _pageIndex,
            pageCount: pageCount,
            onPageChanged: _changePage,
          ),
      ],
    );
  }
}

class _ModelStep extends StatelessWidget {
  const _ModelStep({
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _Stack(
      gap: 12,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _CreateSectionHeader(
                title: 'Select Model',
                subtitle: 'Choose a model to wear your product',
              ),
            ),
            AppOutlinedButton(
              label: 'Add',
              icon: Icons.add,
              fitToContent: true,
              height: 36,
              onPressed: onAdd,
            ),
          ],
        ),
        const _SegmentedChoices(
          choices: ['My Models · 4', 'LookAtlas · 18'],
          selected: 0,
        ),
        _SelectedRoster(
          count: '1/3 models · 1 primary',
          name: _modelOptions[selected].$1,
          asset: _modelOptions[selected].$3,
        ),
        const AppTextField(
          fieldKey: ValueKey('create-model-search'),
          hintText: 'Search models by name...',
          textInputAction: TextInputAction.search,
          leading: Icon(Icons.search, size: 20),
        ),
        _SelectionGrid(
          items: _modelOptions,
          selected: selected,
          onSelect: onSelect,
        ),
      ],
    );
  }
}

class _DirectorStep extends StatelessWidget {
  const _DirectorStep({
    required this.selected,
    required this.onSelect,
    required this.onPortfolio,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onPortfolio;

  @override
  Widget build(BuildContext context) {
    return _Stack(
      gap: 12,
      children: [
        const _CreateSectionHeader(
          title: 'Choose Your Creative Director',
          subtitle: 'Select what you are creating and who should direct it',
        ),
        const _FieldLabel('What are you creating?'),
        const _OptionWrap(
          options: [
            'Product Page',
            'Social Media',
            'Lookbook',
            'Campaign',
            'Marketplace',
          ],
          selected: 0,
        ),
        const _FieldLabel('Select a Director'),
        _SelectionGrid(
          items: _directorOptions,
          selected: selected,
          onSelect: onSelect,
          onPreview: onPortfolio,
        ),
        TextField(
          minLines: 3,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Brief ${_directorOptions[selected].$1} (optional)',
            hintText: 'Tell your director any specific direction...',
            alignLabelWithHint: true,
          ),
        ),
        const _FieldLabel('Resolution'),
        const _OptionWrap(options: ['1K · 1', '2K · 2', '4K · 4'], selected: 1),
        const _FieldLabel('Additional Settings'),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_Caption('Number of shots'), _CardTitle('5')],
        ),
        Slider(value: 0.5, onChanged: (_) {}),
        const _Caption('Variations per shot'),
        const _OptionWrap(options: ['1', '2', '3', '4', '5'], selected: 2),
        const _Caption('Background preference'),
        const _OptionWrap(
          options: [
            'Studio',
            'Studio Dark',
            'Street',
            'Home',
            'Let AI Decide',
          ],
          selected: 4,
        ),
      ],
    );
  }
}

class _PlanningStep extends StatelessWidget {
  const _PlanningStep({
    required this.isPlanned,
    required this.selectedShots,
    required this.onPlan,
    required this.onToggle,
    required this.onCustom,
  });

  final bool isPlanned;
  final Set<int> selectedShots;
  final VoidCallback onPlan;
  final ValueChanged<int> onToggle;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    if (!isPlanned) {
      return _Stack(
        gap: 14,
        children: [
          const _CreateSectionHeader(
            title: 'Shot Planning',
            subtitle: 'Alex Chen will plan your product page shoot',
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 20),
            color: AppColors.neutral50,
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, size: 28),
                const SizedBox(height: 14),
                const _SectionTitle('Alex Chen will plan 5 unique shots'),
                const SizedBox(height: 6),
                const _Caption(
                  'Style: Clean Professional · For: Product Detail Page',
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  key: const ValueKey('plan-shoot-button'),
                  label: 'Plan My Shoot',
                  icon: Icons.auto_awesome,
                  fitToContent: true,
                  onPressed: onPlan,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return _Stack(
      gap: 11,
      children: [
        const _CreateSectionHeader(
          title: 'Shot Planning',
          subtitle: 'Alex Chen planned a cohesive product page shoot',
        ),
        Text(
          '${selectedShots.length}/10 shots selected',
          style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _plannedShots.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final shot = _plannedShots[index];
            return _PlannedShot(
              title: shot.$1,
              body: shot.$2,
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
  const _ReviewStep();

  @override
  Widget build(BuildContext context) {
    return const _Stack(
      gap: 12,
      children: [
        _CreateSectionHeader(
          title: 'Review & Generate',
          subtitle: 'Confirm your shoot settings',
        ),
        _ReviewGrid(),
        _Alert(
          kind: _AlertKind.info,
          text:
              'Why variations? Each shot is generated 3 times, giving you multiple options to choose from.',
        ),
        _CreditSummary(),
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
  const _ReviewGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Product', 'Tan Leather Bag', '$_img/showcase-bag-before.jpg'),
      ('Model', 'Mila', '$_img/showcase-dress-after.jpg'),
      ('Shots × Variations', '5 shots × 3', ''),
      ('Settings', 'Product Page · 4:5 · 2K', ''),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.35,
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
  const _CreditSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        border: Border.all(color: AppColors.successBorder, width: 2),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle('Credits Required'),
                _Caption('5 shots × 3 variations × 2'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '30',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: AppTypography.bold,
                ),
              ),
              Text(
                '124 available',
                style: TextStyle(fontSize: 11, color: AppColors.successDarker),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
