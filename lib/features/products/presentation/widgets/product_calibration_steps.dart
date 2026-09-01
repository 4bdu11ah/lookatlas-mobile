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
    return Column(
      children: [
        const _StepIndicator(current: 'Step 2', label: '3: Place'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Pick a product photo',
                  copy: 'We will remove its background, then you place the cutout on the body outline.',
                ),
                const SizedBox(height: 20),
                const _Kicker('Size guide'),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 96,
                      height: 144,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: AppImage(
                        _localOutlineAsset(bodyArea) ?? product.asset,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bodyViewLabel(bodyArea),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Choose a photo from roughly this angle.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.38,
                              color: AppColors.neutral500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppOutlinedButton(
                            label: 'Change',
                            icon: Icons.edit_outlined,
                            onPressed: onChangeBody,
                            fitToContent: true,
                            height: 44,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _Kicker('Your product photos'),
                const SizedBox(height: 10),
                GridView.builder(
                  itemCount: product.photoAssets.length + 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) =>
                      index == product.photoAssets.length
                      ? _UploadTile(onTap: onNext)
                      : _PhotoTile(
                          key: ValueKey('calibration-photo-$index'),
                          asset: product.photoAssets[index],
                          onTap: () =>
                              onPhotoSelected(product.photoAssets[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(onBack: onBack, onPrimary: onNext),
      ],
    );
  }
}

String _bodyViewLabel(String bodyArea) => switch (bodyArea) {
  'full_body_front' => 'Full body (front)',
  'full_body_side' => 'Full body (side)',
  _ => bodyArea.replaceAll('_', ' '),
};

class _CalibrationProgressStep extends StatelessWidget {
  const _CalibrationProgressStep({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 2', label: '3: Place'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Removing background',
                  copy: 'One-time model download on first use, then it is near-instant.',
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100Alpha68,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: const Column(
                    children: [
                      BarSpinner(size: 28, color: AppColors.black),
                      SizedBox(height: 12),
                      Text(
                        'Uploading cutout',
                        style: TextStyle(
                          fontSize: 12,
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
        _ProductFlowFooter(onBack: onBack, showPrimary: false),
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
  });

  final _Product product;
  final ProductUpload? cutout;
  final bool isUploading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 2', label: '3: Place'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Does this look right?',
                  copy: 'Edges do not need to be perfect. This is used as a size reference only.',
                ),
                const SizedBox(height: 14),
                _CheckerBox(asset: product.asset, upload: cutout),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PrimaryButton(
                      label: 'Looks good',
                      icon: Icons.check,
                      onPressed: onNext,
                      isLoading: isUploading,
                      fitToContent: true,
                      height: 34,
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      iconSize: 16,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    AppOutlinedButton(
                      label: 'Use a different photo',
                      icon: Icons.refresh,
                      onPressed: isUploading ? null : onBack,
                      fitToContent: true,
                      height: 34,
                      iconSize: 16,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: AppTypography.bold,
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
        const _StepIndicator(current: 'Step 2', label: '3: Place'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Set the size on the body',
                  copy: 'Drag the product to reposition it. Use its corner handle to resize, and the zoom controls to inspect the body.',
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
                Expanded(
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
                  ),
                ),
                const SizedBox(height: 10),
                _PlacementFineControls(
                  onLeft: () => onPlacementChanged(
                    placementX - 0.01,
                    placementY,
                    placementScale,
                  ),
                  onUp: () => onPlacementChanged(
                    placementX,
                    placementY - 0.01,
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
                AppOutlinedButton(
                  label: 'Use a different photo',
                  icon: Icons.arrow_back,
                  onPressed: onBack,
                  fitToContent: true,
                  height: 34,
                  borderColor: AppColors.transparent,
                  backgroundColor: AppColors.transparent,
                  iconSize: 16,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
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
  final String? wornPhotoUrl;
  final String? fitImageUrl;
  final bool isLegacy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 3', label: '3: Review'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCopy(
                  title: isLegacy
                      ? 'Your saved calibration'
                      : 'Review and save',
                  copy: isLegacy
                      ? 'This was set up with the older drawing tool. It still works, but the newer Place on body outline flow is faster and more accurate because it uses your actual product photo.'
                      : wornPhotoUrl != null
                      ? 'The AI will match the size-to-body ratio from your photo. Framing and composition are up to the photographer.'
                      : 'The AI will use this size-on-body setup as the scale reference. Framing and composition are up to the photographer.',
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

                  AppTextField(
                    controller: notesController,
                    labelText: 'Notes for the AI (optional)',
                    hintText: 'Anything that helps the AI get size right. Material, dimensions, context.',
                    minLines: 3,
                    maxLines: 4,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 14),
                  AppOutlinedButton(
                    label: wornPhotoUrl == null
                        ? 'Adjust placement'
                        : 'Replace photo',
                    onPressed: onAdjust,
                    fitToContent: true,
                    height: 34,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: AppTypography.bold,
                    ),
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
          primaryLabel: isSaving ? 'Saving...' : 'Save calibration',
          onPrimary: isSaving ? null : onSave,
          showPrimary: !isLegacy,
        ),
      ],
    );
  }
}
