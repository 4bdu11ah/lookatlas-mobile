part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CreateShootState {
  const _CreateShootState({
    this.step = _CreateStep.product,
    this.previewAssets = _createShootPreviewAssets,
  });

  final _CreateStep step;
  final List<String> previewAssets;

  _CreateShootState copyWith({_CreateStep? step}) {
    return _CreateShootState(
      step: step ?? this.step,
      previewAssets: previewAssets,
    );
  }
}

class _CreateShootController extends Notifier<_CreateShootState> {
  @override
  _CreateShootState build() => const _CreateShootState();

  void setStep(_CreateStep step) {
    state = state.copyWith(step: step);
  }
}

final _createShootControllerProvider =
    NotifierProvider<_CreateShootController, _CreateShootState>(
      _CreateShootController.new,
    );
