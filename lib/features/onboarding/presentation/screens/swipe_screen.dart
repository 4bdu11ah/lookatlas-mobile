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

part '../widgets/swipe_screen_widgets.dart';

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
    _release.forward(from: 0);
  }

  void _cancelDrag() {
    if (_release.isAnimating) return;
    _pendingDecision = null;
    _releaseFrom = _drag;
    _releaseTo = Offset.zero;
    _release.forward(from: 0);
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
