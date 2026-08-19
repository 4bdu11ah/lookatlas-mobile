part of 'welcome_profile_screen.dart';

class _ProfileWorktable extends StatelessWidget {
  const _ProfileWorktable({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -.48),
        radius: 1.15,
        colors: [AppColors.white, Color(0xFFF2F2F3), Color(0xFFD6D7DA)],
        stops: [0, .48, 1],
      ),
    ),
    child: CustomPaint(
      painter: const _WorktablePainter(),
      child: child,
    ),
  );
}

class _DirectorPrints extends StatefulWidget {
  const _DirectorPrints({
    required this.step,
    required this.animateEntrance,
    required this.onEntranceComplete,
  });
  final int step;
  final bool animateEntrance;
  final VoidCallback onEntranceComplete;

  static const _sets = [
    ['minimalist/1.jpg', 'luxury-editorial/3.jpg', 'lifestyle-natural/2.jpg'],
    ['fine-jewelry/1.jpg', 'street-energy/3.jpg', 'minimalist/4.jpg'],
    [
      'luxury-editorial/1.jpg',
      'lifestyle-natural/4.jpg',
      'editorial-jewelry/2.jpg',
    ],
    ['bold-dramatic/1.jpg', 'fine-jewelry/3.jpg', 'clean-pro/4.jpg'],
  ];

  @override
  State<_DirectorPrints> createState() => _DirectorPrintsState();
}

class _DirectorPrintsState extends State<_DirectorPrints>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: widget.animateEntrance ? 0 : 1,
    )..addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onEntranceComplete();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animateEntrance || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      unawaited(_controller.forward());
    }
  }

  @override
  void didUpdateWidget(covariant _DirectorPrints oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animateEntrance) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final entranceDistance = MediaQuery.sizeOf(context).width + 88;
    return ExcludeSemantics(
      child: SizedBox(
        height: 180,
        child: Center(
          child: SizedBox(
            width: 250,
            height: 132,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                for (var index = 0; index < 3; index++)
                  Positioned(
                    left: 24.0 + index * 60,
                    top: 24,
                    child: _AnimatedDirectorPrint(
                      key: ValueKey('director-print-$index'),
                      animation: _controller,
                      index: index,
                      reduceMotion: reduceMotion,
                      entranceDistance: entranceDistance,
                      child: Container(
                        width: 88,
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: AppColors.neutral200),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.blackAlpha15,
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset(
                              'assets/directors/${_DirectorPrints._sets[widget.step][index]}',
                              width: 76,
                              height: 95,
                              fit: BoxFit.cover,
                              cacheWidth: (76 * dpr).round(),
                              cacheHeight: (95 * dpr).round(),
                            ),
                            const Positioned(
                              top: -13,
                              left: 23,
                              child: SizedBox(
                                width: 32,
                                height: 14,
                                child: ColoredBox(color: Color(0xB8D8D8D8)),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _AnimatedDirectorPrint extends StatelessWidget {
  const _AnimatedDirectorPrint({
    required this.animation,
    required this.index,
    required this.reduceMotion,
    required this.entranceDistance,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final int index;
  final bool reduceMotion;
  final double entranceDistance;
  final Widget child;

  static const _rotations = [-.14, .07, .16];
  static const _entranceDirections = [-1.0, -1.0, 1.0];

  @override
  Widget build(BuildContext context) {
    final progress = reduceMotion
        ? const AlwaysStoppedAnimation<double>(1)
        : CurvedAnimation(
            parent: animation,
            curve: Interval(
              index * .1,
              .8 + index * .1,
              curve: const Cubic(.215, .61, .355, 1),
            ),
          );
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final value = progress.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              _entranceDirections[index] * entranceDistance * (1 - value),
              0,
            ),
            child: Transform.rotate(
              angle: _rotations[index] * value,
              alignment: Alignment.topCenter,
              child: Transform.scale(
                scale: 1.03 - (.03 * value),
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WorktablePainter extends CustomPainter {
  const _WorktablePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.black.withValues(alpha: .028)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final grain = Paint()..color = AppColors.black.withValues(alpha: .025);
    for (var y = 7.0; y < size.height; y += 23) {
      for (var x = 11.0; x < size.width; x += 29) {
        canvas.drawCircle(Offset(x, y), .45, grain);
      }
    }
  }

  @override
  bool shouldRepaint(_WorktablePainter oldDelegate) => false;
}
