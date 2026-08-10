part of '../screens/swipe_results_screen.dart';

class _SavedGrid extends StatelessWidget {
  const _SavedGrid({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        for (var i = 0; i < urls.length; i += 2)
          Row(
            spacing: 10,
            children: [
              for (var j = i; j < i + 2; j++)
                Expanded(
                  child: j < urls.length
                      ? _DealInTile(url: urls[j], index: j)
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}

class _DealInTile extends StatelessWidget {
  const _DealInTile({required this.url, required this.index});

  final String url;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 120),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(
        scale: 0.7 + 0.3 * t.clamp(0, 1),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.darkAlpha11,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShotImage(url),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.blackAlpha50,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1,
                      fontWeight: AppTypography.bold,
                      color: AppColors.white,
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

/// Compact store context mockup with the hero shot and skeleton copy.
class _StoreContextMockup extends StatelessWidget {
  const _StoreContextMockup({required this.heroUrl, required this.scheme});

  final String heroUrl;
  final ColorScheme scheme;

  Widget _line(double widthFactor) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.82),
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outline)),
            ),
            child: Row(
              spacing: 6,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              spacing: 12,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 88,
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ShotImage(heroUrl),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _line(0.78),
                      _line(0.58),
                      _line(1),
                      _line(0.78),
                    ],
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

class _MathCard extends StatelessWidget {
  const _MathCard({required this.keptCount, required this.scheme});

  final int keptCount;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.46),
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your $keptCount shots are ready in HD.',
            style: TextStyle(
              fontSize: 21,
              height: 1.12,
              fontWeight: AppTypography.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You shot 1 product in 1 style. Pro runs your whole catalog, '
            'any mood, any drop.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _UseCasePills extends StatelessWidget {
  const _UseCasePills();

  static const List<(IconData, String, String)> _cases = [
    (
      Icons.shopping_bag_outlined,
      'PDP-ready',
      'HD shots for every product listing',
    ),
    (
      Icons.photo_camera_outlined,
      'Ad-ready',
      'Fresh creative for every campaign',
    ),
    (Icons.auto_awesome_outlined, 'Any drop', 'New styles, models, seasons'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      spacing: 8,
      children: [
        for (final (icon, title, sub) in _cases)
          Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.75),
              border: Border.all(color: scheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              spacing: 11,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: AppTypography.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: scheme.onSurface.withValues(alpha: 0.52),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.label,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ANY PRODUCT · ANY MOOD · ANY DROP',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: AppTypography.semiBold,
              letterSpacing: 1.54,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          WizardButton(
            label: label,
            trailing: Icons.arrow_forward,
            expand: true,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// Results variant when nothing was saved: pitch Pro's brand-tuning instead.
class _ZeroSavedView extends StatelessWidget {
  const _ZeroSavedView({required this.onCta, required this.scheme});

  final VoidCallback onCta;
  final ColorScheme scheme;

  static const List<(IconData, String)> _pitches = [
    (Icons.shopping_bag_outlined, 'Shoot every product in your catalog'),
    (Icons.photo_camera_outlined, 'PDP-ready, ad-ready, Shopify-ready'),
    (
      Icons.auto_awesome_outlined,
      'Try different styles until you find your look',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Let's tune this to your brand.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: AppTypography.bold,
                    letterSpacing: -0.56,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Preview's done. Pro runs shoots that match your brand: "
                  'reference-image uploads, your exact vibe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Fashion brands are specific.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: AppTypography.semiBold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pro unlocks 10x the shot variety and reference-image '
                  'uploads. Match your exact poses, angles, lighting, and '
                  'backgrounds on every shoot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                for (final (icon, text) in _pitches)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      border: Border.all(color: scheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      spacing: 12,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Most brands find their look within 2-3 shoots.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                WizardButton(
                  label: 'Run my first shoot',
                  trailing: Icons.arrow_forward,
                  expand: true,
                  onTap: onCta,
                ),
                const SizedBox(height: 12),
                Text(
                  'One-tap cancel from Settings. No emails, no phone. '
                  r'Plans from $49/mo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: AppTypography.medium,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
