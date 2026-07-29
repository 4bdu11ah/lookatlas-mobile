part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductPagination extends StatelessWidget {
  const _ProductPagination({
    required this.pageIndex,
    required this.pageCount,
    required this.onPageChanged,
  });

  final int pageIndex;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const ValueKey('create-product-previous-page'),
          onPressed: pageIndex > 0 ? () => onPageChanged(pageIndex - 1) : null,
          icon: const Icon(Icons.chevron_left),
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(36),
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
              width: 36,
              child: index == pageIndex
                  ? PrimaryButton(
                      key: ValueKey('create-product-page-${index + 1}'),
                      label: '${index + 1}',
                      height: 36,
                      onPressed: () => onPageChanged(index),
                    )
                  : AppOutlinedButton(
                      key: ValueKey('create-product-page-${index + 1}'),
                      label: '${index + 1}',
                      height: 36,
                      onPressed: () => onPageChanged(index),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          key: const ValueKey('create-product-next-page'),
          onPressed: pageIndex < pageCount - 1
              ? () => onPageChanged(pageIndex + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(36),
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
    required this.selected,
    required this.onSelect,
    this.onPreview,
    this.square = false,
  });

  final List<(int, String, String, String)> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback? onPreview;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: square ? 1 : 0.78,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SelectionCard(
          title: item.$2,
          subtitle: item.$3,
          asset: item.$4,
          selected: item.$1 == selected,
          onTap: () => onSelect(item.$1),
          onPreview: onPreview,
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
    required this.onTap,
    this.onPreview,
  });

  final String title;
  final String subtitle;
  final String asset;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onPreview;

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
              const Positioned(
                top: 8,
                left: 8,
                child: _Badge('Primary', kind: _BadgeKind.dark),
              ),
            if (onPreview != null)
              Positioned(
                top: 8,
                right: 8,
                child: _SmallOverlayButton(
                  key: ValueKey('director-portfolio-$title'),
                  icon: Icons.visibility_outlined,
                  onTap: onPreview!,
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
    required this.name,
    required this.asset,
  });

  final String count;
  final String name;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: AppColors.neutral50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Caption(count),
          const SizedBox(height: 8),
          Row(
            children: [
              _AssetBox(asset, width: 42, height: 42),
              const SizedBox(width: 9),
              Expanded(child: _CardTitle(name)),
              const _Badge('Primary', kind: _BadgeKind.dark),
            ],
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
              height: 40,
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
    this.onSelect,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: List.generate(
        options.length,
        (index) => InkWell(
          onTap: onSelect == null ? null : () => onSelect!(index),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
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
      ),
    );
  }
}
