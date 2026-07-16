part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ModelsGuide extends StatelessWidget {
  const _ModelsGuide({required this.onNavigate});

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    return _GuideStack(
      children: [
        const _GuideIntroSection(
          title: 'Choosing Your Models',
          body:
              'Models are the foundation of your on-model product photography. Look Atlas gives you three flexible options.',
        ),
        const _GuideNumberedSection(
          number: 1,
          title: 'Upload Your Own Models',
          child: _GuideContentCard(
            children: [
              _GuideBodyText(
                'Upload real models you have worked with to maintain brand consistency.',
              ),
              _GuideCardTitle('What you need:'),
              _GuideBulletList(
                items: [
                  '4 photos: Front, Left, Right, and Back',
                  'Full-body shots with a clean background',
                  'Consistent lighting across all angles',
                ],
              ),
              _GuideCallout(
                type: _GuideCalloutType.warning,
                strongPrefix: 'Permission Required: ',
                text: 'Ensure you have legal rights to use these images.',
              ),
            ],
          ),
        ),
        const _GuideNumberedSection(
          number: 2,
          title: 'Look Atlas Model Library',
          child: _GuideContentCard(
            children: [
              _GuideBodyText(
                'Choose from a curated collection of diverse professional AI models, ready instantly at no extra cost.',
              ),
              _GuideModelGrid(),
              _GuideCallout(
                type: _GuideCalloutType.info,
                strongPrefix: 'Free to use: ',
                text: 'Library models are included with your plan.',
              ),
            ],
          ),
        ),
        const _GuideNumberedSection(
          number: 3,
          title: 'Create with AI',
          child: _GuideContentCard(
            children: [
              _GuideBodyText(
                'Generate a unique AI model tailored to gender, ethnicity, body type, age range, and more.',
              ),
              _GuideAiModelCredit(),
              _GuideBodyText(
                'Generated models include Front, Left, Right, and Back angles and are owned by you for campaign use.',
              ),
            ],
          ),
        ),
        const _GuideScreenshotPlaceholder(
          label:
              'Screenshot: House Models page - Your models and Look Atlas library',
        ),
        _GuideRouteButton(
          label: 'Go to Models',
          onTap: () => onNavigate(_DashboardPage.models),
        ),
      ],
    );
  }
}

class _GuideNumberedSection extends StatelessWidget {
  const _GuideNumberedSection({
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _GuideStack(
      gap: 16,
      children: [
        Row(
          children: [
            _GuideNumberBox(number: '$number', size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }
}

class _GuideModelGrid extends StatelessWidget {
  const _GuideModelGrid();

  static const List<(IconData, String)> _models = [
    (Icons.woman_outlined, '12 Female'),
    (Icons.man_outlined, '8 Male'),
    (Icons.person_outline, '4 Non-Binary'),
    (Icons.public, 'Diverse'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 100,
      ),
      itemCount: _models.length,
      itemBuilder: (context, index) {
        final model = _models[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neutral100Alpha68,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(model.$1, size: 24),
              const SizedBox(height: 4),
              Text(
                model.$2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuideAiModelCredit extends StatelessWidget {
  const _GuideAiModelCredit();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha68,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt_outlined, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Cost: ',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: AppTypography.bold,
                ),
                children: [
                  TextSpan(
                    text: '20 credits per AI model generation',
                    style: TextStyle(
                      color: AppColors.neutral500,
                      fontWeight: AppTypography.regular,
                    ),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
