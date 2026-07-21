import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
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
  bool get isComplete =>
      jobStatus == 'completed' ||
      (jobStatus == null && started && readyCount == images.length);
  bool get isTerminal => isComplete || jobStatus == 'failed';

  /// Rough time remaining, matching the mockup's "~N minutes remaining".
  int get etaMinutes {
    final remaining = images.length - readyCount;
    return (remaining / 4).ceil().clamp(1, 5);
  }

  List<GeneratedImage> imagesForShot(int shot) =>
      images.where((i) => i.shot == shot).toList();
}

/// Polls the authenticated onboarding job. Anonymous preview routes retain a
/// deterministic simulation so the public funnel remains demonstrable.
class GenerationController extends Notifier<GenerationState> {
  /// How often the next simulated image completes.
  static const interval = Duration(milliseconds: 900);
  static const pollInterval = Duration(seconds: 10);

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
    if (ref.read(authRepositoryProvider).currentUser != null) {
      unawaited(_poll());
      return;
    }
    _timer = Timer.periodic(interval, (_) => _completeNext());
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
    required bool terminalFailure,
  }) {
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
      for (var shot = 1; shot <= freeShootShotCount; shot++)
        for (
          var variation = 1;
          variation <= freeShootVariationsPerShot;
          variation++
        )
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
