part of '../screens/products_page.dart';

class _ProductsLibraryHeader extends StatelessWidget {
  const _ProductsLibraryHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CatalogEyebrow('Product library'),
      const SizedBox(height: 5),
      const Text(
        'Products',
        style: TextStyle(
          fontFamily: productDisplayFontFamily,
          fontSize: 48,
          height: 0.98,
          letterSpacing: -1.6,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'A clean, shoot-ready catalog of every piece your brand brings into the studio.',
        style: TextStyle(
          color: AppColors.neutral500,
          fontSize: 13,
          height: 1.65,
        ),
      ),
      const SizedBox(height: 28),
      PrimaryButton(
        label: 'Add a product',
        icon: Icons.add,
        onPressed: onAdd,
        fitToContent: true,
        height: 44,
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
    ],
  );
}

class _ProductsCatalogStats extends StatelessWidget {
  const _ProductsCatalogStats({
    required this.total,
    required this.loaded,
    required this.calibrated,
  });

  final int total;
  final int loaded;
  final int? calibrated;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Page gutters consume 32 px, so a 420 px viewport gives this card
        // 388 px. Match the HTML breakpoint using the available width.
        final compact = constraints.maxWidth <= 388;
        return ColoredBox(
          color: AppColors.black,
          child: Column(
            children: [
              if (compact) ...[
                _CatalogMetric('Total products', total, compact: true),
                _CatalogMetric('Loaded now', loaded, compact: true),
                _CatalogMetric('Size calibrated', calibrated, compact: true),
              ] else
                SizedBox(
                  height: 88,
                  child: Row(
                    children: [
                      Expanded(child: _CatalogMetric('Total products', total)),
                      Expanded(child: _CatalogMetric('Loaded now', loaded)),
                      Expanded(
                        child: _CatalogMetric('Size calibrated', calibrated),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1, color: AppColors.whiteAlpha20),
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Strong source photography makes every shoot more accurate. Add up to eight front, back, side, and detail views.',
                  style: TextStyle(
                    color: AppColors.whiteAlpha60,
                    fontSize: 10,
                    height: 1.65,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogMetric extends StatelessWidget {
  const _CatalogMetric(this.label, this.value, {this.compact = false});

  final String label;
  final int? value;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? double.infinity : null,
    padding: compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
        : const EdgeInsets.fromLTRB(10, 14, 8, 12),
    decoration: BoxDecoration(
      border: Border(
        right: compact
            ? BorderSide.none
            : const BorderSide(color: AppColors.whiteAlpha20),
        bottom: compact
            ? const BorderSide(color: AppColors.whiteAlpha20)
            : BorderSide.none,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CatalogEyebrow(label, color: AppColors.whiteAlpha60),
        if (compact) const SizedBox(height: 10) else const Spacer(),
        Text(
          value == null ? '—' : value.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: AppColors.white,
            fontFamily: productDisplayFontFamily,
            fontSize: 23,
          ),
        ),
      ],
    ),
  );
}

class _CalibrationCatalogFailure extends StatelessWidget {
  const _CalibrationCatalogFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.neutral100Alpha68,
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Size status is temporarily unavailable. You can keep browsing your products.',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(width: 10),
        AppOutlinedButton(
          label: 'Retry',
          onPressed: onRetry,
          fitToContent: true,
          height: 44,
        ),
      ],
    ),
  );
}

class _ProductEmptyResults extends StatelessWidget {
  const _ProductEmptyResults({
    required this.query,
    required this.hasActiveFilters,
    required this.onClear,
    required this.onAdd,
  });

  final String query;
  final bool hasActiveFilters;
  final VoidCallback onClear;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha68,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 28, color: AppColors.neutral500),
          const SizedBox(height: 10),
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            query.trim().isEmpty
                ? 'Try a different filter combination.'
                : 'No product matches "$query".',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: query.trim().isEmpty && !hasActiveFilters
                ? 'Add a product'
                : 'Clear filters',
            onPressed: query.trim().isEmpty && !hasActiveFilters
                ? onAdd
                : onClear,
            fitToContent: true,
            height: 44,
            backgroundColor: AppColors.black,
            foregroundColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.index,
    required this.product,
    required this.onOpen,
    required this.onCalibrate,
    super.key,
  });

  final int index;
  final _Product product;
  final VoidCallback onOpen;
  final VoidCallback onCalibrate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral100,
      shape: const Border.fromBorderSide(
        BorderSide(color: AppColors.neutral200),
      ),
      child: InkWell(
        key: ValueKey('open-product-${product.sku}'),
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppAssetImage(product.asset),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _CatalogBadge(
                      key: ValueKey('product-index-${product.sku}'),
                      text: (index + 1).toString().padLeft(2, '0'),
                      dark: true,
                      editorialNumber: true,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _CatalogBadge(text: product.category),
                  ),
                  Positioned(
                    top: 8,
                    left: 38,
                    child: Tooltip(
                      message: product.status,
                      child: InkWell(
                        key: ValueKey('calibrate-product-${product.sku}'),
                        onTap: onCalibrate,
                        child: _ProductCalibrationIndicator(
                          sku: product.sku,
                          status: product.calibrationStatus,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CardKicker(product.sku, maxLines: null),
                      ),
                      _CardKicker('${product.photos} views'),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontFamily: productDisplayFontFamily,
                            fontSize: 19,
                            height: 1,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 15),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.neutral200),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _CardKicker('View product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCalibrationIndicator extends StatelessWidget {
  const _ProductCalibrationIndicator({
    required this.sku,
    required this.status,
  });

  final String sku;
  final ProductCalibrationStatus status;

  IconData get _icon => switch (status) {
    ProductCalibrationStatus.calibrated ||
    ProductCalibrationStatus.changesPending => Icons.check_circle_outline,
    ProductCalibrationStatus.fitRendering ||
    ProductCalibrationStatus.fitPending => Icons.hourglass_top,
    ProductCalibrationStatus.fitReady ||
    ProductCalibrationStatus.saveReady => Icons.rate_review_outlined,
    ProductCalibrationStatus.fitFailed => Icons.error_outline,
    ProductCalibrationStatus.recommended ||
    ProductCalibrationStatus.optional => Icons.straighten,
  };

  Color get _color => switch (status) {
    ProductCalibrationStatus.calibrated ||
    ProductCalibrationStatus.changesPending => AppColors.successDarker,
    ProductCalibrationStatus.fitFailed => AppColors.danger,
    _ => AppColors.neutral800,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    label: status.label,
    button: true,
    child: Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Transform.rotate(
        angle:
            status == ProductCalibrationStatus.recommended ||
                status == ProductCalibrationStatus.optional
            ? -0.785398
            : 0,
        child: Icon(
          _icon,
          key: ValueKey('product-status-icon-$sku'),
          size: 16,
          color: _color,
        ),
      ),
    ),
  );
}

class _CatalogBadge extends StatelessWidget {
  const _CatalogBadge({
    required this.text,
    this.dark = false,
    this.editorialNumber = false,
    super.key,
  });

  final String text;
  final bool dark;
  final bool editorialNumber;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    color: dark ? AppColors.black : AppColors.white,
    child: Text(
      text.toUpperCase(),
      maxLines: 1,
      style: TextStyle(
        color: dark ? AppColors.white : AppColors.black,
        fontFamily: editorialNumber ? productDisplayFontFamily : null,
        fontStyle: editorialNumber ? FontStyle.italic : null,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
      ),
    ),
  );
}

class _CardKicker extends StatelessWidget {
  const _CardKicker(this.text, {this.maxLines = 1});

  final String text;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: maxLines,
    overflow: maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
    style: const TextStyle(
      color: AppColors.neutral500,
      fontSize: 8,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
    ),
  );
}
