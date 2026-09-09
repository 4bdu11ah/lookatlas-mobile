part of '../shoots_feature.dart';

mixin _CreateShootDemoController on Notifier<_CreateShootState> {
  bool get _createInFlight;
  set _createInFlight(bool value);
  bool get _disposed;

  void setDemoMode({required bool enabled}) {
    state = state.copyWith(
      demoMode: enabled,
      step: state.step == _CreateStep.planning
          ? _CreateStep.director
          : state.step,
      settings: state.settings.copyWith(
        imageSize: '2K',
        lane: enabled
            ? ShootLane.fast
            : state.canUseUnlimited
            ? ShootLane.relax
            : ShootLane.fast,
      ),
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void toggleDemoDirector(int index) {
    if (index < 0 || index >= state.directors.length) return;
    final directorId = state.directors[index].id;
    final configs = [...state.demoDirectors];
    final existing = configs.indexWhere(
      (config) => config.directorId == directorId,
    );
    if (existing >= 0) {
      configs.removeAt(existing);
    } else {
      configs.add(DemoDirectorConfig(directorId: directorId));
    }
    state = state.copyWith(demoDirectors: configs);
  }

  void updateDemoDirector(DemoDirectorConfig updated) {
    final cap = updated.directorId == 'fine-jewelry' ? 7 : 8;
    state = state.copyWith(
      demoDirectors: [
        for (final config in state.demoDirectors)
          if (config.directorId == updated.directorId)
            updated.copyWith(
              numberOfShots: updated.numberOfShots.clamp(1, cap),
              variations: updated.variations.clamp(1, 5),
            )
          else
            config,
      ],
    );
  }

  Future<Result<String>> createDemoShoot() async {
    if (_createInFlight) {
      return const Err(ValidationFailure('Shoot creation is already running.'));
    }
    if (!state.demoMode || !state.canContinueFromDirector) {
      return const Err(ValidationFailure('Select at least one director.'));
    }
    if (!state.canGenerateDemo) {
      return const Err(ValidationFailure('Not enough credits for this demo.'));
    }
    if (state.selectedProducts.isEmpty || state.selectedModels.isEmpty) {
      return const Err(ValidationFailure('Select a product and model first.'));
    }
    _createInFlight = true;
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    final demoGroupId = _newDemoGroupId();
    late final DemoShootOutcome outcome;
    try {
      outcome = await ref.read(createDemoShootsUseCaseProvider)(
        directors: [
          for (final config in state.demoDirectors)
            DemoShootDirector(
              name: state.directors
                  .firstWhere((item) => item.id == config.directorId)
                  .name,
              config: config,
            ),
        ],
        products: state.selectedProducts,
        models: state.selectedModels,
        productMode: state.productMode,
        settings: state.settings,
        demoGroupId: demoGroupId,
      );
    } finally {
      _createInFlight = false;
    }
    if (_disposed) {
      return outcome.firstJobId == null
          ? const Err(UnknownFailure('Demo creation failed.'))
          : Ok(outcome.firstJobId!);
    }
    if (outcome.failedDirectors.isNotEmpty) {
      final failure = UnknownFailure(
        'Created ${outcome.createdCount} demo '
        '${outcome.createdCount == 1 ? 'shoot' : 'shoots'}. Failed: '
        '${outcome.failedDirectors.join(', ')}.',
      );
      state = state.copyWith(isSubmitting: false, failure: failure);
      return Err(failure);
    }
    state = state.copyWith(isSubmitting: false, clearFailure: true);
    return Ok(outcome.firstJobId!);
  }
}
