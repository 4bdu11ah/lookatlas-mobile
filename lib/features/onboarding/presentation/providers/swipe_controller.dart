import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:look_atlas/services/service_providers.dart';

/// Save/skip decisions over the 15-card deck. The card being shown is always
/// `decisions.length` (cards are decided strictly in order, undo pops).
@immutable
class SwipeState {
  const SwipeState({this.decisions = const []});

  /// One entry per swiped card, true = saved, in deck order.
  final List<bool> decisions;

  /// Index of the card currently on top of the deck.
  int get currentIndex => decisions.length;

  int get savedCount => decisions.where((saved) => saved).length;
  int get passedCount => decisions.length - savedCount;
  bool get isFinished => decisions.length >= freeShootImageCount;
  bool get canUndo => decisions.isNotEmpty;

  /// Percentage of swiped cards that were saved (the results "match rate").
  int get matchRatePercent =>
      decisions.isEmpty ? 0 : (savedCount / decisions.length * 100).round();
}

/// Tracks the swipe deck. Reads the deck itself from
/// [generationControllerProvider]; this only owns the decisions.
class SwipeController extends Notifier<SwipeState> {
  @override
  SwipeState build() {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return const SwipeState();
    final store = ref.read(keyValueStoreProvider);
    final swiped = store.getStringList(_key('swiped_urls', userId)) ?? const [];
    final saved = (store.getStringList(_key('saved', userId)) ?? const [])
        .toSet();
    return SwipeState(
      decisions: [for (final key in swiped) saved.contains(key)],
    );
  }

  void decide({required bool saved}) {
    if (state.isFinished) return;
    state = SwipeState(decisions: [...state.decisions, saved]);
    _persist();
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            saved ? 'swipe.right' : 'swipe.left',
            properties: {'image_key': _currentIdentity()},
          ),
    );
    final generation = ref.read(generationControllerProvider);
    if (generation.isTerminal && state.currentIndex >= generation.readyCount) {
      unawaited(
        ref.read(analyticsServiceProvider).track('swipe.all_swiped'),
      );
    }
  }

  void undo() {
    if (!state.canUndo) return;
    state = SwipeState(
      decisions: state.decisions.sublist(0, state.decisions.length - 1),
    );
    _persist();
    unawaited(ref.read(analyticsServiceProvider).track('swipe.undo'));
  }

  void reset() {
    state = const SwipeState();
    _persist();
  }

  void _persist() {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    final images = ref.read(generationControllerProvider).images;
    final decidedCount = state.decisions.length.clamp(0, images.length);
    final keys = [
      for (var i = 0; i < decidedCount; i++) _identity(images[i]),
    ];
    final saved = [
      for (var i = 0; i < decidedCount; i++)
        if (state.decisions[i]) keys[i],
    ];
    final passed = [
      for (var i = 0; i < decidedCount; i++)
        if (!state.decisions[i]) keys[i],
    ];
    final store = ref.read(keyValueStoreProvider);
    unawaited(store.setStringList(_key('saved', userId), saved));
    unawaited(store.setStringList(_key('passed', userId), passed));
    unawaited(store.setStringList(_key('swiped_urls', userId), keys));
    final generation = ref.read(generationControllerProvider);
    if (state.isFinished ||
        (generation.isTerminal &&
            state.currentIndex >= generation.readyCount)) {
      unawaited(
        store.setBool(_key('collection_reached', userId), value: true),
      );
    }
  }

  static String _identity(GeneratedImage image) =>
      '${image.shot - 1}:${image.variation}';

  String _currentIdentity() {
    final images = ref.read(generationControllerProvider).images;
    final index = state.currentIndex - 1;
    return index >= 0 && index < images.length ? _identity(images[index]) : '';
  }

  static String _key(String suffix, String userId) =>
      'onboarding_swipe_${suffix}_$userId';
}

/// Save/skip decisions for the current free shoot.
final swipeControllerProvider = NotifierProvider<SwipeController, SwipeState>(
  SwipeController.new,
);

/// Images the user saved, in deck order.
final savedImagesProvider = Provider<List<GeneratedImage>>((ref) {
  final images = ref.watch(generationControllerProvider).images;
  final decisions = ref.watch(swipeControllerProvider).decisions;
  return [
    for (var i = 0; i < decisions.length && i < images.length; i++)
      if (decisions[i]) images[i],
  ];
});

/// Images the user passed on, in deck order.
final passedImagesProvider = Provider<List<GeneratedImage>>((ref) {
  final images = ref.watch(generationControllerProvider).images;
  final decisions = ref.watch(swipeControllerProvider).decisions;
  return [
    for (var i = 0; i < decisions.length && i < images.length; i++)
      if (!decisions[i]) images[i],
  ];
});
