part of 'steps/product_step.dart';

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onSelect});

  final ProductCategory? selected;
  final ValueChanged<ProductCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    // "Other" gets its own full-width tile at the end.
    final regular = ProductCategory.values
        .where((c) => c != ProductCategory.other)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
      child: Column(
        spacing: 24,
        children: [
          const WizardStepHeader(
            title: 'What are you shooting?',
            subtitle:
                'This helps us show you the best way to photograph '
                'your product.',
          ),
          Column(
            spacing: 12,
            children: [
              for (var i = 0; i < regular.length; i += 2)
                Row(
                  spacing: 12,
                  children: [
                    for (var j = i; j < i + 2 && j < regular.length; j++)
                      Expanded(
                        child: _CategoryTile(
                          category: regular[j],
                          selected: selected == regular[j],
                          onTap: () => onSelect(regular[j]),
                        ),
                      ),
                  ],
                ),
              _OtherTile(
                selected: selected == ProductCategory.other,
                onTap: () => onSelect(ProductCategory.other),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outline,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(aspectRatio: 1, child: ShotImage(category.imageUrl)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                category.label,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: AppTypography.medium,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherTile extends StatelessWidget {
  const _OtherTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outline,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2.2,
              child: ColoredBox(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 32,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Other',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: AppTypography.medium,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- States B/C: photo upload ------------------------------------------------

class _PhotoUpload extends ConsumerWidget {
  const _PhotoUpload({
    required this.state,
    required this.isSavingProduct,
    required this.onAddPhotos,
  });

  final WizardState state;
  final bool isSavingProduct;
  final VoidCallback onAddPhotos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final category = state.category?.label.toLowerCase() ?? 'product';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          WizardStepHeader(
            title: 'Upload your $category photos',
            subtitle:
                'More photos from different sides help our AI recreate your '
                'product accurately. Upload up to $maxWizardPhotos.',
          ),
          _AngleGuidance(category: state.category),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              CheckLine('White or plain background'),
              CheckLine('Show the full product'),
              CheckLine('Capture logos and unique details'),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  'Your photos',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: AppTypography.medium,
                    color: scheme.onSurface,
                  ),
                ),
                if (state.addingPhotos || isSavingProduct)
                  const _UploadingIndicator()
                else if (state.photos.isEmpty)
                  _DropZone(onTap: onAddPhotos)
                else
                  _PhotoGrid(state: state, onAddPhotos: onAddPhotos),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AngleGuidance extends StatelessWidget {
  const _AngleGuidance({required this.category});

  final ProductCategory? category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Category-specific example shots (e.g. shoes: Front/Side/Top).
    final guides = (category ?? ProductCategory.other).angleGuides;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'For best results, capture these sides',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: AppTypography.medium,
            color: scheme.onSurface,
          ),
        ),
        Row(
          spacing: 12,
          children: [
            for (final (label, asset) in guides)
              Expanded(
                child: Column(
                  spacing: 8,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outline),
                        ),
                        child: ShotImage(asset),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.43,
                        fontWeight: AppTypography.medium,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Text(
          "Don't have all of these? No worries, upload what you have.",
          style: TextStyle(
            fontSize: 14,
            height: 1.43,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _UploadingIndicator extends StatelessWidget {
  const _UploadingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const BarSpinner(size: 28),
            Text(
              'Uploading your photos...',
              style: TextStyle(
                fontSize: 14,
                height: 1.43,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The empty full-square drop target (mockup state C).
class _DropZone extends StatelessWidget {
  const _DropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DashedBorder(
        color: scheme.onSurface.withValues(alpha: 0.2),
        child: AspectRatio(
          aspectRatio: 1,
          child: ColoredBox(
            color: scheme.surface.withValues(alpha: 0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.upload, size: 28, color: scheme.surface),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to add photos',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: AppTypography.semiBold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'JPG or PNG, up to 10MB',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.5),
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

/// Uploaded photos in a 2-column grid with per-photo angle dropdowns, an
/// "Add more" tile and the "Looking good · Clear all" footer.
