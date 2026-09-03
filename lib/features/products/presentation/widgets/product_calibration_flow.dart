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
  success,
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
  Size get preferredSize => const Size.fromHeight(69);

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Container(
      height: 69,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'InstrumentSerif',
                    fontSize: 18,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 12,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.arrow_back, size: 20),
            label: const Text('Exit'),
            style: TextButton.styleFrom(
              minimumSize: const Size(68, 44),
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.black,
              textStyle: const TextStyle(fontSize: 13),
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
  const _StepIndicator({
    required this.current,
    required this.total,
    required this.label,
  });

  final int current;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Step $current',
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                TextSpan(text: ' of $total · $label'),
              ],
            ),
            style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              for (var index = 1; index <= total; index++) ...[
                Expanded(
                  child: Container(
                    height: 3,
                    color: index <= current
                        ? AppColors.black
                        : AppColors.neutral200,
                  ),
                ),
                if (index != total) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Choose the easiest way to set the size',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'InstrumentSerif',
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'This helps the product look naturally proportioned on every model.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MethodCard(
                    icon: Icons.open_with,
                    title: 'Use a product photo',
                    subtitle: 'Pick a clear photo. We remove the background, then you resize the product on a simple body guide.',
                    recommended: true,
                    onTap: onBody,
                  ),
                  const SizedBox(height: 8),
                  _MethodCard(
                    icon: Icons.photo_camera_outlined,
                    title: 'Use a worn photo',
                    subtitle: 'Choose a photo where the product is worn or carried. No editing needed.',
                    onTap: onWorn,
                  ),
                  const SizedBox(height: 8),
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
        ),
      ),
    );
  }
}

class _CalibrationOverviewStep extends StatelessWidget {
  const _CalibrationOverviewStep({
    required this.product,
    required this.onBack,
    required this.onNext,
  });

  final _Product product;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _StepIndicator(current: 1, total: 3, label: 'Product'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionCopy(
                title: 'Set size from a product photo',
                copy: 'Three quick steps turn one clear product photo into a reliable size reference.',
              ),
              const SizedBox(height: 16),
              _CalibrationOverviewCard(
                number: '1',
                title: 'Choose a photo',
                imageUrl: product.asset,
                copy: 'Pick a clear product view from the library or upload another.',
              ),
              _CalibrationOverviewCard(
                number: '2',
                title: 'Clean the product',
                imageUrl: product.asset,
                copy: 'We remove the background. Crop or fix the cutout if needed.',
              ),
              const _CalibrationOverviewCard(
                number: '3',
                title: 'Place at true size',
                imageUrl:
                    'assets/images/calibration/outlines/full_body_front.png',
                copy: 'Drag and resize the product against the suggested body guide.',
              ),
            ],
          ),
        ),
      ),
      _ProductFlowFooter(
        onBack: onBack,
        onPrimary: onNext,
      ),
    ],
  );
}

class _CalibrationOverviewCard extends StatelessWidget {
  const _CalibrationOverviewCard({
    required this.number,
    required this.title,
    required this.imageUrl,
    required this.copy,
  });

  final String number;
  final String title;
  final String imageUrl;
  final String copy;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.neutral200)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 150,
          padding: const EdgeInsets.all(14),
          color: const Color(0xFFF8F7F3),
          alignment: Alignment.center,
          child: AppImage(imageUrl),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            copy,
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
              height: 1.45,
            ),
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
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('calibration-method-$title'),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        if (recommended) const _CalibrationRecommendedBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalibrationRecommendedBadge extends StatelessWidget {
  const _CalibrationRecommendedBadge({this.label = 'Recommended'});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    color: AppColors.black,
    alignment: Alignment.center,
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 10,
        height: 1.1,
        fontWeight: AppTypography.bold,
        letterSpacing: .8,
      ),
    ),
  );
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
        const _StepIndicator(current: 1, total: 3, label: 'Product'),
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
                      _bodyViewLabel(view.id),
                      _bodyAreaDescription(view.id),
                      recommended: index < 2,
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
    this.recommended = false,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final String? imageUrl;
  final bool recommended;

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
            if (recommended)
              const Align(
                alignment: Alignment.centerLeft,
                child: _CalibrationRecommendedBadge(),
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

String _bodyAreaDescription(String bodyArea) => switch (bodyArea) {
  'full_body_front' => 'Clothing, bags, dresses',
  'full_body_side' => 'Crossbody, shoulder bags',
  'waist_front' => 'Belts, waist bags',
  'hand_side' || 'hand_palm' => 'Rings, bracelets, gloves',
  'wrist_side' => 'Watches and bracelets',
  'neck_chest' => 'Necklaces and pendants',
  'face_front' || 'head_3q' => 'Eyewear and earrings',
  'ear_profile' => 'Earrings',
  'foot_side' => 'Shoes',
  _ => 'Choose this body view',
};
