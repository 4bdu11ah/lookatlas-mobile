import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';

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
  SwipeState build() => const SwipeState();

  void decide({required bool saved}) {
    if (state.isFinished) return;
    state = SwipeState(decisions: [...state.decisions, saved]);
  }

  void undo() {
    if (!state.canUndo) return;
    state = SwipeState(
      decisions: state.decisions.sublist(0, state.decisions.length - 1),
    );
  }

  void reset() => state = const SwipeState();
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
    for (var i = 0; i < decisions.length; i++)
      if (decisions[i]) images[i],
  ];
});

/// Images the user passed on, in deck order.
final passedImagesProvider = Provider<List<GeneratedImage>>((ref) {
  final images = ref.watch(generationControllerProvider).images;
  final decisions = ref.watch(swipeControllerProvider).decisions;
  return [
    for (var i = 0; i < decisions.length; i++)
      if (!decisions[i]) images[i],
  ];
});
