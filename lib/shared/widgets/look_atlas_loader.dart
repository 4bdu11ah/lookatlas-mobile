import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

/// Full-screen loader, a port of the web app's `FullScreenLoader`
/// (loader.tsx): dust particles converge into the "Look Atlas" wordmark over
/// ~590ms (450ms travel + up to 140ms per-particle stagger), then hold with a
/// subtle wobble until the widget is removed.
///
/// Performance notes:
/// - The wordmark is rasterized once per size and its pixels are scanned
///   inline — at logical resolution that's a few milliseconds, far cheaper
///   than spawning an isolate (which used to delay the intro visibly).
/// - Particles live in flat typed arrays and are drawn with a handful of
///   batched `drawRawPoints` calls per frame instead of thousands of
///   individual circles.
/// - Honors `MediaQuery.disableAnimations` by rendering the static wordmark.
class LookAtlasLoader extends StatefulWidget {
  const LookAtlasLoader({
    super.key,
    this.title,
    this.subtitle,
    this.text = 'Look Atlas',
    this.particleColor = const Color(0xFF0A0A0A),
    this.backgroundColor = Colors.white,
    // Web uses 6000; lower this if older devices drop frames.
    this.particleCap = 6000,
    this.onIntroStarted,
  });

  final String? title;
  final String? subtitle;
  final String text;
  final Color particleColor;
  final Color backgroundColor;
  final int particleCap;

  /// Fired once when the intro actually starts playing (particle field
  /// generated, first animated frame about to draw). Hosts that time
  /// something to the intro — like the splash screen's hand-off — should
  /// start their clock here, not at mount: rasterizing + pixel-scanning the
  /// wordmark can take a while on slower devices.
  final VoidCallback? onIntroStarted;

  @override
  State<LookAtlasLoader> createState() => _LookAtlasLoaderState();
}

class _LookAtlasLoaderState extends State<LookAtlasLoader>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _elapsedMs = ValueNotifier(0);
  _ParticleField? _field;
  Size _generatedFor = Size.zero;
  int _generation = 0;
  bool _introNotified = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _elapsedMs.value = elapsed.inMicroseconds / 1000;
    });
    unawaited(_ticker.start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsedMs.dispose();
    super.dispose();
  }

  static double _fontSize(double width) =>
      math.min(76, math.max(38, (width * 0.075).floorToDouble()));

  TextStyle _wordmarkStyle(double width, Color color) => TextStyle(
    fontFamily: AppTypography.displayFontFamily,
    fontSize: _fontSize(width),
    fontWeight: AppTypography.regular,
    color: color,
  );

  /// Rasterizes the wordmark offscreen, scans its opaque pixels in a
  /// background isolate, and builds the particle field from the result.
  Future<void> _generateParticles(Size size) async {
    final generation = ++_generation;
    final w = size.width.floor();
    final h = size.height.floor();
    if (w <= 0 || h <= 0) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final tp = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: _wordmarkStyle(size.width, Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp
      ..paint(
        canvas,
        Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2),
      )
      ..dispose();

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    picture.dispose();
    final byteData = await image.toByteData();
    image.dispose();
    if (byteData == null || generation != _generation || !mounted) return;

    // Scanned inline: at logical resolution this is a few ms, while an
    // isolate round-trip (spawn + copying the pixel buffer twice) used to
    // hold the intro on a blank screen noticeably longer.
    final targets = _sampleTargets(
      byteData.buffer.asUint8List(),
      w,
      h,
      widget.particleCap,
    );
    if (generation != _generation || !mounted) return;

    // Restart the clock so the converge animation always plays from zero —
    // without this, slow setup (raster + isolate) would eat into the travel
    // window and the particles would appear already converged.
    _ticker.stop();
    _elapsedMs.value = 0;
    unawaited(_ticker.start());

    setState(() => _field = _ParticleField.generate(targets, size));
    _notifyIntroStarted();
  }

  void _notifyIntroStarted() {
    if (_introNotified) return;
    _introNotified = true;
    widget.onIntroStarted?.call();
  }

  /// Returns (x, y) pairs of wordmark pixels, downsampled to at most [cap].
  static Float32List _sampleTargets(Uint8List rgba, int w, int h, int cap) {
    final found = <double>[];
    for (var y = 0; y < h; y++) {
      final row = y * w;
      for (var x = 0; x < w; x++) {
        if (rgba[(row + x) * 4 + 3] > 128) {
          found
            ..add(x.toDouble())
            ..add(y.toDouble());
        }
      }
    }
    final total = found.length ~/ 2;
    if (total <= cap) return Float32List.fromList(found);

    final rng = math.Random();
    final keep = cap / total;
    final sampled = <double>[];
    for (var i = 0; i < total; i++) {
      if (rng.nextDouble() < keep) {
        sampled
          ..add(found[i * 2])
          ..add(found[i * 2 + 1]);
      }
    }
    return Float32List.fromList(sampled);
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Material(
      color: widget.backgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                if (reducedMotion) {
                  // No intro to wait for — unblock timed hosts right away.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _notifyIntroStarted(),
                  );
                  return Center(
                    child: Text(
                      widget.text,
                      style: _wordmarkStyle(size.width, widget.particleColor),
                    ),
                  );
                }
                if (size != _generatedFor) {
                  _generatedFor = size;
                  // Fire-and-forget; guarded by generation + mounted checks.
                  // ignore: discarded_futures
                  _generateParticles(size);
                }
                final field = _field;
                // Blank first frame while pixel sampling completes.
                if (field == null) return const SizedBox.expand();

                return RepaintBoundary(
                  child: CustomPaint(
                    isComplex: true,
                    painter: _ParticlePainter(
                      field: field,
                      elapsedMs: _elapsedMs,
                      color: widget.particleColor,
                    ),
                    size: size,
                  ),
                );
              },
            ),
          ),
          if (widget.title != null || widget.subtitle != null)
            Align(
              alignment: const Alignment(0, 0.6), // ~bottom 20%, as on web.
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: AppTypography.medium,
                          color: widget.particleColor.withValues(alpha: 0.65),
                        ),
                      ),
                    if (widget.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.particleColor.withValues(
                              alpha: 0.45,
                            ),
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

/// Flat, typed per-particle data (struct-of-arrays). Particles are grouped
/// into size x opacity buckets so the painter can batch them into a few
/// `drawRawPoints` calls.
class _ParticleField {
  _ParticleField._(this.count)
    : homeX = Float32List(count),
      homeY = Float32List(count),
      targetX = Float32List(count),
      targetY = Float32List(count),
      delay = Float32List(count),
      wobbleFreq = Float32List(count),
      wobblePhase = Float32List(count),
      bucket = Uint8List(count),
      // Worst case: every particle in one bucket.
      buffers = List.generate(bucketCount, (_) => Float32List(count * 2)),
      counts = Uint32List(bucketCount);

  factory _ParticleField.generate(Float32List targets, Size size) {
    final rng = math.Random();
    final count = targets.length ~/ 2;
    final field = _ParticleField._(count);
    final radiusBase = math.max(size.width, size.height);

    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = radiusBase * (0.3 + rng.nextDouble() * 0.5);
      field.homeX[i] = size.width / 2 + math.cos(angle) * dist;
      field.homeY[i] = size.height / 2 + math.sin(angle) * dist * 0.8;
      field.targetX[i] = targets[i * 2];
      field.targetY[i] = targets[i * 2 + 1];
      field.delay[i] = rng.nextDouble() * _staggerMs;
      field.wobbleFreq[i] = 0.0008 + rng.nextDouble() * 0.0008;
      field.wobblePhase[i] = rng.nextDouble() * math.pi * 2;
      // Web: 35% large (1.4px) dots, opacity 0.65-0.95 (quantized to 4
      // levels here so batching stays possible; the difference is invisible).
      final sizeBucket = rng.nextDouble() < 0.35 ? 1 : 0;
      final opacityBucket = rng.nextInt(_opacities.length);
      field.bucket[i] = sizeBucket * _opacities.length + opacityBucket;
    }
    return field;
  }

  static const _diameters = [1.8, 2.8]; // 0.9 / 1.4 px radii on web.
  static const _opacities = [0.65, 0.75, 0.85, 0.95];
  static final int bucketCount = _diameters.length * _opacities.length;

  static double diameterOf(int bucket) => _diameters[bucket ~/ 4];
  static double opacityOf(int bucket) => _opacities[bucket % 4];

  final int count;
  final Float32List homeX;
  final Float32List homeY;
  final Float32List targetX;
  final Float32List targetY;
  final Float32List delay;
  final Float32List wobbleFreq;
  final Float32List wobblePhase;
  final Uint8List bucket;

  /// Scratch buffers reused every frame (no per-frame allocation).
  final List<Float32List> buffers;
  final Uint32List counts;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.field,
    required this.elapsedMs,
    required this.color,
  }) : super(repaint: elapsedMs);

  static const double travelMs = 450;
  static const double convergeEndMs = travelMs + _staggerMs;

  final _ParticleField field;
  final ValueNotifier<double> elapsedMs;
  final Color color;

  static double _easeInOutCubic(double t) {
    final c = t.clamp(0.0, 1.0);
    return c < 0.5 ? 4 * c * c * c : 1 - math.pow(-2 * c + 2, 3) / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final now = elapsedMs.value;
    final converged = now >= convergeEndMs;
    field.counts.fillRange(0, field.counts.length, 0);

    for (var i = 0; i < field.count; i++) {
      double x;
      double y;
      if (converged) {
        // Hold with a subtle wobble so the wordmark stays alive however
        // long the load takes.
        final wobble = now * field.wobbleFreq[i] + field.wobblePhase[i];
        x = field.targetX[i] + math.sin(wobble) * 0.45;
        y = field.targetY[i] + math.cos(wobble) * 0.45;
      } else {
        final e = _easeInOutCubic((now - field.delay[i]) / travelMs);
        x = field.homeX[i] + (field.targetX[i] - field.homeX[i]) * e;
        y = field.homeY[i] + (field.targetY[i] - field.homeY[i]) * e;
      }
      final b = field.bucket[i];
      final n = field.counts[b];
      field.buffers[b][n * 2] = x;
      field.buffers[b][n * 2 + 1] = y;
      field.counts[b] = n + 1;
    }

    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var b = 0; b < _ParticleField.bucketCount; b++) {
      final n = field.counts[b];
      if (n == 0) continue;
      paint
        ..color = color.withValues(alpha: _ParticleField.opacityOf(b))
        ..strokeWidth = _ParticleField.diameterOf(b);
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(field.buffers[b], 0, n * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.field != field || oldDelegate.color != color;
}

/// Per-particle start-delay spread, shared by the field generator and painter.
const double _staggerMs = 140;
