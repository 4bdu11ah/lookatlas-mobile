part of '../screens/swipe_results_screen.dart';

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
