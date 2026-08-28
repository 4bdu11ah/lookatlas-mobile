part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

enum _CalibrationStep {
  method,
  bodyView,
  pickPhoto,
  removingBackground,
  confirmCutout,
  placeProduct,
  fit,
  review,
  wornPhoto,
  copyFrom,
}

const _outlineBodyAreas = {
  'hand_palm',
  'hand_side',
  'wrist_side',
  'neck_chest',
  'ear_profile',
  'face_front',
  'head_3q',
  'full_body_front',
  'full_body_side',
  'foot_side',
  'waist_front',
};

String? _localOutlineAsset(String bodyArea) =>
    _outlineBodyAreas.contains(bodyArea)
    ? 'assets/images/calibration/outlines/$bodyArea.png'
    : null;

class _ProductCalibrationLoadingShimmer extends StatelessWidget {
  const _ProductCalibrationLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FractionallySizedBox(
            widthFactor: 0.6,
            child: SizedBox(height: 18, child: ShimmerBox()),
          ),
          SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: 0.9,
            child: SizedBox(height: 13, child: ShimmerBox()),
          ),
          SizedBox(height: 28),
          Expanded(child: ShimmerBox()),
          SizedBox(height: 20),
          SizedBox(height: 44, child: ShimmerBox()),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.label});

  final String current;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: current,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: AppTypography.bold,
              ),
            ),
            TextSpan(text: ' of $label'),
          ],
        ),
        style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
      ),
    );
  }
}

class _CalibrationMethodStep extends StatelessWidget {
  const _CalibrationMethodStep({
    required this.onBody,
    required this.onWorn,
    required this.onCopy,
  });

  final VoidCallback onBody;
  final VoidCallback onWorn;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'How should we learn the real-world size?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Any of these work. Pick whichever is easiest for this product.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.38,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 14),
                _MethodCard(
                  icon: Icons.open_with,
                  title: 'Place the product on a body outline',
                  subtitle:
                      'Remove the background, then drag the product onto a body outline.',
                  recommended: true,
                  onTap: onBody,
                ),
                _MethodCard(
                  icon: Icons.photo_camera_outlined,
                  title: 'Upload a photo of it being worn',
                  subtitle: 'Fastest if you already have a rough phone photo.',
                  onTap: onWorn,
                ),
                _MethodCard(
                  icon: Icons.copy_outlined,
                  title: 'Copy from another calibrated product',
                  subtitle: 'Reuse a setup from a similar product.',
                  onTap: onCopy,
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(
          onBack: () => Navigator.pop(context),
          backLabel: 'Cancel',
          showPrimary: false,
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.recommended = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Icon(icon, size: 16),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (recommended) const _ProductPill.dark('Recommended'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalibrationBodyStep extends StatelessWidget {
  const _CalibrationBodyStep({
    required this.outlines,
    required this.selectedBodyArea,
    required this.onSelected,
    required this.onBack,
    required this.onNext,
  });

  final List<CalibrationOutline> outlines;
  final String selectedBodyArea;
  final ValueChanged<String> onSelected;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final views = outlines.isEmpty
        ? const [
            CalibrationOutline(
              id: 'full_body_front',
              name: 'Full Body Front',
            ),
            CalibrationOutline(id: 'hand_side', name: 'Hand Side'),
            CalibrationOutline(
              id: 'full_body_side',
              name: 'Full Body Side',
            ),
            CalibrationOutline(id: 'waist_front', name: 'Waist Front'),
          ]
        : outlines;
    final orderedViews = [
      for (final view in views)
        if (view.id == 'full_body_front') view,
      for (final view in views)
        if (view.id != 'full_body_front') view,
    ];
    return Column(
      children: [
        const _StepIndicator(current: 'Step 1', label: '3: View'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Pick a body view',
                  copy:
                      'We have pre-selected the view that usually fits this category. Tap any other one to change it.',
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  itemCount: orderedViews.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.58,
                  ),
                  itemBuilder: (context, index) {
                    final view = orderedViews[index];
                    return _BodyTile(
                      view.name,
                      'Tap to use this body view',
                      active: selectedBodyArea == view.id,
                      imageUrl: _localOutlineAsset(view.id),
                      onTap: () => onSelected(view.id),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'None of these fit your product? Pick the closest view, or go back and upload a real worn photo instead.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.neutral500,
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

class _BodyTile extends StatelessWidget {
  const _BodyTile(
    this.title,
    this.subtitle, {
    required this.active,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: active ? AppColors.neutral100 : AppColors.white,
          border: Border.all(
            color: active ? AppColors.black : AppColors.neutral200,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            if (active)
              const Align(
                alignment: Alignment.centerLeft,
                child: _ProductPill.dark('Selected'),
              ),
            Expanded(
              child: imageUrl == null
                  ? CustomPaint(painter: _BodyOutlinePainter())
                  : AppImage(imageUrl!),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
