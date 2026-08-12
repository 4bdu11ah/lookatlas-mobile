part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

const _directorBrands = <String, String>{
  'clean-pro': 'Uniqlo, Everlane',
  'luxury-editorial': 'Hermès, Loro Piana',
  'bold-dramatic': 'Versace, Balmain',
  'street-energy': 'Zara, ASOS',
  'minimalist': 'COS, Arket',
  'lifestyle-natural': 'Reformation, Madewell',
  'fine-jewelry': 'Tiffany & Co., Cartier',
  'editorial-jewelry': 'Mejuri, Net-a-Porter',
  'heirloom-children': 'Bonpoint, Tartine et Chocolat',
};

class _UseCaseGrid extends StatelessWidget {
  const _UseCaseGrid({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const useCases = [
      ('Product Detail Page', Icons.inventory_2_outlined),
      ('Social Media', Icons.alternate_email),
      ('Lookbook / Catalog', Icons.view_list_outlined),
      ('Campaign / Hero', Icons.diamond_outlined),
      ('Marketplace', Icons.grid_view_outlined),
    ];
    return GridView.builder(
      key: const ValueKey('create-use-case-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: useCases.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 69,
      ),
      itemBuilder: (context, index) {
        final useCase = useCases[index];
        final isSelected = index == selected;
        return Material(
          key: ValueKey('create-use-case-${useCase.$1}'),
          color: isSelected ? AppColors.neutral100 : AppColors.white,
          child: InkWell(
            onTap: () => onSelect(index),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.neutral200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    useCase.$2,
                    size: 20,
                    color: isSelected ? AppColors.black : AppColors.neutral900,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    useCase.$1,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.black
                          : AppColors.neutral900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DirectorGrid extends StatelessWidget {
  const _DirectorGrid({
    required this.directors,
    required this.selectedIndices,
    required this.onSelect,
    required this.onPreview,
  });

  final List<ShootLook> directors;
  final Set<int> selectedIndices;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onPreview;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('create-director-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: directors.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) => _DirectorCard(
        director: directors[index],
        selected: selectedIndices.contains(index),
        onSelect: () => onSelect(index),
        onPreview: () => onPreview(index),
      ),
    );
  }
}

class _DirectorCard extends StatelessWidget {
  const _DirectorCard({
    required this.director,
    required this.selected,
    required this.onSelect,
    required this.onPreview,
  });

  final ShootLook director;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: selected ? 0.98 : 1,
      child: Material(
        key: ValueKey('selection-${director.name}'),
        color: AppColors.neutral200,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.black : AppColors.neutral200,
              width: 2,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(color: AppColors.blackAlpha20, spreadRadius: 2),
                  ]
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _AssetImage(director.imageUrl),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.transparent, AppColors.blackAlpha90],
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(onTap: onSelect),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Material(
                  key: ValueKey('director-portfolio-${director.name}'),
                  color: AppColors.whiteAlpha90,
                  child: InkWell(
                    onTap: onPreview,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.visibility_outlined, size: 17),
                    ),
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 11,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        director.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        director.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.whiteAlpha80,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Like ${_directorBrands[director.id] ?? director.subtitle}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.whiteAlpha70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductGridShimmer extends StatelessWidget {
  const _ProductGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('create-product-grid-shimmer'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 205,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, _) => const ShimmerBox(),
    );
  }
}

class _ProductPagination extends StatelessWidget {
  const _ProductPagination({
    required this.pageIndex,
    required this.pageCount,
    required this.onPageChanged,
    this.keyPrefix = 'product',
  });

  final int pageIndex;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: ValueKey('create-$keyPrefix-previous-page'),
          onPressed: pageIndex > 0 ? () => onPageChanged(pageIndex - 1) : null,
          icon: const Icon(Icons.chevron_left),
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(30),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const RoundedRectangleBorder(),
            side: const BorderSide(color: AppColors.neutral200),
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(
          pageCount,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: SizedBox(
              width: 30,
              child: AppOutlinedButton(
                key: ValueKey('create-$keyPrefix-page-${index + 1}'),
                label: '${index + 1}',
                height: 30,
                borderColor: index == pageIndex
                    ? AppColors.black
                    : AppColors.neutral200,
                backgroundColor: index == pageIndex
                    ? AppColors.black
                    : AppColors.white,
                foregroundColor: index == pageIndex
                    ? AppColors.white
                    : AppColors.black,
                onPressed: () => onPageChanged(index),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          key: ValueKey('create-$keyPrefix-next-page'),
          onPressed: pageIndex < pageCount - 1
              ? () => onPageChanged(pageIndex + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(30),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const RoundedRectangleBorder(),
            side: const BorderSide(color: AppColors.neutral200),
          ),
        ),
      ],
    );
  }
}

class _SelectionGrid extends StatelessWidget {
  const _SelectionGrid({
    required this.items,
    required this.selectedIndices,
    required this.onSelect,
    this.selectedLabels = const {},
    this.disabledIndices = const {},
    this.selectedLabelOnLeft = false,
    this.square = false,
  });

  final List<(int, String, String, String)> items;
  final Set<int> selectedIndices;
  final ValueChanged<int> onSelect;
  final Map<int, String> selectedLabels;
  final Set<int> disabledIndices;
  final bool selectedLabelOnLeft;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 205,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: square ? 1 : 0.78,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isDisabled = disabledIndices.contains(item.$1);
        return Opacity(
          key: ValueKey('selection-opacity-${item.$2}'),
          opacity: isDisabled ? 0.35 : 1,
          child: IgnorePointer(
            key: ValueKey('selection-disabled-${item.$2}'),
            ignoring: isDisabled,
            child: _SelectionCard(
              title: item.$2,
              subtitle: item.$3,
              asset: item.$4,
              selected: selectedIndices.contains(item.$1),
              selectedLabel: selectedLabels[item.$1],
              selectedLabelOnLeft: selectedLabelOnLeft,
              onTap: () => onSelect(item.$1),
            ),
          ),
        );
      },
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.selected,
    required this.selectedLabel,
    required this.selectedLabelOnLeft,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String asset;
  final bool selected;
  final String? selectedLabel;
  final bool selectedLabelOnLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('selection-$title'),
      color: AppColors.neutral100,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.black : AppColors.neutral200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AssetImage(asset),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.transparent, AppColors.blackAlpha80],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: AppColors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
            if (selected)
              Positioned(
                top: 8,
                left: selectedLabelOnLeft ? 8 : null,
                right: selectedLabelOnLeft ? null : 8,
                child: _Badge(
                  selectedLabel ?? 'Primary',
                  kind: _BadgeKind.dark,
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 9,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.whiteAlpha80,
                        fontSize: 9,
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
}

class _SelectedRoster extends StatelessWidget {
  const _SelectedRoster({
    required this.count,
    required this.items,
    required this.onClear,
    required this.onRemove,
  });

  final String count;
  final List<ShootCatalogItem> items;
  final VoidCallback onClear;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('create-model-selection-panel'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Caption(count, fontSize: 12)),
              if (items.length > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClear,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          for (final (index, items) in items.indexed)
            _selectedProductRow(
              product: items,
              role: index == 0 ? 'Primary' : 'Secondary $index',
              onRemove: () => onRemove(_modelKey(items)),
              margin: const EdgeInsets.only(bottom: 7),
            ),
        ],
      ),
    );
  }
}

class _SegmentedChoices extends StatelessWidget {
  const _SegmentedChoices({
    required this.choices,
    required this.selected,
    this.onSelect,
  });

  final List<String> choices;
  final int selected;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        choices.length,
        (index) => Expanded(
          child: InkWell(
            onTap: onSelect == null ? null : () => onSelect!(index),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: index == selected ? AppColors.black : AppColors.white,
                border: Border.all(color: AppColors.black),
              ),
              child: Text(
                choices[index],
                style: TextStyle(
                  color: index == selected ? AppColors.white : AppColors.black,
                  fontSize: 11,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({
    required this.options,
    required this.selected,
  });

  final List<String> options;
  final int selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: List.generate(
        options.length,
        (index) => Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: index == selected ? AppColors.black : AppColors.white,
            border: Border.all(color: AppColors.black),
          ),
          child: Text(
            options[index],
            style: TextStyle(
              color: index == selected ? AppColors.white : AppColors.black,
              fontSize: 10,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
      ),
    );
  }
}
