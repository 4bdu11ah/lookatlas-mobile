part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CalibrationPickPhotoStep extends StatelessWidget {
  const _CalibrationPickPhotoStep({
    required this.product,
    required this.bodyArea,
    required this.onBack,
    required this.onNext,
    required this.onPhotoSelected,
    required this.onChangeBody,
  });

  final _Product product;
  final String bodyArea;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<String> onPhotoSelected;
  final VoidCallback onChangeBody;

  @override
  Widget build(BuildContext context) {
    final photos = product.productPhotos.isEmpty
        ? [
            for (final asset in product.photoAssets.indexed)
              (url: asset.$2, angle: 'View ${asset.$1 + 1}'),
          ]
        : [
            for (final photo in product.productPhotos)
              (url: photo.url, angle: photo.viewAngle ?? 'Product'),
          ];
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
                  title: 'Choose a clear product photo',
                  copy: 'A front-facing photo with the whole product visible works best. We’ll remove the background automatically.',
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Kicker('Size guide'),
                          const SizedBox(height: 8),
                          AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.neutral200,
                                ),
                              ),
                              child: AppImage(
                                _localOutlineAsset(bodyArea) ?? product.asset,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _bodyViewLabel(bodyArea),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onChangeBody,
                            icon: const Icon(Icons.edit_outlined, size: 13),
                            label: const Text('Change'),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(44, 44),
                              padding: EdgeInsets.zero,
                              foregroundColor: AppColors.neutral500,
                              textStyle: const TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            'Choose a photo from roughly this angle.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.45,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Kicker('Choose a clear product photo'),
                          const SizedBox(height: 10),
                          for (final (index, photo) in photos.indexed) ...[
                            _PhotoTile(
                              key: ValueKey('calibration-photo-$index'),
                              asset: photo.url,
                              angle: photo.angle,
                              onTap: () => onPhotoSelected(photo.url),
                            ),
                            const SizedBox(height: 10),
                          ],
                          AspectRatio(
                            aspectRatio: 1.25,
                            child: _UploadTile(onTap: onNext),
                          ),
                        ],
                      ),
                    ),
                  ],
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

String _bodyViewLabel(String bodyArea) => switch (bodyArea) {
  'full_body_front' => 'Full body front',
  'full_body_side' => 'Full body side',
  'waist_front' => 'Waist front',
  'hand_side' => 'Hand side',
  'hand_palm' => 'Hand palm',
  'wrist_side' => 'Wrist side',
  'neck_chest' => 'Neck and chest',
  'face_front' => 'Face front',
  'head_3q' => 'Head three-quarter',
  'ear_profile' => 'Ear profile',
  'foot_side' => 'Foot side',
  _ => bodyArea.replaceAll('_', ' '),
};

class _CalibrationProgressStep extends StatefulWidget {
  const _CalibrationProgressStep({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_CalibrationProgressStep> createState() =>
      _CalibrationProgressStepState();
}

class _CalibrationProgressStepState extends State<_CalibrationProgressStep> {
  Timer? _timer;
  var _progress = 18;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (mounted && _progress < 88) setState(() => _progress += 7);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 1, total: 3, label: 'Product'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Preparing your product',
                  copy: 'Removing the background. The first time can take a little longer.',
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 320),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100Alpha68,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.black,
                          backgroundColor: AppColors.neutral200,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 220,
                        height: 6,
                        child: LinearProgressIndicator(
                          value: _progress / 100,
                          color: AppColors.black,
                          backgroundColor: AppColors.neutral200,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_progress%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalibrationConfirmCutoutStep extends StatelessWidget {
  const _CalibrationConfirmCutoutStep({
    required this.product,
    required this.cutout,
    required this.isUploading,
    required this.onBack,
    required this.onNext,
    required this.onCrop,
    required this.onFix,
  });

  final _Product product;
  final ProductUpload? cutout;
  final bool isUploading;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onCrop;
  final VoidCallback onFix;

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
                  title: 'Is this the right product?',
                  copy: 'Only the product you want to size should remain.',
                ),
                const SizedBox(height: 14),
                _CheckerBox(asset: product.asset, upload: cutout),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neutral200),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'CUTOUT READY\n',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: AppTypography.bold,
                            letterSpacing: .8,
                          ),
                        ),
                        TextSpan(
                          text: 'Check the edges and make sure no other object remains.',
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 12, height: 1.45),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CalibrationActionButton(
                        label: 'Crop image',
                        outlined: true,
                        onPressed: isUploading ? null : onCrop,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CalibrationActionButton(
                        label: 'Fix cutout',
                        outlined: true,
                        onPressed: isUploading ? null : onFix,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: isUploading ? null : onBack,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: AppColors.neutral500,
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('Use different photo'),
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(
          onBack: onBack,
          onPrimary: isUploading ? null : onNext,
          primaryLabel: 'Use this cutout',
        ),
      ],
    );
  }
}

class _CalibrationPlaceStep extends StatelessWidget {
  const _CalibrationPlaceStep({
    required this.product,
    required this.bodyArea,
    required this.cutout,
    required this.bodyZoom,
    required this.placementX,
    required this.placementY,
    required this.placementScale,
    required this.placementRotation,
    required this.onPlacementChanged,
    required this.onRotationChanged,
    required this.onBodyZoomChanged,
    required this.onBack,
    required this.onNext,
  });

  final _Product product;
  final String bodyArea;
  final ProductUpload? cutout;
  final double bodyZoom;
  final double placementX;
  final double placementY;
  final double placementScale;
  final double placementRotation;
  final void Function(double x, double y, double scale) onPlacementChanged;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<double> onBodyZoomChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 2, total: 3, label: 'Size'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionCopy(
                title: 'Make the product look true to size',
                copy: 'Drag the product into place, then resize it until its scale looks natural on the body.',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _ZoomControl(
                  onZoomOut: () => onBodyZoomChanged(bodyZoom - 0.1),
                  onReset: () => onBodyZoomChanged(1),
                  onZoomIn: () => onBodyZoomChanged(bodyZoom + 0.1),
                ),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 2 / 3,
                child: _PlacementCanvas(
                  product: product,
                  bodyArea: bodyArea,
                  cutout: cutout,
                  bodyZoom: bodyZoom,
                  placementX: placementX,
                  placementY: placementY,
                  placementScale: placementScale,
                  placementRotation: placementRotation,
                  onPlacementChanged: onPlacementChanged,
                  onRotationChanged: onRotationChanged,
                ),
              ),
              const SizedBox(height: 10),
              _PlacementFineControls(
                onLeft: () => onPlacementChanged(
                  placementX - 0.01,
                  placementY,
                  placementScale,
                ),
                onRight: () => onPlacementChanged(
                  placementX + 0.01,
                  placementY,
                  placementScale,
                ),
                onSmaller: () => onPlacementChanged(
                  placementX,
                  placementY,
                  placementScale - 0.03,
                ),
                onCenter: () => onPlacementChanged(0.5, 0.56, placementScale),
                onLarger: () => onPlacementChanged(
                  placementX,
                  placementY,
                  placementScale + 0.03,
                ),
                onRotateLeft: () => onRotationChanged(placementRotation - 2),
                onRotateRight: () => onRotationChanged(placementRotation + 2),
              ),
              const SizedBox(height: 10),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'This sets the '),
                    TextSpan(
                      text: 'size',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' of your product compared to the body. Final photo framing is up to the photographer.',
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.neutral500,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        _ProductFlowFooter(onBack: onBack, onPrimary: onNext),
      ],
    );
  }
}

class _CalibrationReviewStep extends StatelessWidget {
  const _CalibrationReviewStep({
    required this.product,
    required this.bodyArea,
    required this.cutout,
    required this.placementX,
    required this.placementY,
    required this.placementScale,
    required this.placementRotation,
    required this.notesController,
    required this.onAdjust,
    required this.onClose,
    required this.onSave,
    required this.onDiscard,
    required this.onRemoveWornPhoto,
    required this.isSaving,
    required this.canDiscard,
    required this.isActive,
    this.wornPhotoUrl,
    this.fitImageUrl,
    this.isLegacy = false,
  });

  final _Product product;
  final String bodyArea;
  final ProductUpload? cutout;
  final double placementX;
  final double placementY;
  final double placementScale;
  final double placementRotation;
  final TextEditingController notesController;
  final VoidCallback onAdjust;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onRemoveWornPhoto;
  final bool isSaving;
  final bool canDiscard;
  final bool isActive;
  final String? wornPhotoUrl;
  final String? fitImageUrl;
  final bool isLegacy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (wornPhotoUrl != null)
          const _StepIndicator(current: 2, total: 2, label: 'Finish')
        else
          const _StepIndicator(current: 3, total: 3, label: 'Finish'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCopy(
                  title: isLegacy || isActive
                      ? 'Size is set'
                      : 'Check and save',
                  copy: isLegacy
                      ? 'This was set up with the older drawing tool. It still works, but the newer Place on body outline flow is faster and more accurate because it uses your actual product photo.'
                      : wornPhotoUrl != null
                      ? 'We’ll use the product-to-body scale from this photo.'
                      : 'We’ll use this Fit only as a size reference. Your shoots still use the model you choose.',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 300,
                  child: fitImageUrl != null
                      ? _AssetImage(fitImageUrl!)
                      : wornPhotoUrl == null
                      ? _PlacementCanvas(
                          product: product,
                          bodyArea: bodyArea,
                          cutout: cutout,
                          placementX: placementX,
                          placementY: placementY,
                          placementScale: placementScale,
                          placementRotation: placementRotation,
                        )
                      : _AssetImage(wornPhotoUrl!),
                ),
                if (!isLegacy) ...[
                  const SizedBox(height: 14),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 13),
                      minTileHeight: 44,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Add instructions ',
                              style: TextStyle(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            TextSpan(
                              text: '(optional)',
                              style: TextStyle(color: AppColors.neutral500),
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 12),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: AppTextField(
                            controller: notesController,
                            hintText: _calibrationNotesHint(product),
                            minLines: 4,
                            maxLines: 5,
                            maxLength: 500,
                            showCounter: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CalibrationActionButton(
                    label: wornPhotoUrl == null
                        ? 'Adjust placement'
                        : 'Replace photo',
                    outlined: true,
                    fullWidth: true,
                    onPressed: onAdjust,
                  ),
                  if (wornPhotoUrl != null) ...[
                    const SizedBox(height: 8),
                    AppOutlinedButton(
                      label: 'Remove worn photo',
                      icon: Icons.delete_outline,
                      onPressed: isSaving ? null : onRemoveWornPhoto,
                      foregroundColor: AppColors.dangerDark,
                      height: 44,
                    ),
                  ],
                  if (canDiscard) ...[
                    const SizedBox(height: 8),
                    AppOutlinedButton(
                      label: 'Discard changes',
                      icon: Icons.restore,
                      onPressed: isSaving ? null : onDiscard,
                      foregroundColor: AppColors.dangerDark,
                      height: 44,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        _ProductFlowFooter(
          onBack: onClose,
          backLabel: isLegacy || isActive ? 'Done' : 'Back',
          primaryLabel: isSaving
              ? 'Saving...'
              : isActive
              ? 'Save notes'
              : 'Save size',
          onPrimary: isSaving ? null : onSave,
          showPrimary: !isLegacy,
        ),
      ],
    );
  }
}

String _calibrationNotesHint(_Product product) {
  if (product.category.toLowerCase() == 'bags') {
    return 'For example, leather exterior, 30 cm wide, 20 cm tall';
  }
  return 'For example, 18 inch chain, sunburst pendant';
}

class _CalibrationSuccessStep extends StatelessWidget {
  const _CalibrationSuccessStep({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF315B44),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.white, size: 25),
          ),
          const SizedBox(height: 15),
          const Text(
            'Size is set',
            style: TextStyle(
              fontFamily: 'InstrumentSerif',
              fontSize: 21,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Future shoots will use this product size.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          _CalibrationActionButton(label: 'Done', onPressed: onDone),
        ],
      ),
    ),
  );
}
