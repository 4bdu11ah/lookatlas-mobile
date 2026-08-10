import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

/// Animated shimmer placeholder shown while an image (or any content) loads:
/// a soft highlight band sweeps diagonally across a muted base, matching the
/// monochrome design system. Fills whatever box it's given.
///
/// Renders the static base color when `MediaQuery.disableAnimations` is set,
/// and under `flutter test` — a forever-repeating ticker would otherwise
/// keep `pumpAndSettle` from ever settling on screens with loading images.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.dark = false, this.borderRadius});

  /// Dark-surface variant for the black paywall/success screens.
  final bool dark;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

/// Lightweight content skeleton for a list or form while its initial data is
/// loading. Use a feature-specific skeleton only when the final layout needs
/// a more accurate shape.
class ContentShimmer extends StatelessWidget {
  const ContentShimmer({
    required this.itemCount,
    this.itemHeight = 96,
    this.gap = 12,
    super.key,
  });

  final int itemCount;
  final double itemHeight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < itemCount; index++) ...[
          SizedBox(height: itemHeight, child: const ShimmerBox()),
          if (index != itemCount - 1) SizedBox(height: gap),
        ],
      ],
    );
  }
}

/// True when running under the widget-test harness.
final bool _isTestEnvironment =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  // Created in initState (not lazily) so dispose never constructs a ticker
  // while the element tree is being torn down.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!_isTestEnvironment) unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (base, highlight) = widget.dark
        ? (AppColors.neutral940, AppColors.neutral945)
        : (AppColors.neutral225, AppColors.neutral150);

    if (_isTestEnvironment || MediaQuery.disableAnimationsOf(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: base,
          borderRadius: widget.borderRadius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Slide the highlight band from just off the top-left to just off
        // the bottom-right each cycle.
        final t = _controller.value * 1.8 - 0.4;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, highlight, base],
              stops: [
                (t - 0.25).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.25).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
