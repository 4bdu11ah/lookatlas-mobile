part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

enum _CalibrationStep {
  method,
  overview,
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

class _CalibrationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const _CalibrationHeader({required this.productName, required this.onExit});

  final String productName;
  final VoidCallback? onExit;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(20, 8, 10, 8),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set product size',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Exit'),
            style: TextButton.styleFrom(
              minimumSize: const Size(72, 44),
              foregroundColor: AppColors.black,
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ],
      ),
    ),
  );
}

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
                  'Choose the easiest way to set the size',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'This helps the product look naturally proportioned on every model.',
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
                  title: 'Use a product photo',
                  subtitle: 'Pick a clear photo. We remove the background, then you resize the product on a simple body guide.',
                  recommended: true,
                  onTap: onBody,
                ),
                _MethodCard(
                  icon: Icons.photo_camera_outlined,
                  title: 'Use a worn photo',
                  subtitle: 'Choose a photo where the product is worn or carried. No editing needed.',
                  onTap: onWorn,
                ),
                _MethodCard(
                  icon: Icons.copy_outlined,
                  title: 'Reuse a saved size',
                  subtitle: 'Copy the size from a similar product you already set up.',
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

class _CalibrationOverviewStep extends StatelessWidget {
  const _CalibrationOverviewStep({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _StepIndicator(current: 'Step 1', label: '3 · Product'),
      const Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _SectionCopy(
                title: 'Set the size in 3 easy steps',
                copy: 'Upload a photo, clean it up, then drag it to the right size.',
              ),
              SizedBox(height: 18),
              _CalibrationOverviewCard(
                number: '1',
                icon: Icons.upload_outlined,
                title: 'Upload one product photo',
                copy: 'Choose one clear photo that shows the whole product.',
              ),
              _CalibrationOverviewCard(
                number: '2',
                icon: Icons.auto_fix_high_outlined,
                title: 'Remove the background',
                copy:
                    'We remove the background. Crop or erase anything we miss.',
              ),
              _CalibrationOverviewCard(
                number: '3',
                icon: Icons.open_with,
                title: 'Place and resize',
                copy: 'Drag the product onto the body. Pull a corner until the size looks right.',
              ),
            ],
          ),
        ),
      ),
      _ProductFlowFooter(
        onBack: onBack,
        onPrimary: onNext,
        primaryLabel: 'Choose a product photo',
      ),
    ],
  );
}

class _CalibrationOverviewCard extends StatelessWidget {
  const _CalibrationOverviewCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.copy,
  });

  final String number;
  final IconData icon;
  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          color: AppColors.black,
          child: Text(
            number,
            style: const TextStyle(color: AppColors.white, fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                copy,
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
                  title: 'Choose a different size guide',
                  copy: 'We picked the best match for this product. Change it only if another view makes the size easier to judge.',
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
