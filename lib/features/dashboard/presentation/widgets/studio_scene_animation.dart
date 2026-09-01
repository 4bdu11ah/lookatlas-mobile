import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum StudioStep {
  addProduct,
  calibrate,
  pickAngles,
  createModel,
  chooseDirection,
  runShoot,
}

@immutable
class StudioProgress {
  const StudioProgress({
    required this.addProduct,
    required this.calibrate,
    required this.calibrationOptional,
    required this.pickAngles,
    required this.createModel,
    required this.chooseDirection,
    required this.runShoot,
  });

  const StudioProgress.empty()
    : addProduct = false,
      calibrate = false,
      calibrationOptional = false,
      pickAngles = false,
      createModel = false,
      chooseDirection = false,
      runShoot = false;

  final bool addProduct;
  final bool calibrate;
  final bool calibrationOptional;
  final bool pickAngles;
  final bool createModel;
  final bool chooseDirection;
  final bool runShoot;

  bool isDone(StudioStep step) => switch (step) {
    StudioStep.addProduct => addProduct,
    StudioStep.calibrate => calibrate || calibrationOptional,
    StudioStep.pickAngles => pickAngles,
    StudioStep.createModel => createModel,
    StudioStep.chooseDirection => chooseDirection,
    StudioStep.runShoot => runShoot,
  };

  StudioStep? get activeStep {
    for (final step in StudioStep.values) {
      if (!isDone(step)) return step;
    }
    return null;
  }

  int get doneCount => StudioStep.values.where(isDone).length;

  @override
  bool operator ==(Object other) =>
      other is StudioProgress &&
      addProduct == other.addProduct &&
      calibrate == other.calibrate &&
      calibrationOptional == other.calibrationOptional &&
      pickAngles == other.pickAngles &&
      createModel == other.createModel &&
      chooseDirection == other.chooseDirection &&
      runShoot == other.runShoot;

  @override
  int get hashCode => Object.hash(
    addProduct,
    calibrate,
    calibrationOptional,
    pickAngles,
    createModel,
    chooseDirection,
    runShoot,
  );
}

class StudioSceneAnimation extends StatefulWidget {
  const StudioSceneAnimation({
    required this.progress,
    this.height = 220,
    this.lineColor = Colors.white,
    this.reduceMotion = false,
    super.key,
  });

  final StudioProgress progress;
  final double height;
  final Color lineColor;
  final bool reduceMotion;

  @override
  State<StudioSceneAnimation> createState() => _StudioSceneAnimationState();
}

class _StudioSceneAnimationState extends State<StudioSceneAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _transition;
  late final Listenable _repaint;
  late StudioProgress _from;
  late StudioProgress _to;

  @override
  void initState() {
    super.initState();
    _from = widget.progress;
    _to = widget.progress;
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
    _transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 1,
    );
    _repaint = Listenable.merge([_idle, _transition]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant StudioSceneAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _from = _to;
      _to = widget.progress;
      _motionDisabled ? _transition.value = 1 : _transition.forward(from: 0);
    }
    if (widget.reduceMotion != oldWidget.reduceMotion) _syncMotion();
  }

  bool get _motionDisabled =>
      widget.reduceMotion ||
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  void _syncMotion() {
    if (_motionDisabled) {
      _idle
        ..stop()
        ..value = 0;
      _transition.value = 1;
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Studio setup illustration, ${widget.progress.doneCount} of 6 steps complete',
      image: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: double.infinity,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _repaint,
            builder: (context, _) => CustomPaint(
              painter: _StudioPainter(
                from: _from,
                to: _to,
                transition: Curves.easeOutCubic.transform(_transition.value),
                idle: _motionDisabled ? 0 : _idle.value,
                lineColor: widget.lineColor,
                reduceMotion: _motionDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudioPainter extends CustomPainter {
  const _StudioPainter({
    required this.from,
    required this.to,
    required this.transition,
    required this.idle,
    required this.lineColor,
    required this.reduceMotion,
  });

  final StudioProgress from;
  final StudioProgress to;
  final double transition;
  final double idle;
  final Color lineColor;
  final bool reduceMotion;

  static const _designSize = Size(360, 220);
  double get _tau => math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / _designSize.width,
      size.height / _designSize.height,
    );
    canvas
      ..save()
      ..translate((size.width - _designSize.width * scale) / 2, 0)
      ..scale(scale);
    _staticSet(canvas);
    _product(canvas);
    _calibration(canvas);
    _angles(canvas);
    _model(canvas);
    _direction(canvas);
    _camera(canvas);
    canvas.restore();
  }

  Paint _paint(double opacity, {double width = 1.75}) => Paint()
    ..color = lineColor.withValues(alpha: opacity.clamp(0, 1))
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  double _baseOpacity(StudioProgress state, StudioStep step) {
    if (state.isDone(step)) return 1;
    if (state.activeStep == step) {
      if (reduceMotion) return .55;
      return .54 + .26 * math.sin(_tau * idle * (5.5 / 2.4));
    }
    return .14;
  }

  double _opacity(StudioStep step) => ui.lerpDouble(
    _baseOpacity(from, step),
    _baseOpacity(to, step),
    transition,
  )!;

  void _staticSet(Canvas canvas) {
    final paint = _paint(.35, width: 3);
    canvas
      ..drawLine(const Offset(10, 200), const Offset(350, 200), paint)
      ..drawLine(const Offset(80, 14), const Offset(280, 14), paint)
      ..drawLine(const Offset(86, 14), const Offset(86, 22), paint)
      ..drawLine(const Offset(274, 14), const Offset(274, 22), paint);
  }

  void _product(Canvas canvas) {
    final opacity = _opacity(StudioStep.addProduct);
    final paint = _paint(opacity);
    final backdrop = Path()
      ..moveTo(92, 16)
      ..lineTo(92, 168)
      ..quadraticBezierTo(92, 186, 110, 186)
      ..lineTo(250, 186)
      ..quadraticBezierTo(268, 186, 268, 168)
      ..lineTo(268, 16);
    canvas
      ..drawPath(backdrop, _paint(opacity * .5))
      ..drawLine(const Offset(38, 52), const Offset(38, 200), paint)
      ..drawLine(const Offset(24, 200), const Offset(52, 200), paint)
      ..drawLine(const Offset(38, 52), const Offset(66, 52), paint);
    final sway = reduceMotion ? 0.0 : math.sin(_tau * idle * (5.5 / 3.8)) * 3.2;
    canvas
      ..save()
      ..translate(66, 52)
      ..rotate(sway * math.pi / 180)
      ..translate(-66, -52)
      ..drawLine(const Offset(66, 52), const Offset(66, 62), paint);
    final garment = Path()
      ..moveTo(56, 66)
      ..lineTo(66, 60)
      ..lineTo(76, 66)
      ..lineTo(76, 106)
      ..lineTo(56, 106)
      ..close();
    canvas
      ..drawPath(garment, paint)
      ..restore();
  }

  void _calibration(Canvas canvas) {
    final paint = _paint(_opacity(StudioStep.calibrate));
    final frame = Path()..addRect(const Rect.fromLTWH(48, 58, 36, 56));
    _drawDashedPath(canvas, frame, paint, offset: idle * 10);
    canvas
      ..drawLine(const Offset(48, 122), const Offset(84, 122), paint)
      ..drawLine(const Offset(54, 119), const Offset(54, 125), paint)
      ..drawLine(const Offset(66, 119), const Offset(66, 125), paint)
      ..drawLine(const Offset(78, 119), const Offset(78, 125), paint);
  }

  void _angles(Canvas canvas) {
    final opacity = _opacity(StudioStep.pickAngles);
    final paint = _paint(opacity);
    const centers = [Offset(120, 196), Offset(180, 204), Offset(240, 196)];
    for (var index = 0; index < centers.length; index++) {
      final pulse = reduceMotion
          ? 1.0
          : 1.15 + .25 * math.sin(_tau * idle * (5.5 / 2) + index * 2.1);
      canvas.drawCircle(centers[index], 4 * pulse, paint);
    }
    final arc = Path()
      ..moveTo(116, 188)
      ..cubicTo(139, 155, 221, 155, 244, 188);
    _drawDashedPath(canvas, arc, _paint(opacity * .6), offset: idle * 10);
  }

  void _model(Canvas canvas) {
    final paint = _paint(_opacity(StudioStep.createModel));
    final wave = reduceMotion ? 0.0 : math.sin(_tau * idle * (5.5 / 3.6));
    final y = -1.5 - wave * 1.5;
    final scale = 1.0075 + wave * .0075;
    canvas
      ..save()
      ..translate(180, 136)
      ..scale(scale)
      ..translate(-180, -136 + y)
      ..drawCircle(const Offset(180, 88), 13, paint)
      ..drawLine(const Offset(180, 101), const Offset(180, 148), paint)
      ..drawLine(const Offset(180, 112), const Offset(160, 132), paint)
      ..drawLine(const Offset(180, 112), const Offset(200, 132), paint)
      ..drawLine(const Offset(180, 148), const Offset(166, 184), paint)
      ..drawLine(const Offset(180, 148), const Offset(194, 184), paint)
      ..restore();
  }

  void _direction(Canvas canvas) {
    final opacity = _opacity(StudioStep.chooseDirection);
    final paint = _paint(opacity);
    final light = Path()
      ..moveTo(296, 94)
      ..lineTo(282, 72)
      ..lineTo(306, 66)
      ..close();
    canvas
      ..drawLine(const Offset(296, 94), const Offset(296, 200), paint)
      ..drawLine(const Offset(284, 200), const Offset(308, 200), paint)
      ..drawPath(light, paint);
    final beamOpacity = reduceMotion
        ? opacity * .4
        : opacity * (.34 + .2 * math.sin(_tau * idle * (5.5 / 3.2) + 1.1));
    final beam = Path()
      ..moveTo(282, 72)
      ..lineTo(220, 104);
    _drawDashedPath(canvas, beam, _paint(beamOpacity), offset: idle * 10);
    final chair = Path()
      ..moveTo(320, 168)
      ..lineTo(344, 168)
      ..lineTo(340, 200)
      ..moveTo(324, 200)
      ..lineTo(320, 168)
      ..moveTo(322, 182)
      ..lineTo(342, 182);
    canvas.drawPath(chair, paint);
  }

  void _camera(Canvas canvas) {
    final paint = _paint(_opacity(StudioStep.runShoot));
    final wave = reduceMotion ? 0.0 : math.sin(_tau * idle * (5.5 / 3.2) + .45);
    final y = -1.25 - wave * 1.25;
    final rotation = wave * -.8 * math.pi / 180;
    final lensScale = reduceMotion
        ? 1.0
        : 1.12 + .12 * math.sin(_tau * idle * (5.5 / 2.8) + .8);
    canvas
      ..save()
      ..translate(127, 156)
      ..rotate(rotation)
      ..translate(-127, -156 + y)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(112, 128, 30, 22),
          const Radius.circular(3),
        ),
        paint,
      )
      ..drawCircle(const Offset(127, 139), 6 * lensScale, paint)
      ..drawLine(const Offset(127, 150), const Offset(127, 178), paint)
      ..drawLine(const Offset(127, 160), const Offset(113, 184), paint)
      ..drawLine(const Offset(127, 160), const Offset(141, 184), paint)
      ..restore();
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dash = 5,
    double gap = 5,
    double offset = 0,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = -offset % (dash + gap);
      while (distance < metric.length) {
        final start = math.max(0, distance).toDouble();
        final end = math.min(metric.length, distance + dash);
        if (end > start) canvas.drawPath(metric.extractPath(start, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_StudioPainter oldDelegate) =>
      from != oldDelegate.from ||
      to != oldDelegate.to ||
      transition != oldDelegate.transition ||
      idle != oldDelegate.idle ||
      lineColor != oldDelegate.lineColor ||
      reduceMotion != oldDelegate.reduceMotion;
}
