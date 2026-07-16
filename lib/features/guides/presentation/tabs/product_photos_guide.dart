part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductPhotosGuide extends StatelessWidget {
  const _ProductPhotosGuide({required this.onNavigate});

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    return _GuideStack(
      children: [
        const _GuideIntroSection(
          title: 'Taking Great Product Photos',
          body:
              'High-quality product photos are essential for generating realistic on-model images. The better your source photos, the better your AI-generated results will be.',
        ),
        const _GuideSection(
          title: 'Why Multiple Angles Matter',
          children: [
            _GuideBodyText(
              'Multiple angles help Look Atlas understand 3D shape, texture, and details so the product can be placed accurately from any angle.',
            ),
            _GuideAngleGrid(),
          ],
        ),
        const _GuideSection(
          title: 'Photography Tips',
          children: [
            _GuideCheckRow(
              title: 'Use Good Lighting',
              body:
                  'Natural daylight or well-lit studio lighting captures true colors and textures.',
            ),
            _GuideCheckRow(
              title: 'Clean, Neutral Background',
              body:
                  'Use plain white or light gray so the AI can isolate your product.',
            ),
            _GuideCheckRow(
              title: 'Capture Logos & Details',
              body:
                  'Take close-ups of logos, stitching, and intricate details.',
            ),
            _GuideCheckRow(
              title: 'Show Texture',
              body: 'Capture fabric, leather, or textured surfaces up close.',
            ),
            _GuideCheckRow(
              title: 'Flat Lay for Apparel',
              body:
                  'Flat lay photos show the full garment shape and proportions.',
            ),
          ],
        ),
        const _GuideCallout(
          type: _GuideCalloutType.tip,
          strongPrefix: 'Pro tip: ',
          text:
              'Upload up to 5 photos per product. We recommend at least front, back, and one detail shot.',
        ),
        const _GuideSection(
          title: 'Creating a Product',
          children: [
            _GuideStep(
              number: 1,
              title: 'Go to the Products Tab',
              body: 'Navigate to Products from the sidebar menu.',
            ),
            _GuideStep(
              number: 2,
              title: "Click 'Add Product'",
              body: 'Click the Add Product button in the top right corner.',
            ),
            _GuideStep(
              number: 3,
              title: 'Fill in Product Details',
              body: 'Enter product name, optional SKU, and description.',
            ),
            _GuideStep(
              number: 4,
              title: 'Upload Your Photos',
              body: 'Drag and drop or click to upload up to 5 product photos.',
            ),
            _GuideStep(
              number: 5,
              title: 'Save Your Product',
              body: 'Click Create Product. Your product is ready for shoots.',
            ),
            _GuideScreenshotPlaceholder(
              label: 'Screenshot: Products page - Creating a new product',
            ),
          ],
        ),
        _GuideRouteButton(
          label: 'Go to Products',
          onTap: () => onNavigate(_DashboardPage.products),
        ),
      ],
    );
  }
}

class _GuideAngleGrid extends StatelessWidget {
  const _GuideAngleGrid();

  static const List<(IconData, String, String)> _angles = [
    (Icons.camera_alt_outlined, 'Front', 'Main product view'),
    (Icons.flip_camera_android_outlined, 'Back', 'Rear details'),
    (Icons.view_sidebar_outlined, 'Side', 'Profile view'),
    (Icons.zoom_in_outlined, 'Detail', 'Close-ups'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 148,
      ),
      itemCount: _angles.length,
      itemBuilder: (context, index) {
        final angle = _angles[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.neutral100Alpha68,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(angle.$1, size: 24),
              const SizedBox(height: 8),
              Text(
                angle.$2,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: AppTypography.bold,
                ),
              ),
              Text(
                angle.$3,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
