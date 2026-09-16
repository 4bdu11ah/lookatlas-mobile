import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/dashboard/presentation/models/campaign_shot.dart';

class CampaignSelectionState {
  const CampaignSelectionState({
    this.overrides = const {},
    this.inflight = const {},
  });
  final Map<String, bool> overrides;
  final Set<String> inflight;
}

class CampaignSelectionController extends Notifier<CampaignSelectionState> {
  CampaignSelectionController(this.jobId);
  final String jobId;
  @override
  CampaignSelectionState build() => const CampaignSelectionState();

  Future<Failure?> toggle(
    CampaignShot shot,
    List<CampaignShot> images,
    ToggleCampaignShot save,
  ) async {
    if (state.inflight.contains(shot.id)) return null;
    final previous = state.overrides[shot.id] ?? shot.approved;
    final keptCount = images
        .where((image) => state.overrides[image.id] ?? image.approved)
        .length;
    if (!previous && keptCount >= 3) {
      return const ValidationFailure('Pick up to 3 heroes.');
    }
    state = CampaignSelectionState(
      overrides: {...state.overrides, shot.id: !previous},
      inflight: {...state.inflight, shot.id},
    );
    Failure? failure;
    try {
      failure = await save(shot, approved: !previous);
    } on Object {
      failure = const NetworkFailure('Could not save your selection.');
    }
    if (!ref.mounted) return failure;
    state = CampaignSelectionState(
      overrides: {...state.overrides, if (failure != null) shot.id: previous},
      inflight: {...state.inflight}..remove(shot.id),
    );
    return failure;
  }
}

// Riverpod infers the family provider type from the factory.
// ignore: specify_nonobvious_property_types
final campaignSelectionControllerProvider = NotifierProvider.autoDispose
    .family<CampaignSelectionController, CampaignSelectionState, String>(
      CampaignSelectionController.new,
    );
