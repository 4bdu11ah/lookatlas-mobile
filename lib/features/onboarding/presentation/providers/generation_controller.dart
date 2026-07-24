import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';

/// One generated photo. Dimensions come from the live start-shoot response.
@immutable
class GeneratedImage {
  const GeneratedImage({
    required this.shot,
    required this.variation,
    required this.url,
    required this.isReady,
  });

  /// 1-based shot number.
  final int shot;

  /// 1-based variation number within the shot.
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
  const GenerationState({
    required this.images,
    required this.started,
    this.jobStatus,
    this.failure,
    this.shouldOpenPlans = false,
  });

  /// All 15 slots in generation order, pending until [GeneratedImage.isReady].
  final List<GeneratedImage> images;
  final bool started;
  final String? jobStatus;
  final Failure? failure;
  final bool shouldOpenPlans;

  int get readyCount => images.where((i) => i.isReady).length;
  int get shotCount => images.fold<int>(
    0,
    (largest, image) => image.shot > largest ? image.shot : largest,
  );
  bool get isComplete =>
      started && images.isNotEmpty && readyCount == images.length;
  bool get isTerminal => isComplete || jobStatus == 'failed';

  /// Rough time remaining, matching the mockup's "~N minutes remaining".
  int get etaMinutes {
    final remaining = images.length - readyCount;
    return (remaining / 4).ceil().clamp(1, 5);
  }

  List<GeneratedImage> imagesForShot(int shot) =>
      images.where((i) => i.shot == shot).toList();
}

/// Polls the onboarding job until every generated image is available.
class GenerationController extends Notifier<GenerationState> {
  static const pollInterval = Duration(seconds: 5);

  Timer? _timer;
  int _shotCount = freeShootShotCount;
  int _variations = freeShootVariationsPerShot;
  int _expectedTotal = freeShootImageCount;

  @override
  GenerationState build() {
    ref.onDispose(_stopTimer);
    return GenerationState(
      images: _freshSlots(_shotCount, _variations),
      started: false,
    );
  }

  static List<GeneratedImage> _freshSlots(int shotCount, int variations) => [
    for (var shot = 1; shot <= shotCount; shot++)
      for (var v = 1; v <= variations; v++)
        GeneratedImage(
          shot: shot,
          variation: v,
          url: 'https://picsum.photos/seed/la-gen-$shot-$v/720/900',
          isReady: false,
        ),
  ];

  void start({StartShootResponse? shoot}) {
    _stopTimer();
    if (shoot != null) {
      _shotCount = shoot.shotCount > 0 ? shoot.shotCount : _shotCount;
      _variations = shoot.variations > 0 ? shoot.variations : _variations;
      _expectedTotal = shoot.totalImages > 0
          ? shoot.totalImages
          : _shotCount * _variations;
    }
    state = GenerationState(
      images: _freshSlots(_shotCount, _variations),
      started: true,
    );
    unawaited(_poll());
  }

  Future<void> _poll() async {
    final result = await ref.read(getOnboardingStatusUseCaseProvider)();
    if (result.failureOrNull case final failure?) {
      state = GenerationState(
        images: state.images,
        started: true,
        failure: failure,
      );
      _schedulePoll();
      return;
    }
    final status = result.valueOrNull!;
    final jobStatus = _normalizedStatus(status);
    state = GenerationState(
      images: _mergeImages(
        status.onboardingImages,
        completed: jobStatus == 'completed',
        terminalFailure: jobStatus == 'failed',
      ),
      started: true,
      jobStatus: jobStatus,
      shouldOpenPlans: status.freeShootUsed && status.onboardingJob == null,
    );
    if (!state.isTerminal && !state.shouldOpenPlans) _schedulePoll();
  }

  void _schedulePoll() {
    _stopTimer();
    _timer = Timer(pollInterval, () => unawaited(_poll()));
  }

  List<GeneratedImage> _mergeImages(
    List<OnboardingImage> incoming, {
    required bool completed,
    required bool terminalFailure,
  }) {
    if (completed && incoming.length == _expectedTotal) {
      final inferredShots = incoming.fold<int>(
        0,
        (largest, image) =>
            image.shotIndex + 1 > largest ? image.shotIndex + 1 : largest,
      );
      final inferredVariations = incoming.fold<int>(
        0,
        (largest, image) =>
            image.variation > largest ? image.variation : largest,
      );
      if (inferredShots * inferredVariations == _expectedTotal) {
        _shotCount = inferredShots;
        _variations = inferredVariations;
      }
    }
    final byIdentity = {
      for (final image in state.images)
        '${image.shot - 1}:${image.variation}': image,
    };
    for (final image in incoming) {
      if (image.url.isEmpty || image.variation < 1) continue;
      byIdentity[image.identity] = GeneratedImage(
        shot: image.shotIndex + 1,
        variation: image.variation,
        url: image.url,
        isReady: true,
      );
    }
    final merged = [
      for (var shot = 1; shot <= _shotCount; shot++)
        for (var variation = 1; variation <= _variations; variation++)
          byIdentity['${shot - 1}:$variation'] ??
              GeneratedImage(
                shot: shot,
                variation: variation,
                url: '',
                isReady: false,
              ),
    ];
    return terminalFailure
        ? merged.where((image) => image.isReady).toList()
        : merged;
  }

  static String _normalizedStatus(OnboardingStatus status) {
    final value = status.onboardingJobStatus ?? status.onboardingJob?.status;
    return value?.toLowerCase() ?? 'pending';
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Back to a clean, unstarted shoot.
  void reset() {
    _stopTimer();
    _shotCount = freeShootShotCount;
    _variations = freeShootVariationsPerShot;
    _expectedTotal = freeShootImageCount;
    state = GenerationState(
      images: _freshSlots(_shotCount, _variations),
      started: false,
    );
  }
}

/// The simulated free-shoot generation shared across onboarding screens.
final generationControllerProvider =
    NotifierProvider<GenerationController, GenerationState>(
      GenerationController.new,
    );
