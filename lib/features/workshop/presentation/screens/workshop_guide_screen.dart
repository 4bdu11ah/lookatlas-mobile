part of 'workshop_screen.dart';

class WorkshopGuideScreen extends StatelessWidget {
  const WorkshopGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Workshop Guide',
        showBackButton: true,
      ),
      body: _WorkshopGuideContent(
        onClose: () => context.go(AppRoutes.workshop),
      ),
    );
  }
}

class _WorkshopGuideContent extends StatelessWidget {
  const _WorkshopGuideContent({required this.onClose});

  final VoidCallback onClose;

  static const List<_GuideExampleData> _examples = [
    _GuideExampleData(
      title: 'Change the background',
      caption: 'Same model. Drop them into any scene.',
      before: AppAssets.showcaseDressBefore,
      after: AppAssets.showcaseDressAfter,
      prompt:
          'Re-render this photo as if she was actually photographed at a sunlit Paris cafe terrace at golden hour. Keep her face, outfit, hair, and pose exactly the same. Re-light her body and hair to match the warm directional sunlight, add a soft natural shadow on the ground behind her, and let the background fall into soft bokeh. Shot on a 50mm lens with shallow depth of field.',
    ),
    _GuideExampleData(
      title: 'Restyle a product',
      caption: 'Recolor a product without losing its shape.',
      before: AppAssets.showcaseShoesBefore,
      after: AppAssets.showcaseShoesAfter,
      prompt:
          'Recolor the sneaker to deep navy blue suede. Keep the silhouette, laces, sole, stitching, and shadow exactly as they are.',
    ),
    _GuideExampleData(
      title: 'Swap the model, keep the product',
      caption: 'Same product. Different person.',
      before: AppAssets.stepModel,
      after: AppAssets.stepGenerate,
      prompt:
          'Replace the model with the person from Image 2. Keep the watch on the wrist, the pose, the hand position, the framing, and the lighting identical to the original.',
      note: 'Upload the new model as the second image.',
    ),
    _GuideExampleData(
      title: 'Swap the product, keep the model',
      caption: 'Same model. Different product.',
      before: AppAssets.showcaseBagBefore,
      after: AppAssets.showcaseBagAfter,
      prompt:
          "Replace the coffee cup in the model's hand with the wine glass from Image 2. Keep the model, hand position, pose, framing, lighting, and background identical.",
      note: 'Upload the new product as the second image.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(context).bottom + 28,
        ),
        children: [
          const _GuideHero(),
          const SizedBox(height: 24),
          const _GuideModeCard(
            icon: Icons.lock_outline,
            title: 'Lock this image',
            body:
                'Keeps your photo exactly as it is. Only the part you describe changes. Best for face swaps, color changes, or replacing one thing in the shot.',
          ),
          const SizedBox(height: 12),
          const _GuideModeCard(
            icon: Icons.lightbulb_outline,
            title: 'Use as inspiration',
            body:
                "Makes a brand new image inspired by your photo. The output won't match the original. Best for fresh shots in the same style.",
          ),
          const SizedBox(height: 24),
          const _GuideSectionHead(),
          const SizedBox(height: 16),
          for (final example in _examples) ...[
            _GuideExample(example: example),
            const SizedBox(height: 16),
          ],
          const _GuideTips(),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              label: 'Got it',
              onPressed: onClose,
              fitToContent: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideExampleData {
  const _GuideExampleData({
    required this.title,
    required this.caption,
    required this.before,
    required this.after,
    required this.prompt,
    this.note,
  });

  final String title;
  final String caption;
  final String before;
  final String after;
  final String prompt;
  final String? note;
}

class _GuideHero extends StatelessWidget {
  const _GuideHero();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideBadge(),
          SizedBox(height: 8),
          Text(
            'One image, one prompt, one credit.',
            maxLines: 2,
            style: TextStyle(
              fontSize: 20,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Drop a photo, type the change you want, get the result back. Works for faces, products, or whole scenes.',
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBadge extends StatelessWidget {
  const _GuideBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 13,
            color: AppColors.neutral500,
          ),
          SizedBox(width: 6),
          Text(
            'How Workshop works',
            style: TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: AppTypography.bold,
              letterSpacing: 1.21,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideModeCard extends StatelessWidget {
  const _GuideModeCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _GuidePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.black),
              const SizedBox(width: 8),
              Expanded(
                child: _GuideFitText(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSectionHead extends StatelessWidget {
  const _GuideSectionHead();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Examples',
          style: TextStyle(
            fontSize: 18,
            height: 1.35,
            fontWeight: AppTypography.bold,
            letterSpacing: 0.72,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Four real prompts. Copy any of them straight into the editor.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _GuideExample extends StatelessWidget {
  const _GuideExample({required this.example});

  final _GuideExampleData example;

  @override
  Widget build(BuildContext context) {
    return _GuidePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  example.title,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _ModePill(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            example.caption,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GuideImage(label: 'Before', asset: example.before),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: AppColors.neutral500,
                ),
              ),
              Expanded(
                child: _GuideImage(label: 'After', asset: example.after),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GuidePromptBlock(example: example),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 11, color: AppColors.neutral500),
          SizedBox(width: 4),
          Text(
            'Lock this image',
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: AppTypography.bold,
              letterSpacing: 1,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideImage extends StatelessWidget {
  const _GuideImage({required this.label, required this.asset});

  final String label;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            height: 1,
            fontWeight: AppTypography.bold,
            letterSpacing: 1.1,
            color: AppColors.neutral500,
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              border: Border.all(color: AppColors.neutral200),
            ),
            clipBehavior: Clip.hardEdge,
            child: AppImage(asset, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}

class _GuidePromptBlock extends StatelessWidget {
  const _GuidePromptBlock({required this.example});

  final _GuideExampleData example;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha30,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you type',
            style: TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: AppTypography.bold,
              letterSpacing: 1.1,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            example.prompt,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.black,
            ),
          ),
          if (example.note != null) ...[
            const SizedBox(height: 6),
            Text(
              example.note!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideTips extends StatelessWidget {
  const _GuideTips();

  static const List<String> _tips = [
    'Tell it what to keep, not just what to change. Keep the lighting and pose really helps.',
    'You can add up to 4 reference images to pull in a face, color, or texture from somewhere else.',
    'Each generation costs 1 credit. If it fails, you get the credit back automatically.',
    'Generations run on our servers. Switch tabs or close the page. It will be ready when you come back.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tips',
            style: TextStyle(
              fontSize: 18,
              height: 1.35,
              fontWeight: AppTypography.bold,
              letterSpacing: 0.72,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          for (final tip in _tips) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•',
                  style: TextStyle(fontSize: 14, color: AppColors.neutral500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _GuidePanel extends StatelessWidget {
  const _GuidePanel({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: child,
    );
  }
}

class _GuideFitText extends StatelessWidget {
  const _GuideFitText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
