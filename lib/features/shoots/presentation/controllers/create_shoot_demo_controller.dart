part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

mixin _CreateShootDemoController on Notifier<_CreateShootState> {
  bool get _createInFlight;
  set _createInFlight(bool value);
  bool get _disposed;
  ShootsRepository get _repository;

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
    final failedDirectors = <String>[];
    String? firstJobId;
    var createdCount = 0;
    try {
      for (final config in state.demoDirectors) {
        final director = state.directors.firstWhere(
          (item) => item.id == config.directorId,
        );
        final selection = _demoSelection(config);
        final planned = await _repository.planShots(selection);
        if (planned case Err()) {
          failedDirectors.add(director.name);
          continue;
        }
        final created = await _repository.createShoot(
          CreateShootRequest(
            selection: selection,
            shots: planned.valueOrNull!.take(config.numberOfShots).toList(),
            demoGroupId: demoGroupId,
          ),
        );
        if (created case Err()) {
          failedDirectors.add(director.name);
          continue;
        }
        firstJobId ??= created.valueOrNull!;
        createdCount++;
      }
    } finally {
      _createInFlight = false;
    }
    if (_disposed) {
      return firstJobId == null
          ? const Err(UnknownFailure('Demo creation failed.'))
          : Ok(firstJobId);
    }
    if (failedDirectors.isNotEmpty) {
      final failure = UnknownFailure(
        'Created $createdCount demo '
        '${createdCount == 1 ? 'shoot' : 'shoots'}. Failed: '
        '${failedDirectors.join(', ')}.',
      );
      state = state.copyWith(isSubmitting: false, failure: failure);
      return Err(failure);
    }
    state = state.copyWith(isSubmitting: false, clearFailure: true);
    return Ok(firstJobId!);
  }

  ShootSelection _demoSelection(DemoDirectorConfig config) => ShootSelection(
    products: state.selectedProducts,
    models: state.selectedModels,
    productMode: state.productMode,
    settings: state.settings.copyWith(
      directorId: config.directorId,
      numberOfShots: config.numberOfShots,
      variations: config.variations,
      imageSize: '2K',
      lane: ShootLane.fast,
      stylingNotes: const {},
    ),
  );
}
