import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pulsing-bars spinner, a port of the web app's `Spinner` (loader.tsx):
/// 4 square-cornered bars, 0.8s ease-in-out pulse (scaleY and opacity
/// 0.4 -> 1), each bar phase-shifted by 0.15s so the wave loops seamlessly.
class BarSpinner extends StatefulWidget {
  const BarSpinner({super.key, this.size = 24, this.color});

  final double size;

  /// Defaults to the surrounding text color (like `bg-current` on web), so it
  /// picks up a button's foreground automatically.
  final Color? color;

  @override
  State<BarSpinner> createState() => _BarSpinnerState();
}

class _BarSpinnerState extends State<BarSpinner>
    with SingleTickerProviderStateMixin {
  static const Duration _cycle = Duration(milliseconds: 800);
  static const double _staggerFraction = 0.15 / 0.8; // 0.15s delay per bar.

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 0%/100% -> 0.0, 50% -> 1.0, eased like CSS ease-in-out.
  double _pulse(double t) {
    final tri = t < 0.5 ? t * 2 : 2 - t * 2;
    return Curves.easeInOut.transform(tri);
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;

    // Same sizing math as the web version.
    final barWidth = math.max<double>(2, (widget.size / 8).floorToDouble());
    final barHeight = math.max<double>(6, (widget.size / 3).floorToDouble());

    return Semantics(
      label: 'Loading',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: List.generate(4, (i) {
                final t = (_controller.value - i * _staggerFraction) % 1.0;
                final v = _pulse(t);
                return Opacity(
                  opacity: 0.4 + 0.6 * v,
                  child: Transform.scale(
                    scaleY: 0.4 + 0.6 * v,
                    child: Container(
                      width: barWidth,
                      height: barHeight,
                      color: color,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

/// Port of the web `ButtonLoader`: a 16px [BarSpinner] plus optional text.
/// Drop into a button's child while its action is in flight.
class ButtonLoader extends StatelessWidget {
  const ButtonLoader({super.key, this.text, this.color});

  final String? text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BarSpinner(size: 16, color: color),
        if (text != null) ...[const SizedBox(width: 8), Text(text!)],
      ],
    );
  }
}
