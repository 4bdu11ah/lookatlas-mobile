part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _GettingStartedGuide extends StatelessWidget {
  const _GettingStartedGuide({required this.onNavigate});

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    return _GuideStack(
      children: [
        const _GuideIntroSection(
          title: 'Welcome to Look Atlas',
          body:
              'Look Atlas transforms your product photos into stunning on-model imagery using AI. No expensive photo shoots, no scheduling models, no studio rentals, just upload your products and watch the magic happen.',
          largeBody: true,
        ),
        const _GuideSection(
          title: 'What You Can Do',
          children: [
            _GuideFeatureCard(
              icon: Icons.image_outlined,
              title: 'Generate On-Model Photos',
              body:
                  'Place your products on professional models with realistic lighting, poses, and backgrounds.',
            ),
            _GuideFeatureCard(
              icon: Icons.videocam_outlined,
              title: 'Create Product Videos',
              body:
                  'Transform your images into 8-second cinematic video clips perfect for social media and ads.',
            ),
            _GuideFeatureCard(
              icon: Icons.auto_fix_high_outlined,
              title: 'AI-Powered Edits',
              body:
                  'Refine generated images with natural language, just describe what you want to change.',
            ),
          ],
        ),
        const _GuideSection(
          title: 'Quick Start in 5 Steps',
          children: [
            _GuideStep(
              number: 1,
              title: 'Upload Your Product',
              body:
                  'Go to Products and add your first product. Upload 1-5 photos showing front, back, side, and detail shots.',
              extra: _GuideCallout(
                type: _GuideCalloutType.tip,
                strongPrefix: 'Best results: ',
                text: 'Use clean, well-lit photos on a neutral background.',
              ),
            ),
            _GuideStep(
              number: 2,
              title: 'Choose a Model',
              body:
                  'Go to House Models and choose the Look Atlas Library, upload your own model, or create one with AI for 20 credits.',
            ),
            _GuideStep(
              number: 3,
              title: 'Create Your First Shoot',
              body:
                  'Head to Shoots, pick a director, generate shot ideas, choose your model, and submit.',
              extra: _GuideCallout(
                type: _GuideCalloutType.info,
                text:
                    'Shoots create full catalog sets with multiple angles and variations, plus video generation.',
              ),
            ),
            _GuideStep(
              number: 4,
              title: 'Review & Download',
              body:
                  'Review the generated image, download it, or use AI Edits to describe refinements.',
            ),
            _GuideStep(
              number: 5,
              title: 'Add Variations or Resize',
              body:
                  'Use Add Variation for alternates, or select Standard / HD / 4K when creating the next shoot.',
            ),
          ],
        ),
        const _GuideCreditsSection(),
        _GuideSection(
          title: 'Jump Right In',
          children: [
            _GuideQuickActionCard(
              icon: Icons.inventory_2_outlined,
              title: 'Products',
              body: 'Upload and manage your product photos',
              buttonLabel: 'Add Products',
              onTap: () => onNavigate(_DashboardPage.products),
            ),
            _GuideQuickActionCard(
              icon: Icons.groups_outlined,
              title: 'Models',
              body: 'Browse or create your house models',
              buttonLabel: 'View Models',
              onTap: () => onNavigate(_DashboardPage.models),
            ),
            _GuideQuickActionCard(
              icon: Icons.play_arrow_outlined,
              title: 'Shoots',
              body: 'Full production photo shoots',
              buttonLabel: 'Create Shoot',
              onTap: () => onNavigate(_DashboardPage.create),
            ),
          ],
        ),
        _GuideReadyCallout(
          onSupport: () => onNavigate(_DashboardPage.support),
        ),
      ],
    );
  }
}

class _GuideCreditsSection extends StatelessWidget {
  const _GuideCreditsSection();

  @override
  Widget build(BuildContext context) {
    return const _GuideSection(
      title: 'Understanding Credits',
      children: [
        _GuideContentCard(
          children: [
            _GuideBodyText(
              'Credits are the currency of Look Atlas. Different actions cost different amounts:',
            ),
            _GuideCreditItem(
              number: '1',
              title: 'Image Generation',
              body: 'Per image variation',
            ),
            _GuideCreditItem(
              number: '20',
              title: 'AI Model Creation',
              body: 'Per custom model',
            ),
            _GuideCreditItem(
              number: '10',
              title: 'Video Generation',
              body: '10 Video or 25 Video HD',
            ),
            _GuideCreditItem(
              number: '0',
              title: 'Look Atlas Models',
              body: 'Free to use',
              inverted: true,
            ),
            _GuideBodyText(
              'Check remaining credits anytime on the Dashboard or in Billing.',
            ),
          ],
        ),
      ],
    );
  }
}

class _GuideCreditItem extends StatelessWidget {
  const _GuideCreditItem({
    required this.number,
    required this.title,
    required this.body,
    this.inverted = false,
  });

  final String number;
  final String title;
  final String body;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final foreground = inverted ? AppColors.white : AppColors.black;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inverted ? AppColors.black : AppColors.neutral100Alpha68,
        border: Border.all(
          color: inverted ? AppColors.black : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            color: inverted ? AppColors.white : AppColors.black,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: AppTypography.bold,
                color: inverted ? AppColors.black : AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: AppTypography.bold,
                    color: foreground,
                  ),
                ),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: inverted
                        ? AppColors.whiteAlpha70
                        : AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideQuickActionCard extends StatelessWidget {
  const _GuideQuickActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GuideBorderedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideFeatureIcon(icon: icon, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GuideCardTitle(title),
                    _GuideBodyText(body),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GuideRouteButton(label: buttonLabel, onTap: onTap, outlined: true),
        ],
      ),
    );
  }
}

class _GuideReadyCallout extends StatelessWidget {
  const _GuideReadyCallout({required this.onSupport});

  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.black,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 20, color: AppColors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  "You're all set! Explore the other tabs for detailed walkthroughs. Visit ",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.white,
                  ),
                ),
                GestureDetector(
                  onTap: onSupport,
                  child: const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.white,
                      fontWeight: AppTypography.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.white,
                    ),
                  ),
                ),
                const Text(
                  ' if you have questions.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
