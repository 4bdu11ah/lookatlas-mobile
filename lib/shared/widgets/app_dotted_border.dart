import 'package:flutter/material.dart';

/// Paints a reusable dotted border around [child].
class AppDottedBorder extends StatelessWidget {
  const AppDottedBorder({
    required this.child,
    this.color,
    this.strokeWidth = 1,
    this.dotWidth = 4,
    this.gap = 4,
    super.key,
  }) : assert(strokeWidth > 0, 'strokeWidth must be greater than zero.'),
       assert(dotWidth > 0, 'dotWidth must be greater than zero.'),
       assert(gap >= 0, 'gap cannot be negative.');

  final Widget child;
  final Color? color;
  final double strokeWidth;
  final double dotWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DottedBorderPainter(
        color: color ?? Theme.of(context).colorScheme.outline,
        strokeWidth: strokeWidth,
        dotWidth: dotWidth,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  const _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dotWidth,
    required this.gap,
  });

  final Color color;
  final double strokeWidth;
  final double dotWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    if (rect.width <= 0 || rect.height <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    _paintLine(canvas, paint, rect.topLeft, rect.topRight);
    _paintLine(canvas, paint, rect.topRight, rect.bottomRight);
    _paintLine(canvas, paint, rect.bottomRight, rect.bottomLeft);
    _paintLine(canvas, paint, rect.bottomLeft, rect.topLeft);
  }

  void _paintLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final vector = end - start;
    final length = vector.distance;
    final direction = Offset(vector.dx / length, vector.dy / length);
    var distance = 0.0;
    while (distance < length) {
      final endDistance = (distance + dotWidth).clamp(0.0, length);
      canvas.drawLine(
        start + direction * distance,
        start + direction * endDistance,
        paint,
      );
      distance += dotWidth + gap;
    }
  }

  @override
  bool shouldRepaint(_DottedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dotWidth != oldDelegate.dotWidth ||
        gap != oldDelegate.gap;
  }
}
