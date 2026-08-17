import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/widgets/app_dotted_border.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

class DashboardGuideContent {
  const DashboardGuideContent({
    required this.title,
    required this.intro,
    required this.icon,
    required this.route,
    required this.cta,
    required this.sections,
    this.tip,
  });

  final String title;
  final String intro;
  final IconData icon;
  final String route;
  final String cta;
  final List<(String, String, String)> sections;
  final String? tip;
}

final dashboardGuideContent = <DashboardWelcomeStepId, DashboardGuideContent>{
  DashboardWelcomeStepId.product: const DashboardGuideContent(
    title: 'Add your product',
    intro:
        'Add one product to start. A few clear photos on a plain background work best.',
    icon: Icons.inventory_2_outlined,
    route: AppRoutes.dashboardProducts,
    cta: 'Go to Products',
    tip:
        'Phone photos are fine. What matters is even light and a plain background.',
    sections: [
      (
        'addProduct-1.png',
        'Products page with the Add Product button highlighted',
        'Open Products and click Add Product.',
      ),
      (
        'addProduct-2.png',
        'The add product form with name and photos',
        'Give it a name and drop in your photos.',
      ),
      (
        'addProduct-3.png',
        'Photo upload with a clean flat lay example',
        'Sharp, well lit photos in, better shots out.',
      ),
    ],
  ),
  DashboardWelcomeStepId.calibration: const DashboardGuideContent(
    title: 'Calibrate sizes',
    intro:
        'Calibration tells us how big your piece is, so it sits right on the model. About a minute. It matters most for jewelry, bags, watches, eyewear and shoes.',
    icon: Icons.straighten,
    route: AppRoutes.dashboardProducts,
    cta: 'Go to Products',
    sections: [
      (
        'calibrate-1.png',
        'A product card with the Calibrate pill highlighted',
        'Open your product and click Calibrate.',
      ),
      (
        'calibrate-2.png',
        'The body area picker',
        'Pick where the piece is worn.',
      ),
      (
        'calibrate-3.png',
        'The size adjust canvas',
        'Drag until the size looks true to life. Save.',
      ),
    ],
  ),
  DashboardWelcomeStepId.angles: const DashboardGuideContent(
    title: 'Label your angles',
    intro:
        'Label each photo with the angle it shows. Front, side, detail. Better labels make truer shots.',
    icon: Icons.center_focus_strong,
    route: AppRoutes.dashboardProducts,
    cta: 'Go to Products',
    sections: [
      (
        'pickAngles-1.png',
        'The photo grid with angle labels visible',
        'Open your product photos.',
      ),
      (
        'pickAngles-2.png',
        'The angle menu open on one photo',
        'Pick the angle each photo shows. Done.',
      ),
    ],
  ),
  DashboardWelcomeStepId.model: const DashboardGuideContent(
    title: 'Create your model',
    intro:
        'Build a model that fits your brand, or pick one from the library. You can reuse them on every product, forever.',
    icon: Icons.person_outline,
    route: AppRoutes.dashboardModels,
    cta: 'Go to Models',
    sections: [
      (
        'createModel-1.png',
        'The Models page with Create Model highlighted',
        'Open Models and click Create.',
      ),
      (
        'createModel-2.png',
        'The model builder with gender, age and description',
        'Describe the model you want. We build them.',
      ),
      (
        'createModel-3.png',
        'A saved model card',
        'Saved models stay in your library for every future shoot.',
      ),
    ],
  ),
  DashboardWelcomeStepId.direction: const DashboardGuideContent(
    title: 'Choose your direction',
    intro:
        'Directors set the mood of a shoot. Same product, same model, very different photos. Pick the one that matches where these photos will live.',
    icon: Icons.movie_filter_outlined,
    route: AppRoutes.dashboardShoots,
    cta: 'Start a shoot',
    sections: [
      (
        'chooseDirection-1.png',
        'The director picker in shoot setup',
        'You pick a director when you set up a shoot.',
      ),
      (
        'chooseDirection-2.png',
        'Two results side by side, clean vs editorial',
        'Clean Pro is the safe pick for your catalog. Try bolder looks for ads.',
      ),
    ],
  ),
  DashboardWelcomeStepId.firstShoot: const DashboardGuideContent(
    title: 'Run your first shoot',
    intro:
        'Pick your product, model and direction. Hit run. First photos land in minutes.',
    icon: Icons.play_arrow_outlined,
    route: AppRoutes.dashboardShoots,
    cta: 'Start a shoot',
    sections: [
      (
        'runShoot-1.png',
        'The shoot setup screen filled in',
        "Product, model, director. That's the whole setup.",
      ),
      (
        'runShoot-2.png',
        'The progress view while generating',
        'Watch it render, or leave the page. It keeps going.',
      ),
      (
        'runShoot-3.png',
        'The results grid with keep buttons',
        'Keep the shots you love. Fix small flaws in Workshop.',
      ),
    ],
  ),
};

Future<void> showDashboardStepGuide(
  BuildContext context,
  WidgetRef ref,
  DashboardWelcomeStepId step,
) async {
  unawaited(
    ref
        .read(analyticsServiceProvider)
        .track('welcome.guide_opened', properties: {'step': step.name}),
  );
  final route = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close guide',
    barrierColor: AppColors.black.withValues(alpha: .7),
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180),
    pageBuilder: (context, _, _) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DashboardStepGuideDialog(step: step),
        ),
      ),
    ),
  );
  if (route != null && context.mounted) unawaited(context.push<void>(route));
}

class DashboardStepGuideDialog extends StatelessWidget {
  const DashboardStepGuideDialog({required this.step, super.key});
  final DashboardWelcomeStepId step;

  @override
  Widget build(BuildContext context) {
    final guide = dashboardGuideContent[step]!;
    final maxHeight = MediaQuery.sizeOf(context).height * .9;
    return Center(
      child: Material(
        color: AppColors.white,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: 512, maxHeight: maxHeight),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200, width: 2),
          ),
          child: Column(
            children: [
              _GuideHeader(guide: guide),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      guide.intro,
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 14,
                      ),
                    ),
                    for (
                      var index = 0;
                      index < guide.sections.length;
                      index++
                    ) ...[
                      const SizedBox(height: 20),
                      _GuideSection(
                        index: index,
                        section: guide.sections[index],
                      ),
                    ],
                    if (guide.tip case final tip?) ...[
                      const SizedBox(height: 20),
                      _GuideTip(tip),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.neutral200)),
                ),
                child: PrimaryButton(
                  label: guide.cta,
                  icon: Icons.arrow_forward,
                  iconAlignment: IconAlignment.end,
                  onPressed: () => Navigator.pop(context, guide.route),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.guide});
  final DashboardGuideContent guide;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.neutral200)),
    ),
    child: Row(
      children: [
        ColoredBox(
          color: AppColors.black,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(guide.icon, size: 18, color: AppColors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            guide.title,
            style: const TextStyle(fontWeight: AppTypography.bold),
          ),
        ),
        IconButton(
          autofocus: true,
          tooltip: 'Close guide',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.neutral500),
        ),
      ],
    ),
  );
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.index, required this.section});
  final int index;
  final (String, String, String) section;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _GuideScreenshot(fileName: section.$1, label: section.$2),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ColoredBox(
            color: AppColors.black,
            child: SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(section.$3)),
        ],
      ),
    ],
  );
}

class _GuideScreenshot extends StatefulWidget {
  const _GuideScreenshot({required this.fileName, required this.label});

  final String fileName;
  final String label;

  @override
  State<_GuideScreenshot> createState() => _GuideScreenshotState();
}

class _GuideScreenshotState extends State<_GuideScreenshot> {
  AssetBundle? _bundle;
  Future<ByteData?>? _bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (_bundle == bundle) return;
    _bundle = bundle;
    _bytes = _load(bundle);
  }

  @override
  void didUpdateWidget(covariant _GuideScreenshot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fileName == oldWidget.fileName) return;
    final bundle = _bundle;
    if (bundle != null) _bytes = _load(bundle);
  }

  Future<ByteData?> _load(AssetBundle bundle) async {
    try {
      return await bundle.load('assets/images/guides/${widget.fileName}');
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 178,
    width: double.infinity,
    child: FutureBuilder<ByteData?>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return _GuideScreenshotPlaceholder(label: widget.label);
        }
        return Image.memory(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          fit: BoxFit.cover,
          cacheWidth: 900,
          semanticLabel: widget.label,
        );
      },
    ),
  );
}

class _GuideScreenshotPlaceholder extends StatelessWidget {
  const _GuideScreenshotPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => AppDottedBorder(
    strokeWidth: 2,
    color: AppColors.neutral200,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 24,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Screenshot coming soon',
              style: TextStyle(color: AppColors.neutral400, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GuideTip extends StatelessWidget {
  const _GuideTip(this.tip);
  final String tip;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    color: AppColors.neutralLight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.diamond_outlined, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tip,
            style: const TextStyle(color: AppColors.neutral500, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
