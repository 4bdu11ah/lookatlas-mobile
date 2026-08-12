part of 'director_portfolio_modal.dart';

class _PortfolioGrid extends StatelessWidget {
  const _PortfolioGrid({required this.director, required this.captions});

  final Director director;
  final List<String> captions;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Portfolio',
      icon: Icons.photo_camera_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < director.portfolioUrls.length; i++)
                SizedBox(
                  width: tileWidth,
                  child: _PortfolioTile(
                    key: ValueKey('portfolio-image-$i'),
                    url: director.portfolioUrls[i],
                    caption: captions[i],
                    onTap: () => unawaited(
                      _showImageViewer(
                        context,
                        urls: director.portfolioUrls,
                        captions: captions,
                        initialIndex: i,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({
    required this.url,
    required this.caption,
    required this.onTap,
    super.key,
  });

  final String url;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral100,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShotImage(url),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 82),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [AppColors.blackAlpha86, AppColors.transparent],
                    ),
                  ),
                  child: Text(
                    caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: AppColors.whiteAlpha90,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorySection extends StatelessWidget {
  const _StorySection({required this.content});

  final _DirectorPortfolioContent content;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'The Story',
      icon: Icons.workspace_premium_outlined,
      soft: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          for (final paragraph in content.story)
            Text(
              paragraph,
              style: const TextStyle(
                fontSize: 14,
                height: 1.65,
                color: AppColors.neutral500,
              ),
            ),
        ],
      ),
    );
  }
}

class _QuoteSection extends StatelessWidget {
  const _QuoteSection({required this.director, required this.quote});

  final Director director;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '"',
            style: TextStyle(
              fontSize: 42,
              height: 0.85,
              fontWeight: FontWeight.w900,
              color: AppColors.inkAlpha18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.55,
                    fontStyle: FontStyle.italic,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '- ${director.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.neutral500,
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

class _ChipSection extends StatelessWidget {
  const _ChipSection({required this.content});

  final _DirectorPortfolioContent content;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 22,
        children: [
          _ChipGroup(
            title: 'Style Characteristics',
            labels: content.styleCharacteristics,
          ),
          _ChipGroup(
            title: 'Best For',
            labels: content.bestFor,
            dark: true,
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.title,
    required this.labels,
    this.dark = false,
  });

  final String title;
  final List<String> labels;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.96,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in labels)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: dark ? AppColors.inkAlpha05 : AppColors.neutral100,
                  border: Border.all(
                    color: dark ? AppColors.inkAlpha20 : AppColors.neutral200,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: AppTypography.medium,
                      color: dark ? AppColors.black : AppColors.neutral500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.label,
    required this.text,
    this.muted = false,
  });

  final String label;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: muted
              ? null
              : const LinearGradient(
                  colors: [AppColors.inkAlpha04, AppColors.inkAlpha08],
                ),
          color: muted ? AppColors.neutral100Alpha72 : null,
          border: Border.all(
            color: muted ? AppColors.neutral200 : AppColors.inkAlpha12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: AppTypography.bold,
                letterSpacing: 0.88,
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: AppTypography.bold,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
