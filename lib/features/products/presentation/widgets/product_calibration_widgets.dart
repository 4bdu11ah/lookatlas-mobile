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
        const _StepIndicator(current: 1, total: 3, label: 'Product'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Copy from a calibrated product',
                  copy: 'Choose a similar product whose real-world size is already set.',
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: searchController,
                  hintText: 'Search products',
                  height: 46,
                  textStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                ),
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
          style: const TextStyle(
            fontFamily: 'InstrumentSerif',
            fontSize: 16,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          copy,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
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
        fontWeight: AppTypography.bold,
        letterSpacing: .88,
        color: AppColors.neutral500,
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.asset,
    required this.angle,
    this.onTap,
    super.key,
  });

  final String asset;
  final String angle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.neutral200, width: 2),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(7),
                    child: _AssetImage(asset, fit: BoxFit.contain),
                  ),
                  Positioned(
                    left: 5,
                    right: 5,
                    bottom: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      color: AppColors.blackAlpha90,
                      child: Text(
                        angle.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: AppTypography.bold,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 44,
              child: ColoredBox(
                color: AppColors.black,
                child: Center(
                  child: Text(
                    'Use this photo →',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                'JPG, PNG, or WebP · max 20MB',
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
      child: CustomPaint(
        painter: const _CheckerPainter(),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
          ),
          child: SizedBox(
            width: 176,
            height: 210,
            child: upload == null
                ? _AssetImage(asset)
                : AppImage.memory(upload!.bytes),
          ),
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
        width: wide ? 60 : 44,
        height: 44,
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

class _PlacementCanvas extends StatefulWidget {
  const _PlacementCanvas({
    required this.product,
    required this.bodyArea,
    required this.placementX,
    required this.placementY,
    required this.placementScale,
    this.placementRotation = 0,
    this.bodyZoom = 1,
    this.cutout,
    this.onPlacementChanged,
    this.onRotationChanged,
  });

  final _Product product;
  final String bodyArea;
  final double bodyZoom;
  final ProductUpload? cutout;
  final double placementX;
  final double placementY;
  final double placementScale;
  final double placementRotation;
  final void Function(double x, double y, double scale)? onPlacementChanged;
  final ValueChanged<double>? onRotationChanged;

  @override
  State<_PlacementCanvas> createState() => _PlacementCanvasState();
}

class _PlacementCanvasState extends State<_PlacementCanvas> {
  late double _startX;
  late double _startY;
  late double _startScale;
  late double _startRotation;
  Offset _startFocal = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 410.0;
        final productWidth = width * .22 * widget.placementScale;
        final productHeight = height * (260 / 1500) * widget.placementScale;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                top: 8,
                bottom: 8,
                child: ClipRect(
                  child: Transform.scale(
                    scale: widget.bodyZoom,
                    child: AppImage(
                      _localOutlineAsset(widget.bodyArea) ??
                          widget.product.asset,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: widget.placementX * width - productWidth / 2,
                top: widget.placementY * height - productHeight / 2,
                child: GestureDetector(
                  onScaleStart: widget.onPlacementChanged == null
                      ? null
                      : (details) {
                          _startX = widget.placementX;
                          _startY = widget.placementY;
                          _startScale = widget.placementScale;
                          _startRotation = widget.placementRotation;
                          _startFocal = details.focalPoint;
                        },
                  onScaleUpdate: widget.onPlacementChanged == null
                      ? null
                      : (details) {
                          widget.onPlacementChanged!(
                            _startX +
                                (details.focalPoint.dx - _startFocal.dx) /
                                    width,
                            _startY +
                                (details.focalPoint.dy - _startFocal.dy) /
                                    height,
                            _startScale * details.scale,
                          );
                          widget.onRotationChanged?.call(
                            _startRotation + details.rotation * 180 / pi,
                          );
                        },
                  child: Transform.rotate(
                    angle: widget.placementRotation * pi / 180,
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
                            child: widget.cutout == null
                                ? _AssetImage(
                                    widget.product.asset,
                                    fit: BoxFit.contain,
                                  )
                                : AppImage.memory(
                                    widget.cutout!.bytes,
                                  ),
                          ),
                          if (widget.onPlacementChanged != null)
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (details) =>
                                    widget.onPlacementChanged!(
                                      widget.placementX,
                                      widget.placementY,
                                      widget.placementScale +
                                          (details.delta.dx +
                                                  details.delta.dy) /
                                              180,
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
                                  child: const Icon(
                                    Icons.open_in_full,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
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
                ],
              ),
            ),
            const _CalibrationRecommendedBadge(label: 'Calibrated'),
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
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onBack,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: AppColors.black,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: AppTypography.medium,
              ),
              shape: const RoundedRectangleBorder(),
            ),
            child: Text(backLabel),
          ),
          const Spacer(),
          if (showPrimary)
            _CalibrationActionButton(
              label: primaryLabel,
              onPressed: onPrimary,
            ),
        ],
      ),
    );
  }
}

class _CalibrationActionButton extends StatelessWidget {
  const _CalibrationActionButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.fullWidth = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool fullWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      backgroundColor: outlined ? AppColors.white : AppColors.black,
      foregroundColor: outlined ? AppColors.black : AppColors.white,
      disabledBackgroundColor: outlined ? AppColors.white : AppColors.black,
      disabledForegroundColor: outlined
          ? AppColors.neutral400
          : AppColors.white,
      side: BorderSide(
        color: AppColors.black,
        width: outlined ? 2 : 1,
      ),
      shape: const RoundedRectangleBorder(),
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: AppTypography.bold,
      ),
    );
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 44,
      child: icon == null
          ? OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 16),
              label: Text(label),
            ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const square = 10.0;
    final light = Paint()..color = const Color(0xFFF7F7F5);
    final dark = Paint()..color = const Color(0xFFDEDED9);
    canvas.drawRect(Offset.zero & size, light);
    for (var y = 0; y < (size.height / square).ceil(); y++) {
      for (var x = 0; x < (size.width / square).ceil(); x++) {
        if ((x + y).isEven) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * square, y * square, square, square),
          dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
