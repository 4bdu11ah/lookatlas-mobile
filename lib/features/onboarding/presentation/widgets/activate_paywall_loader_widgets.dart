part of '../screens/activate_paywall_screen.dart';

class _AnalyzingLoader extends StatefulWidget {
  const _AnalyzingLoader({required this.savedCount, required this.urls});

  final int savedCount;
  final List<String> urls;

  @override
  State<_AnalyzingLoader> createState() => _AnalyzingLoaderState();
}

class _AnalyzingLoaderState extends State<_AnalyzingLoader>
    with TickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();
  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  )..forward();
  Timer? _phaseTimer;
  int _phase = 0;

  List<String> get _phases => [
    'Analyzing your ${widget.savedCount} liked looks',
    'Matching your style profile',
    'Building your offer',
  ];

  @override
  void initState() {
    super.initState();
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      setState(() => _phase = (_phase + 1) % _phases.length);
    });
  }

  @override
  void dispose() {
    _orbit.dispose();
    _bar.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft overhead glow.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 0.9,
                colors: [
                  AppColors.whiteAlpha09,
                  AppColors.whiteAlpha03,
                  AppColors.transparent,
                ],
                stops: [0, 0.45, 0.75],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 256,
                    height: 256,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Center glow.
                        Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.whiteAlpha22,
                                AppColors.whiteAlpha06,
                                AppColors.transparent,
                              ],
                              stops: [0, 0.55, 0.8],
                            ),
                          ),
                        ),
                        // Six grayscale look thumbs orbiting the ring.
                        AnimatedBuilder(
                          animation: _orbit,
                          builder: (context, _) => Transform.rotate(
                            angle: _orbit.value * 2 * math.pi,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                for (var i = 0; i < 6; i++)
                                  Transform.translate(
                                    offset: Offset(
                                      math.cos(i * math.pi / 3 - math.pi / 2) *
                                          108,
                                      math.sin(i * math.pi / 3 - math.pi / 2) *
                                          108,
                                    ),
                                    child: Transform.rotate(
                                      angle: -_orbit.value * 2 * math.pi,
                                      child: _LookThumb(
                                        index: i,
                                        url: widget.urls.isEmpty
                                            ? null
                                            : widget.urls[i %
                                                  widget.urls.length],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const _Aperture(),
                        for (final corner in const [
                          Alignment.topLeft,
                          Alignment.topRight,
                          Alignment.bottomLeft,
                          Alignment.bottomRight,
                        ])
                          Align(
                            alignment: corner,
                            child: _Bracket(alignment: corner),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _phases[_phase],
                      key: ValueKey(_phase),
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.3,
                        fontWeight: AppTypography.medium,
                        letterSpacing: -0.22,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PLEASE HOLD',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: AppTypography.medium,
                      letterSpacing: 2.75,
                      color: AppColors.whiteAlpha40,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 240,
                    height: 1,
                    child: AnimatedBuilder(
                      animation: _bar,
                      builder: (context, _) => Stack(
                        children: [
                          const ColoredBox(color: AppColors.whiteAlpha10),
                          FractionallySizedBox(
                            widthFactor: _bar.value,
                            heightFactor: 1,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.whiteAlpha50,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LookThumb extends StatelessWidget {
  const _LookThumb({required this.index, required this.url});

  final int index;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.whiteAlpha15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: index.isEven
              ? const [AppColors.neutral950, AppColors.neutral925]
              : const [AppColors.neutral960, AppColors.neutral940],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.blackAlpha60,
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: url == null
          ? null
          : ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: ShotImage(url!, dark: true),
            ),
    );
  }
}

/// The camera-aperture dot with a pulsing ring.
class _Aperture extends StatefulWidget {
  const _Aperture();

  @override
  State<_Aperture> createState() => _ApertureState();
}

class _ApertureState extends State<_Aperture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.blackAlpha40,
            border: Border.all(color: AppColors.whiteAlpha30),
            boxShadow: [
              BoxShadow(
                color: AppColors.white.withValues(alpha: 0.18 * (1 - t)),
                spreadRadius: 16 * t,
              ),
            ],
          ),
          child: const Center(
            child: SizedBox.square(
              dimension: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.whiteAlpha25);
    return SizedBox.square(
      dimension: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0 ? side : BorderSide.none,
            bottom: alignment.y > 0 ? side : BorderSide.none,
            left: alignment.x < 0 ? side : BorderSide.none,
            right: alignment.x > 0 ? side : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// --- State B: the paywall -------------------------------------------------------
