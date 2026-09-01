part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

const String _productDisplayFontFamily = 'InstrumentSerif';

class _ProductsLibraryHeader extends StatelessWidget {
  const _ProductsLibraryHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _CatalogEyebrow('Product library'),
      const SizedBox(height: 5),
      const Text(
        'Products',
        style: TextStyle(
          fontFamily: _productDisplayFontFamily,
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
        _CatalogEyebrow(label, color: AppColors.whiteAlpha60),
        if (compact) const SizedBox(height: 10) else const Spacer(),
        Text(
          value == null ? '—' : value.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: AppColors.white,
            fontFamily: _productDisplayFontFamily,
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

class _ProductLoadFailure extends StatelessWidget {
  const _ProductLoadFailure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Try again',
            onPressed: onRetry,
            fitToContent: true,
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _AssetImage(product.asset),
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
                    children: [
                      Expanded(child: _CardKicker(product.sku)),
                      _CardKicker('${product.photos} views'),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: _productDisplayFontFamily,
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
        fontFamily: editorialNumber ? _productDisplayFontFamily : null,
        fontStyle: editorialNumber ? FontStyle.italic : null,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
      ),
    ),
  );
}

class _CardKicker extends StatelessWidget {
  const _CardKicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: AppColors.neutral500,
      fontSize: 8,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
    ),
  );
}

class _ProductPill extends StatelessWidget {
  const _ProductPill._({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.textColor,
    this.icon,
  });

  // const _ProductPill.status(String status)
  //   : this._(
  //       label: status,
  //       color: status == 'Calibrated'
  //           ? AppColors.successLight
  //           : AppColors.warningLight,
  //       borderColor: status == 'Calibrated'
  //           ? AppColors.successBorder
  //           : AppColors.warningBorder,
  //       textColor: status == 'Calibrated'
  //           ? AppColors.successDarker
  //           : AppColors.warningDark,
  //     );

  const _ProductPill.dark(String label, {IconData? icon})
    : this._(
        label: label,
        color: AppColors.black,
        borderColor: AppColors.black,
        textColor: AppColors.white,
        icon: icon,
      );

  const _ProductPill.neutral(String label, {IconData? icon})
    : this._(
        label: label,
        color: AppColors.white,
        borderColor: AppColors.neutral200,
        textColor: AppColors.neutral800,
        icon: icon,
      );

  final String label;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Transform.rotate(
              angle: -0.785398,
              child: Icon(icon, size: 10, color: textColor),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1,
                fontWeight: AppTypography.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<ProductUpload?> _pickProductPhoto(
  BuildContext context,
  WidgetRef ref, {
  required String title,
}) async {
  final photos = await _pickProductPhotos(
    context,
    ref,
    remaining: 1,
    title: title,
  );
  return photos.firstOrNull;
}

Future<List<ProductUpload>> _pickProductPhotos(
  BuildContext context,
  WidgetRef ref, {
  required int remaining,
  required String title,
}) async {
  if (remaining <= 0) {
    AppSnackBar.show(
      context,
      'You can upload up to $PRODUCT_PHOTO_UPLOAD_MAX_COUNT photos.',
    );
    return const [];
  }
  final source = await showImageSourceSheet(context, title: title);
  if (source == null || !context.mounted) return const [];
  try {
    final picker = ref.read(imagePickerProvider);
    final files = source == ImageSource.camera || remaining == 1
        ? [
            ?await picker.pickImage(
              source: source,
              maxWidth: 1600,
              imageQuality: 85,
            ),
          ]
        : await picker.pickMultiImage(
            maxWidth: 1600,
            imageQuality: 85,
            limit: remaining,
          );
    final uploads = <ProductUpload>[];
    for (final file in files.take(remaining)) {
      final extension = file.name.split('.').last.toLowerCase();
      if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            '${file.name} must be a JPG, PNG, or WebP image.',
          );
        }
        continue;
      }
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > PRODUCT_PHOTO_UPLOAD_MAX_BYTES) {
        if (context.mounted) {
          AppSnackBar.showError(context, '${file.name} is larger than 20MB.');
        }
        continue;
      }
      uploads.add(
        ProductUpload(
          bytes: bytes,
          fileName: file.name,
          path: file.path,
          localKey:
              '${DateTime.now().microsecondsSinceEpoch}-${uploads.length}-${file.name}',
        ),
      );
    }
    return uploads;
  } on Exception {
    if (context.mounted) {
      AppSnackBar.showError(
        context,
        'Could not open your camera or photo library.',
      );
    }
    return const [];
  }
}
