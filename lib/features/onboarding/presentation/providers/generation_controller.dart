import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';

/// One of the 15 photos of the free shoot (3 shots x 5 variations).
@immutable
class GeneratedImage {
  const GeneratedImage({
    required this.shot,
    required this.variation,
    required this.url,
    required this.isReady,
  });

  /// 1-based shot number (1..3).
  final int shot;

  /// 1-based variation number within the shot (1..5).
  final int variation;
  final String url;
  final bool isReady;

  GeneratedImage copyWith({bool? isReady}) => GeneratedImage(
    shot: shot,
    variation: variation,
    url: url,
    isReady: isReady ?? this.isReady,
  );
}

/// Progress of the simulated free shoot.
@immutable
class GenerationState {
  const GenerationState({required this.images, required this.started});

  /// All 15 slots in generation order, pending until [GeneratedImage.isReady].
  final List<GeneratedImage> images;
  final bool started;

  int get readyCount => images.where((i) => i.isReady).length;
  bool get isComplete => started && readyCount == images.length;

  /// Rough time remaining, matching the mockup's "~N minutes remaining".
  int get etaMinutes {
    final remaining = images.length - readyCount;
    return (remaining / 4).ceil().clamp(1, 5);
  }

  List<GeneratedImage> imagesForShot(int shot) =>
      images.where((i) => i.shot == shot).toList();
}

/// Simulates the backend photo shoot: once started, one image finishes every
/// [GenerationController.interval] until all 15 are ready. Swipe, results and
/// paywall screens all read from this state.
class GenerationController extends Notifier<GenerationState> {
  /// How often the next simulated image completes.
  static const interval = Duration(milliseconds: 900);

  Timer? _timer;

  @override
  GenerationState build() {
    ref.onDispose(_stopTimer);
    return GenerationState(images: _freshSlots(), started: false);
  }

  static List<GeneratedImage> _freshSlots() => [
    for (var shot = 1; shot <= freeShootShotCount; shot++)
      for (var v = 1; v <= freeShootVariationsPerShot; v++)
        GeneratedImage(
          shot: shot,
          variation: v,
          url: 'https://picsum.photos/seed/la-gen-$shot-$v/720/900',
          isReady: false,
        ),
  ];

  /// Kicks off (or restarts) the simulated shoot.
  void start() {
    _stopTimer();
    state = GenerationState(images: _freshSlots(), started: true);
    _timer = Timer.periodic(interval, (_) => _completeNext());
  }

  void _completeNext() {
    final i = state.images.indexWhere((img) => !img.isReady);
    if (i < 0) {
      _stopTimer();
      return;
    }
    final images = [...state.images];
    images[i] = images[i].copyWith(isReady: true);
    state = GenerationState(images: images, started: true);
    if (images.every((img) => img.isReady)) _stopTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Back to a clean, unstarted shoot.
  void reset() {
    _stopTimer();
    state = GenerationState(images: _freshSlots(), started: false);
  }
}

/// The simulated free-shoot generation shared across onboarding screens.
final generationControllerProvider =
    NotifierProvider<GenerationController, GenerationState>(
      GenerationController.new,
    );
