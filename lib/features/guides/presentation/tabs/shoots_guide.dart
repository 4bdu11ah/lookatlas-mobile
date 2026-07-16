part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootsGuide extends StatelessWidget {
  const _ShootsGuide({required this.onNavigate});

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    return _GuideStack(
      children: [
        const _GuideIntroSection(
          title: 'Mastering Shoots',
          body:
              'Shoots are the production powerhouse of Look Atlas. Create full catalog sets with multiple angles, variations, and video in one workflow.',
        ),
        const _GuideSection(
          title: 'When to Use Shoots',
          children: [_GuideShootsUseCard()],
        ),
        const _GuideSection(
          title: 'Complete Job Workflow',
          children: [
            _GuideWorkflowCard(),
            _GuideStep(
              number: 1,
              title: 'Select Products',
              body:
                  'Choose one or more products from your library. Settings and model remain consistent across the batch.',
              extra: _GuideCallout(
                type: _GuideCalloutType.tip,
                text: 'More product photos generally produce better results.',
              ),
            ),
            _GuideStep(
              number: 2,
              title: 'Select Model',
              body:
                  'Choose an uploaded model, the Look Atlas library, or an AI-generated model.',
            ),
          ],
        ),
        const _GuideSection(
          title: 'Advanced Settings (Deep Dive)',
          children: [
            _GuideContentCard(
              children: [
                _GuideCardTitle('Variations (1-3)'),
                _GuideBodyText(
                  'Generate 1 to 3 versions for every angle. More variations use more credits but give more choices.',
                ),
                _GuideCardTitle('Aspect Ratio Override'),
                _GuideBodyText(
                  'Override the default with 4:5 portrait, 1:1 square, or 16:9 wide.',
                ),
                _GuideCardTitle('Custom Prompt'),
                _GuideBodyText(
                  'Add specific creative direction such as warm golden-hour lighting or a minimalist editorial look.',
                ),
              ],
            ),
          ],
        ),
        const _GuideSection(
          title: 'Video Generation',
          children: [_GuideVideoCard()],
        ),
        const _GuideSection(
          title: 'AI Edits (Post-Generation)',
          children: [
            _GuideContentCard(
              children: [
                _GuideBodyText(
                  'Describe targeted changes to lighting, background, pose, fit, or unwanted elements instead of regenerating the shoot.',
                ),
              ],
            ),
          ],
        ),
        const _GuideSection(
          title: 'Shoot Status & Results',
          children: [_GuideStatusCard()],
        ),
        const _GuideScreenshotPlaceholder(
          label: 'Screenshot: Shoots - Complete workflow from setup to results',
        ),
        _GuideRouteButton(
          label: 'Create Your First Shoot',
          onTap: () => onNavigate(_DashboardPage.create),
        ),
      ],
    );
  }
}

class _GuideShootsUseCard extends StatelessWidget {
  const _GuideShootsUseCard();

  static const _items = [
    'Multiple product angles',
    'Multiple variations per angle',
    'Batch processing for products',
    'Video generation on Pro/Enterprise',
    'Custom backgrounds and settings',
    'Production-ready e-commerce imagery',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.black,
      child: _GuideStack(
        gap: 12,
        children: [
          const Text(
            'Use Shoots When You Need:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: AppTypography.bold,
              color: AppColors.white,
            ),
          ),
          _GuideStack(
            gap: 8,
            children: [
              for (final item in _items)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 16, color: AppColors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.43,
                          color: AppColors.whiteAlpha80,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideWorkflowCard extends StatelessWidget {
  const _GuideWorkflowCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: 2),
      ),
      child: const _GuideStack(
        gap: 24,
        children: [
          _GuideWorkflowHeader(),
          _GuideWorkflowSubsection(
            title: '1. Use Case',
            body:
                'Choose where images will be used to set the optimal aspect ratio.',
            child: _GuideUseCaseTable(),
          ),
          _GuideWorkflowSubsection(
            title: '2. Background',
            body: 'Set the scene for the shoot.',
            child: _GuideBackgroundOptions(),
          ),
          _GuideWorkflowSubsection(
            title: '3. Shots & Angles',
            body:
                'Choose Single Shot or a Catalog Set with Front, 3/4, Side, Back, and Detail.',
          ),
          _GuideWorkflowSubsection(
            title: '4. Posing',
            body:
                'Keep Original, use subtle AI Posing, or describe a Custom pose.',
          ),
          _GuideWorkflowSubsection(
            title: '5. Accessories',
            body: 'Choose None, Minimal, or specify Custom accessories.',
          ),
          _GuideWorkflowSubsection(
            title: '6. Outfit Completion',
            body:
                'Use Product Only, AI Complete, or a Custom complementary outfit.',
          ),
        ],
      ),
    );
  }
}

class _GuideWorkflowHeader extends StatelessWidget {
  const _GuideWorkflowHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GuideNumberBox(number: '0', size: 40),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideCardTitle('Setup Your Shoot'),
              _GuideBodyText('Configure all settings for your photo session'),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideWorkflowSubsection extends StatelessWidget {
  const _GuideWorkflowSubsection({
    required this.title,
    required this.body,
    this.child,
  });

  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.neutral200, width: 2)),
      ),
      child: _GuideStack(
        gap: 12,
        children: [
          _GuideCardTitle(title),
          _GuideBodyText(body),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _GuideUseCaseTable extends StatelessWidget {
  const _GuideUseCaseTable();

  static const _rows = [
    ('Product Pages', '4:5', 'PDPs, Shopify'),
    ('Marketplace', '1:1', 'Amazon, Etsy'),
    ('Social Media', '4:5', 'Instagram, TikTok'),
    ('Hero Banners', '16:9', 'Landing pages, ads'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 600,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(190),
            1: FixedColumnWidth(150),
            2: FlexColumnWidth(),
          },
          children: [
            _row('Use Case', 'Aspect Ratio', 'Best For', header: true),
            for (final row in _rows) _row(row.$1, row.$2, row.$3),
          ],
        ),
      ),
    );
  }

  TableRow _row(
    String first,
    String second,
    String third, {
    bool header = false,
  }) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      children: [
        for (final value in [first, second, third])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: header ? AppTypography.bold : AppTypography.regular,
              ),
            ),
          ),
      ],
    );
  }
}

class _GuideBackgroundOptions extends StatelessWidget {
  const _GuideBackgroundOptions();

  static const _items = [
    'Studio',
    'Lifestyle Street',
    'Lifestyle Home',
    'Keep Original',
    'Custom Upload',
  ];

  @override
  Widget build(BuildContext context) {
    return _GuideStack(
      gap: 12,
      children: [
        for (final item in _items)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neutral100Alpha30,
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GuideCardTitle(item),
                const _GuideBodyText(
                  'Choose this production background treatment for your product.',
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GuideVideoCard extends StatelessWidget {
  const _GuideVideoCard();

  @override
  Widget build(BuildContext context) {
    return const _GuideContentCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideFeatureIcon(icon: Icons.videocam_outlined, size: 48),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GuideCardTitle('8-Second Cinematic Videos'),
                  _GuideBodyText('Available on Pro & Enterprise plans'),
                ],
              ),
            ),
          ],
        ),
        _GuideBodyText(
          'Generate smooth camera movement, natural model motion, and cinematic lighting. Video costs 10 credits; Video HD costs 25.',
        ),
        _GuideCallout(
          type: _GuideCalloutType.tip,
          text:
              'Pick your favorite image variation before requesting video for full control.',
        ),
      ],
    );
  }
}

class _GuideStatusCard extends StatelessWidget {
  const _GuideStatusCard();

  static const _statuses = [
    ('Pending', 'In queue', false),
    ('Processing', 'Generating', false),
    ('Completed', 'Ready to view', true),
    ('Failed', 'Check details', false),
  ];

  @override
  Widget build(BuildContext context) {
    return _GuideContentCard(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 104,
          ),
          itemCount: _statuses.length,
          itemBuilder: (context, index) {
            final status = _statuses[index];
            return Container(
              padding: const EdgeInsets.all(12),
              color: status.$3 ? AppColors.black : AppColors.neutral100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    status.$1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: AppTypography.bold,
                      color: status.$3 ? AppColors.white : AppColors.black,
                    ),
                  ),
                  Text(
                    status.$2,
                    style: TextStyle(
                      fontSize: 12,
                      color: status.$3
                          ? AppColors.whiteAlpha70
                          : AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const _GuideBodyText(
          'View, approve, reject, download, edit, or request video for completed variations.',
        ),
      ],
    );
  }
}
