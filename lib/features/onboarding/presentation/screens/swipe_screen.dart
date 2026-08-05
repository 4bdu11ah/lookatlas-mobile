import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/swipe_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Tinder-style save/skip view over the 15 generated photos (mockup 09):
/// drag or use the undo/pass/save buttons, liquid-fill loading while the next
/// photo is still generating, milestone toasts on saves. Moves to the results
/// screen after the last card.
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen>
    with TickerProviderStateMixin {
  static const _swipeThreshold = 100.0;
  static const _milestones = {
    1: 'First pick!',
    5: '5 saved — great eye',
    10: '10 saved!',
  };
  static const _proofPoints = [
    r'This shoot would cost $1,500+ at a traditional studio',
    'Studio shoots take 2-3 weeks. Yours takes minutes.',
    '15 photos. One product. Zero logistics.',
  ];

  Offset _drag = Offset.zero;
  bool _muted = false;
  String? _milestone;
  Timer? _milestoneTimer;
  Timer? _proofTimer;
  int _proofIndex = 0;

  /// Animates the card off screen (decide) or back to center (cancel).
  late final AnimationController _release = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Offset _releaseFrom = Offset.zero;
  Offset _releaseTo = Offset.zero;
  bool? _pendingDecision;

  @override
  void initState() {
    super.initState();
    _release
      ..addListener(() {
        setState(() {
          _drag = Offset.lerp(_releaseFrom, _releaseTo, _release.value)!;
        });
      })
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        final decision = _pendingDecision;
        _pendingDecision = null;
        if (decision != null) {
          ref.read(swipeControllerProvider.notifier).decide(saved: decision);
          _onDecision(saved: decision);
        }
        setState(() => _drag = Offset.zero);
      });
    _proofTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      setState(() => _proofIndex = (_proofIndex + 1) % _proofPoints.length);
    });
    // Deep-link safety: make sure a shoot exists to swipe through.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(generationControllerProvider).started) {
        ref.read(generationControllerProvider.notifier).start();
      }
    });
  }

  @override
  void dispose() {
    _release.dispose();
    _milestoneTimer?.cancel();
    _proofTimer?.cancel();
    super.dispose();
  }

  void _onDecision({required bool saved}) {
    final state = ref.read(swipeControllerProvider);
    final generation = ref.read(generationControllerProvider);
    if (generation.isTerminal && state.currentIndex >= generation.readyCount) {
      context.go(AppRoutes.onboardingResults);
      return;
    }
    if (saved) {
      final toast = _milestones[state.savedCount];
      if (toast != null) {
        _milestoneTimer?.cancel();
        setState(() => _milestone = toast);
        _milestoneTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _milestone = null);
        });
      }
    }
  }

  void _decide({required bool saved, required double width}) {
    if (_release.isAnimating) return;
    _pendingDecision = saved;
    _releaseFrom = _drag;
    _releaseTo = Offset((saved ? 1 : -1) * width * 1.4, _drag.dy * 1.4);
    unawaited(_release.forward(from: 0));
  }

  void _cancelDrag() {
    if (_release.isAnimating) return;
    _pendingDecision = null;
    _releaseFrom = _drag;
    _releaseTo = Offset.zero;
    unawaited(_release.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final generation = ref.watch(generationControllerProvider);
    final swipe = ref.watch(swipeControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    ref.listen(generationControllerProvider, (_, next) {
      if (next.shouldOpenPlans && mounted) {
        context.go(AppRoutes.onboardingActivate);
      }
    });

    if (generation.jobStatus == 'failed' && generation.images.isEmpty) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Your shoot could not be generated. Please contact support.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurface),
              ),
            ),
          ),
        ),
      );
    }

    if (generation.isTerminal && swipe.currentIndex >= generation.readyCount) {
      // Finished deck (e.g. resumed route): move on to results.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.onboardingResults);
      });
      return Scaffold(backgroundColor: scheme.surface, body: const SizedBox());
    }

    final index = swipe.currentIndex.clamp(0, generation.images.length - 1);
    final image = generation.images[index];
    final waiting = !image.isReady;
    final isFirst = index == 0;
    final loadingProgress = generation.images.isEmpty
        ? 0.0
        : generation.readyCount / generation.images.length;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _TopBar(
                count: '${index + 1} of ${generation.images.length}',
                savedCount: swipe.savedCount,
                milestone: _milestone,
                muted: _muted,
                onToggleMute: () => setState(() => _muted = !_muted),
                scheme: scheme,
              ),
              const SizedBox(height: 20),
              _Header(
                isFirst: isFirst,
                waiting: waiting,
                scheme: scheme,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Size the card to whatever height remains once the
                    // caption + action buttons (~170px) are accounted for,
                    // so small screens never overflow.
                    final cardWidth = math
                        .min<double>(
                          math.min<double>(width - 60, 340),
                          (constraints.maxHeight - 170) * 3 / 4,
                        )
                        .clamp(120.0, 400.0);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Card + deck slivers.
                        _CardStack(
                          image: image,
                          waiting: waiting,
                          loadingProgress: loadingProgress,
                          drag: _drag,
                          cardWidth: cardWidth,
                          onDragUpdate: waiting
                              ? null
                              : (delta) => setState(() => _drag += delta),
                          onDragEnd: waiting
                              ? null
                              : () {
                                  if (_drag.dx.abs() > _swipeThreshold) {
                                    _decide(saved: _drag.dx > 0, width: width);
                                  } else {
                                    _cancelDrag();
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          waiting
                              ? 'Preparing your photo...'
                              : "Save the ones you'd use",
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Actions(
                          enabled: !waiting,
                          canUndo: swipe.canUndo,
                          onUndo: () {
                            ref.read(swipeControllerProvider.notifier).undo();
                            setState(() => _drag = Offset.zero);
                          },
                          onPass: () => _decide(saved: false, width: width),
                          onSave: () => _decide(saved: true, width: width),
                          scheme: scheme,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _proofPoints[_proofIndex],
                  key: ValueKey(_proofIndex),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.35),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.count,
    required this.savedCount,
    required this.milestone,
    required this.muted,
    required this.onToggleMute,
    required this.scheme,
  });

  final String count;
  final int savedCount;
  final String? milestone;
  final bool muted;
  final VoidCallback onToggleMute;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            count,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (savedCount > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Icon(Icons.favorite, size: 16, color: scheme.onSurface),
                  Text(
                    '$savedCount saved',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: AppTypography.medium,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            if (milestone != null)
              Positioned(
                top: -38,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.onSurface,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.blackAlpha25,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    milestone!,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: AppTypography.medium,
                      color: scheme.surface,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onToggleMute,
              icon: Icon(
                muted ? Icons.volume_off : Icons.volume_up,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isFirst,
    required this.waiting,
    required this.scheme,
  });

  final bool isFirst;
  final bool waiting;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (isFirst && !waiting) {
      return Column(
        spacing: 4,
        children: [
          Text(
            'Your shoot is underway',
            style: TextStyle(
              fontSize: 18,
              height: 1.3,
              fontWeight: AppTypography.bold,
              color: scheme.onSurface,
            ),
          ),
          Text(
            'Save the ones you love, skip the rest.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Some shots may look similar. We're learning your style.",
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      );
    }
    return Text(
      waiting ? 'Creating your next photo...' : 'Save or skip',
      style: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: scheme.onSurface.withValues(alpha: waiting ? 0.5 : 0.6),
      ),
    );
  }
}

/// The draggable top card plus the two deck slivers underneath.
class _CardStack extends StatelessWidget {
  const _CardStack({
    required this.image,
    required this.waiting,
    required this.loadingProgress,
    required this.drag,
    required this.cardWidth,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final GeneratedImage image;
  final bool waiting;
  final double loadingProgress;
  final Offset drag;
  final double cardWidth;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final angle = drag.dx / 1000;
    final saveOpacity = ((drag.dx - 30) / 90).clamp(0.0, 1.0);
    final passOpacity = ((-drag.dx - 30) / 90).clamp(0.0, 1.0);

    return Column(
      children: [
        GestureDetector(
          onPanUpdate: onDragUpdate == null
              ? null
              : (d) => onDragUpdate!(d.delta),
          onPanEnd: onDragEnd == null ? null : (_) => onDragEnd!(),
          child: Transform.translate(
            offset: drag,
            child: Transform.rotate(
              angle: angle,
              child: Container(
                width: cardWidth,
                height: cardWidth * 4 / 3,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.blackAlpha10,
                      blurRadius: 25,
                      offset: Offset(0, 20),
                    ),
                    BoxShadow(
                      color: AppColors.blackAlpha10,
                      blurRadius: 10,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: waiting
                    ? _LiquidFill(
                        key: ValueKey(
                          'liquid-${image.shot}-${image.variation}',
                        ),
                        progress: loadingProgress,
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ShotImage(image.url),
                          // Trial: HD locked.
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.inkAlpha80,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          _SwipeGlow(
                            opacity: saveOpacity,
                            color: AppColors.success,
                            icon: Icons.favorite,
                            alignment: Alignment.topLeft,
                          ),
                          _SwipeGlow(
                            opacity: passOpacity,
                            color: AppColors.danger,
                            icon: Icons.close,
                            alignment: Alignment.topRight,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        // Deck slivers hinting at the cards below.
        Container(
          width: cardWidth - 12,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.inkAlpha08,
            border: Border(
              left: BorderSide(color: AppColors.neutral200Alpha40),
              right: BorderSide(color: AppColors.neutral200Alpha40),
              bottom: BorderSide(color: AppColors.neutral200Alpha40),
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 1),
        Container(
          width: cardWidth - 24,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.inkAlpha05,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
        ),
      ],
    );
  }
}

/// Green heart / red X drag feedback overlay.
class _SwipeGlow extends StatelessWidget {
  const _SwipeGlow({
    required this.opacity,
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final double opacity;
  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (opacity == 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color.withValues(alpha: 0.25)),
          child: Align(
            alignment: alignment == Alignment.topLeft
                ? const Alignment(-0.7, -0.7)
                : const Alignment(0.7, -0.7),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppColors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Undo / pass / save round buttons.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.enabled,
    required this.canUndo,
    required this.onUndo,
    required this.onPass,
    required this.onSave,
    required this.scheme,
  });

  final bool enabled;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onPass;
  final VoidCallback onSave;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 24,
      children: [
        _RoundButton(
          key: const ValueKey('swipe-undo'),
          size: 48,
          onTap: canUndo ? onUndo : null,
          border: scheme.onSurface.withValues(alpha: 0.15),
          child: Icon(
            Icons.undo,
            size: 20,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        _RoundButton(
          key: const ValueKey('swipe-pass'),
          size: 56,
          onTap: enabled ? onPass : null,
          border: scheme.onSurface.withValues(alpha: 0.2),
          child: Icon(
            Icons.close,
            size: 24,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        _RoundButton(
          key: const ValueKey('swipe-save'),
          size: 64,
          onTap: enabled ? onSave : null,
          fill: scheme.onSurface,
          child: Icon(Icons.favorite, size: 28, color: scheme.surface),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.onTap,
    required this.child,
    this.border,
    this.fill,
    super.key,
  });

  final double size;
  final VoidCallback? onTap;
  final Widget child;
  final Color? border;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: fill ?? Theme.of(context).colorScheme.surface,
        shape: border == null
            ? const CircleBorder()
            : CircleBorder(side: BorderSide(color: border!, width: 2)),
        elevation: fill == null ? 0 : 6,
        shadowColor: AppColors.blackAlpha20,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Black liquid rising up the card while generated image progress advances,
/// with a scrolling wave crest and progress-based status copy.
class _LiquidFill extends StatefulWidget {
  const _LiquidFill({
    required this.progress,
    super.key,
  });

  final double progress;

  @override
  State<_LiquidFill> createState() => _LiquidFillState();
}

class _LiquidFillState extends State<_LiquidFill>
    with TickerProviderStateMixin {
  static const _messageInterval = Duration(milliseconds: 4000);
  static const _messages = [
    'Your director is studying your product...',
    'Planning the perfect composition...',
    'Sketching the scene...',
    'Choosing the model and pose...',
    'Setting up the lighting...',
    'Calibrating shadows and highlights...',
    'Positioning the model...',
    'Framing the shot...',
    'Capturing the moment...',
    'Reviewing the take...',
    'Adjusting for your style...',
    'Color grading...',
    'Sharpening the details...',
    'Adding the finishing touches...',
  ];

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _messageTimer = Timer.periodic(_messageInterval, (_) {
      if (_messageIndex >= _messages.length - 1) {
        _messageTimer?.cancel();
        _messageTimer = null;
        return;
      }
      setState(() => _messageIndex += 1);
    });
  }

  @override
  void dispose() {
    _wave.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wave,
      builder: (context, _) {
        final progress = widget.progress.clamp(0.0, 1.0);
        final fill = progress == 1 ? 1.0 : 0.08 + progress * 0.88;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.white),
            CustomPaint(
              painter: _LiquidPainter(fill: fill, phase: _wave.value),
            ),
            Align(
              alignment: const Alignment(0, 0.75),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: AppColors.white.withValues(alpha: 0.25),
                    ),
                    Text(
                      _messages[_messageIndex],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiquidPainter extends CustomPainter {
  const _LiquidPainter({required this.fill, required this.phase});

  /// 0..1 fraction of the card filled from the bottom.
  final double fill;

  /// 0..1 horizontal wave scroll position.
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final surfaceY = size.height * (1 - fill);
    for (final (amplitude, shift, color) in [
      (10.0, 0.0, AppColors.nearBlack),
      (8.0, math.pi, AppColors.inkAlpha80),
    ]) {
      final path = Path()..moveTo(0, surfaceY);
      for (var x = 0.0; x <= size.width; x += 4) {
        final y =
            surfaceY +
            math.sin(
                  x / size.width * 4 * math.pi + phase * 2 * math.pi + shift,
                ) *
                amplitude;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LiquidPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.phase != phase;
}
