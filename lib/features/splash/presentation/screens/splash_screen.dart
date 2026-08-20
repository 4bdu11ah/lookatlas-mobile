import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:look_atlas/shared/widgets/look_atlas_loader.dart';

/// Branded launch screen: dust particles assemble into the "Look Atlas"
/// wordmark ([LookAtlasLoader]), hold for a moment, then the app moves on —
/// signed-in users to home and signed-out users to sign-in.
///
/// The hand-off clock starts when the loader reports the intro is actually
/// playing (via `onIntroStarted`) rather than at mount, so slow devices that
/// spend time rasterizing the wordmark still get the full animation. A
/// fallback timer starts the clock anyway if that signal never arrives.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Time on screen once the intro starts: ~590ms of converge, the rest a
  /// hold so the wordmark can land before the app moves on.
  static const _holdDuration = Duration(milliseconds: 2400);

  /// If the loader never signals (unexpected), leave anyway after this.
  static const _fallbackDelay = Duration(seconds: 3);

  late final AnimationController _controller;
  Timer? _fallback;
  bool _isRouting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener(_onStatusChanged);
    _fallback = Timer(_fallbackDelay, _startClock);
  }

  void _startClock() {
    _fallback?.cancel();
    if (mounted && !_controller.isAnimating && !_controller.isCompleted) {
      unawaited(_controller.forward());
    }
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      unawaited(_routeFromAccessStatus());
    }
  }

  Future<void> _routeFromAccessStatus() async {
    if (_isRouting) return;
    _isRouting = true;
    if (ref.read(authRepositoryProvider).currentUser == null) {
      if (mounted) context.go(AppRoutes.signIn);
      return;
    }

    final result = await ref.read(getOnboardingStatusUseCaseProvider)();
    if (!mounted) return;
    if (result case Err()) {
      context.go(AppRoutes.onboarding);
      return;
    }

    final status = result.valueOrNull!;
    if (status.hasActiveSubscription) {
      context.go(AppRoutes.home);
      return;
    }

    final jobStatus = status.onboardingJobStatus?.toLowerCase();
    if ({'generating', 'enqueued', 'processing', 'completed'}.contains(
      jobStatus,
    )) {
      ref.read(generationControllerProvider.notifier).start();
      context.go(AppRoutes.onboardingSwipe);
      return;
    }

    context.go(
      status.freeShootUsed ? AppRoutes.onboardingActivate : AppRoutes.onboarding,
    );
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: LookAtlasLoader(
        backgroundColor: scheme.surface,
        particleColor: scheme.onSurface,
        onIntroStarted: _startClock,
      ),
    );
  }
}
