part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CalibrationCopyStep extends StatelessWidget {
  const _CalibrationCopyStep({
    required this.searchController,
    required this.onBack,
    required this.products,
    required this.onCopy,
    required this.isCopying,
  });

  final TextEditingController searchController;
  final VoidCallback onBack;
  final List<ProductCatalogItem> products;
  final ValueChanged<ProductCatalogItem> onCopy;
  final bool isCopying;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Copy from a calibrated product',
                  copy:
                      'Reuse the size setup from another product. The two calibrations stay independent afterwards.',
                ),
                const SizedBox(height: 14),
                AppTextField(controller: searchController),
                const SizedBox(height: 14),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, _) {
                    final query = value.text.trim().toLowerCase();
                    final matches = products
                        .where(
                          (product) =>
                              query.isEmpty ||
                              '${product.name} ${product.sku} '
                                      '${product.category} '
                                      '${product.subCategory ?? ''}'
                                  .toLowerCase()
                                  .contains(query),
                        )
                        .toList(growable: false);
                    if (matches.isEmpty) {
                      return const Text(
                        'No calibrated products found.',
                        style: TextStyle(color: AppColors.neutral500),
                      );
                    }
                    return ListView.builder(
                      itemCount: matches.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final product = matches[index];
                        return _CopyCard(
                          product: product,
                          onTap: isCopying ? null : () => onCopy(product),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(onBack: onBack, showPrimary: false),
      ],
    );
  }
}

class _SectionCopy extends StatelessWidget {
  const _SectionCopy({required this.title, required this.copy});

  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          copy,
          style: const TextStyle(
            fontSize: 13,
            height: 1.38,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: AppColors.neutral500,
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.asset, this.onTap, super.key});

  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.neutral200, width: 2),
            ),
            child: _AssetImage(asset),
          ),
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AppDottedBorder(
        color: AppColors.neutral200,
        strokeWidth: 2,
        dotWidth: 8,
        gap: 6,
        child: Container(
          color: AppColors.neutral100Alpha68,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.file_upload_outlined, size: 24),
              SizedBox(height: 8),
              Text(
                'Upload another',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'JPG or PNG',
                style: TextStyle(fontSize: 10, color: AppColors.neutral500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckerBox extends StatelessWidget {
  const _CheckerBox({required this.asset, this.upload});

  final String asset;
  final ProductUpload? upload;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 284),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          color: AppColors.neutral50,
        ),
        child: SizedBox(
          width: 176,
          height: 210,
          child: upload == null
              ? _AssetImage(asset)
              : AppImage.memory(upload!.bytes),
        ),
      ),
    );
  }
}

class _ZoomControl extends StatelessWidget {
  const _ZoomControl({
    required this.onZoomOut,
    required this.onReset,
    required this.onZoomIn,
  });

  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton('-', onTap: onZoomOut),
          _ZoomButton('Reset', onTap: onReset, wide: true),
          _ZoomButton('+', onTap: onZoomIn),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton(
    this.label, {
    required this.onTap,
    this.wide = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: wide ? 58 : 38,
        height: 34,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacementCanvas extends StatelessWidget {
  const _PlacementCanvas({
    required this.product,
    required this.bodyArea,
    required this.placementX,
    required this.placementY,
    required this.placementScale,
    this.bodyZoom = 1,
    this.cutout,
    this.onPlacementChanged,
  });

  final _Product product;
  final String bodyArea;
  final double bodyZoom;
  final ProductUpload? cutout;
  final double placementX;
  final double placementY;
  final double placementScale;
  final void Function(double x, double y, double scale)? onPlacementChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 410.0;
        final productWidth = 118 * placementScale;
        final productHeight = 138 * placementScale;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                left: 78,
                right: 78,
                top: 8,
                bottom: 8,
                child: ClipRect(
                  child: Transform.scale(
                    scale: bodyZoom,
                    child: Opacity(
                      opacity: 0.54,
                      child: AppImage(
                        _localOutlineAsset(bodyArea) ?? product.asset,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: placementX * width - productWidth / 2,
                top: placementY * height - productHeight / 2,
                child: GestureDetector(
                  onPanUpdate: onPlacementChanged == null
                      ? null
                      : (details) => onPlacementChanged!(
                          placementX + details.delta.dx / width,
                          placementY + details.delta.dy / height,
                          placementScale,
                        ),
                  child: SizedBox(
                    width: productWidth,
                    height: productHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.black,
                              width: 2,
                            ),
                          ),
                          child: cutout == null
                              ? _AssetImage(product.asset)
                              : AppImage.memory(cutout!.bytes),
                        ),
                        if (onPlacementChanged != null)
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) => onPlacementChanged!(
                                placementX,
                                placementY,
                                placementScale +
                                    (details.delta.dx + details.delta.dy) / 180,
                              ),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  border: Border.all(
                                    color: AppColors.black,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(Icons.open_in_full, size: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
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

class _CopyCard extends StatelessWidget {
  const _CopyCard({
    required this.product,
    required this.onTap,
  });

  final ProductCatalogItem product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: _AssetImage(product.imageUrl),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      product.sku,
                      product.category,
                      ?product.subCategory,
                    ].where((value) => value.isNotEmpty).join(' - '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _ProductPill.neutral('Calibrated'),
                ],
              ),
            ),
            const Icon(Icons.copy_outlined, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ProductFlowFooter extends StatelessWidget {
  const _ProductFlowFooter({
    required this.onBack,
    this.onPrimary,
    this.backLabel = 'Back',
    this.primaryLabel = 'Next',
    this.showPrimary = true,
  });

  final VoidCallback onBack;
  final VoidCallback? onPrimary;
  final String backLabel;
  final String primaryLabel;
  final bool showPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          AppOutlinedButton(
            label: backLabel,
            onPressed: onBack,
            fitToContent: true,
            height: 34,
          ),
          const Spacer(),
          if (showPrimary)
            PrimaryButton(
              label: primaryLabel,
              onPressed: onPrimary,
              fitToContent: true,
              height: 34,
              // backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
            ),
        ],
      ),
    );
  }
}

class _BodyOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neutral400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.width / 2, size.height * 0.18);
    canvas.drawCircle(center, size.shortestSide * 0.11, paint);
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.66)
      ..moveTo(size.width * 0.24, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.32,
        size.width * 0.76,
        size.height * 0.42,
      )
      ..moveTo(size.width * 0.5, size.height * 0.66)
      ..lineTo(size.width * 0.32, size.height * 0.94)
      ..moveTo(size.width * 0.5, size.height * 0.66)
      ..lineTo(size.width * 0.68, size.height * 0.94);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
