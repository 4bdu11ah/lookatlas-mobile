import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

/// Full-screen "starting your shoot" loader (mockup 07): a progress ring with
/// square stroke caps around a pulsing black square, rotating status messages
/// and milestone square-bursts at 25/50/75%. Hands off to the swipe deck when
/// it reaches 100%.
class StartingShootScreen extends StatefulWidget {
  const StartingShootScreen({super.key});

  @override
  State<StartingShootScreen> createState() => _StartingShootScreenState();
}

class _StartingShootScreenState extends State<StartingShootScreen>
    with TickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 3600);
  static const _burstThresholds = [25, 50, 75];

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _duration,
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  int _lastBurst = 0;

  @override
  void initState() {
    super.initState();
    _progress
      ..addListener(_onProgress)
      ..addStatusListener(_onStatus);
    unawaited(_progress.forward());
  }

  void _onProgress() {
    final percent = (_progress.value * 100).round();
    for (final t in _burstThresholds) {
      if (percent >= t && _lastBurst < t) {
        _lastBurst = t;
        unawaited(_burst.forward(from: 0));
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      context.go(AppRoutes.onboardingSwipe);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _burst.dispose();
    super.dispose();
  }

  (String, String) _messages(int percent) {
    if (percent >= 100) {
      return ('Shoot started!', 'Opening your photos...');
    }
    if (percent >= 90) {
      return ('Finalizing...', 'Opening your photos');
    }
    if (percent >= 50) return ('Creating your job...', 'Almost there');
    return ('Starting your shoot...', 'Setting up the AI');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            const _FloatingSquares(),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) {
                    final percent = (_progress.value * 100).round();
                    final (title, subtitle) = _messages(percent);
                    return Column(
                      children: [
                        SizedBox(
                          width: 168,
                          height: 168,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 128,
                                height: 128,
                                child: CustomPaint(
                                  painter: _RingPainter(
                                    progress: _progress.value,
                                    trackColor: scheme.outline,
                                    fillColor: scheme.onSurface,
                                  ),
                                ),
                              ),
                              _CenterBox(scheme: scheme),
                              _MilestoneBurst(
                                animation: _burst,
                                color: scheme.onSurface,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.2,
                            fontWeight: AppTypography.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _ProgressChip(percent: percent, scheme: scheme),
                        const SizedBox(height: 56),
                        _Footer(scheme: scheme),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Black square with a softly pulsing sparkles icon.
class _CenterBox extends StatefulWidget {
  const _CenterBox({required this.scheme});

  final ColorScheme scheme;

  @override
  State<_CenterBox> createState() => _CenterBoxState();
}

class _CenterBoxState extends State<_CenterBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: widget.scheme.onSurface,
        boxShadow: [
          BoxShadow(
            color: widget.scheme.onSurface.withValues(alpha: 0.2),
            blurRadius: 14,
          ),
        ],
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.5).animate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
        ),
        child: Icon(Icons.auto_awesome, size: 32, color: widget.scheme.surface),
      ),
    );
  }
}

/// The 128px ring with square stroke caps: full track + progress arc.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square
      ..color = fillColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Eight small squares radiating outward, fired at 25/50/75%.
class _MilestoneBurst extends StatelessWidget {
  const _MilestoneBurst({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        if (t == 0 || t == 1) return const SizedBox.shrink();
        final eased = Curves.easeOut.transform(t);
        return SizedBox(
          width: 168,
          height: 168,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 8; i++)
                Transform.translate(
                  offset: Offset(
                    math.cos(i * math.pi / 4) * (40 + 44 * eased),
                    math.sin(i * math.pi / 4) * (40 + 44 * eased),
                  ),
                  child: Opacity(
                    opacity: 1 - t,
                    child: Container(width: 6, height: 6, color: color),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({required this.percent, required this.scheme});

  final int percent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Text(
            'Progress',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: AppTypography.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Column(
        spacing: 16,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(Icons.schedule, size: 16, color: scheme.onSurfaceVariant),
              Text(
                'Generation takes about 5 minutes',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            "You can leave this page — we'll keep generating in the "
            'background.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Faint floating squares in the background, echoing the mockup's floatDeep
/// decoration.
class _FloatingSquares extends StatelessWidget {
  const _FloatingSquares();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.025);
    final faint = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.015);
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;
            return Stack(
              children: [
                Positioned(
                  top: h * 0.10,
                  left: w * 0.05,
                  child: Transform.rotate(
                    angle: 15 * math.pi / 180,
                    child: Container(width: 128, height: 128, color: color),
                  ),
                ),
                Positioned(
                  top: h * 0.60,
                  right: w * 0.08,
                  child: Transform.rotate(
                    angle: -20 * math.pi / 180,
                    child: Container(width: 160, height: 160, color: faint),
                  ),
                ),
                Positioned(
                  bottom: h * 0.25,
                  left: w * 0.04,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
