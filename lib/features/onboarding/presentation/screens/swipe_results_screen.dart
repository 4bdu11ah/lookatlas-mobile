import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/swipe_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Post-swipe results / collection view (mockup 10): stats, the saved grid,
/// in-context mockups, the dark ROI calculator and the unlock CTA. Falls back
/// to the "tune to your brand" pitch when nothing was saved.
class SwipeResultsScreen extends ConsumerStatefulWidget {
  const SwipeResultsScreen({super.key});

  @override
  ConsumerState<SwipeResultsScreen> createState() => _SwipeResultsScreenState();
}

class _SwipeResultsScreenState extends ConsumerState<SwipeResultsScreen> {
  void _unlock() => context.go(AppRoutes.onboardingActivate);

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedImagesProvider);
    final swipe = ref.watch(swipeControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    if (saved.isEmpty) {
      return _ZeroSavedView(onCta: _unlock, scheme: scheme);
    }

    final total = ref.watch(generationControllerProvider).images.length;
    final ctaLabel =
        'Unlock my ${saved.length} '
        'photo${saved.length == 1 ? '' : 's'} in HD';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            const _BackgroundShapes(),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 108),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusPill(scheme: scheme),
                  const SizedBox(height: 18),
                  _Headline(scheme: scheme),
                  const SizedBox(height: 12),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: Text(
                        'You kept ${saved.length} of $total preview shots. '
                        'Here is your catalog in HD, once you unlock it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _StatRow(
                    kept: saved.length,
                    matchRate: swipe.matchRatePercent,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel('Your shots', scheme: scheme),
                  const SizedBox(height: 14),
                  _SavedGrid(urls: [for (final s in saved) s.url]),
                  const SizedBox(height: 28),
                  _SectionLabel('In context', scheme: scheme),
                  const SizedBox(height: 14),
                  _StoreContextMockup(heroUrl: saved.first.url, scheme: scheme),
                  const SizedBox(height: 28),
                  _SectionLabel('The math', scheme: scheme),
                  const SizedBox(height: 14),
                  _MathCard(keptCount: saved.length, scheme: scheme),
                  const SizedBox(height: 22),
                  const _UseCasePills(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _StickyBar(
                label: ctaLabel,
                onTap: _unlock,
                scheme: scheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundShapes extends StatelessWidget {
  const _BackgroundShapes();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              top: 76,
              left: -34,
              child: _SoftShape(size: 100),
            ),
            Positioned(
              top: 360,
              right: -48,
              child: _SoftShape(size: 132),
            ),
            Positioned(
              top: 122,
              right: 32,
              child: _SoftShape(size: 58),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftShape extends StatelessWidget {
  const _SoftShape({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const ColoredBox(color: AppColors.darkAlpha04),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        constraints: const BoxConstraints(minHeight: 30),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            _PingDot(color: scheme.onSurface),
            Text(
              'PREVIEW COMPLETE',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                fontWeight: AppTypography.semiBold,
                letterSpacing: 2.2,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small dot with an expanding "ping" ring.
class _PingDot extends StatefulWidget {
  const _PingDot({required this.color});

  final Color color;

  @override
  State<_PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<_PingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 6,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (t > 0.5)
                Positioned.fill(
                  child: Transform.scale(
                    scale: 1 + (t - 0.5) * 2.4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 1 - t),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
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

class _Headline extends StatelessWidget {
  const _Headline({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: 33,
      height: 1.05,
      fontWeight: AppTypography.bold,
      color: scheme.onSurface,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Your catalog is ', style: base),
          TextSpan(
            text: 'taking shape.',
            style: base.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: AppTypography.semiBold,
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.kept,
    required this.matchRate,
    required this.scheme,
  });

  final int kept;
  final int matchRate;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        for (final (n, l) in [
          ('$kept', 'Kept'),
          ('$matchRate%', 'Match'),
          ('HD', 'Ready'),
        ])
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    n,
                    style: TextStyle(
                      fontSize: 24,
                      height: 1,
                      fontWeight: AppTypography.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    l.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      height: 1,
                      fontWeight: AppTypography.semiBold,
                      letterSpacing: 1,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.scheme});

  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        Container(width: 46, height: 1, color: scheme.outline),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            height: 1,
            fontWeight: AppTypography.semiBold,
            letterSpacing: 2,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Container(width: 46, height: 1, color: scheme.outline),
      ],
    );
  }
}

/// Saved tiles "deal in" with a staggered scale/fade on first build.
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
