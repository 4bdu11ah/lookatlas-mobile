part of '../screens/swipe_screen.dart';

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
