part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CreateShootState {
  const _CreateShootState({
    this.step = _CreateStep.product,
    this.previewAssets = _createShootPreviewAssets,
    this.selectedProduct = 0,
    this.selectedModel = 0,
    this.selectedDirector = 0,
    this.isPlanned = false,
    this.selectedShots = const {0, 1, 2, 3, 4},
  });

  final _CreateStep step;
  final List<String> previewAssets;
  final int selectedProduct;
  final int selectedModel;
  final int selectedDirector;
  final bool isPlanned;
  final Set<int> selectedShots;

  _CreateShootState copyWith({
    _CreateStep? step,
    int? selectedProduct,
    int? selectedModel,
    int? selectedDirector,
    bool? isPlanned,
    Set<int>? selectedShots,
  }) {
    return _CreateShootState(
      step: step ?? this.step,
      previewAssets: previewAssets,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      selectedModel: selectedModel ?? this.selectedModel,
      selectedDirector: selectedDirector ?? this.selectedDirector,
      isPlanned: isPlanned ?? this.isPlanned,
      selectedShots: selectedShots ?? this.selectedShots,
    );
  }
}

class _CreateShootController extends Notifier<_CreateShootState> {
  @override
  _CreateShootState build() => const _CreateShootState();

  void setStep(_CreateStep step) {
    state = state.copyWith(step: step);
  }

  void selectProduct(int index) {
    state = state.copyWith(selectedProduct: index);
  }

  void selectModel(int index) {
    state = state.copyWith(selectedModel: index);
  }

  void selectDirector(int index) {
    state = state.copyWith(selectedDirector: index);
  }

  void planShots() {
    state = state.copyWith(isPlanned: true);
  }

  void toggleShot(int index) {
    final selected = {...state.selectedShots};
    selected.contains(index) ? selected.remove(index) : selected.add(index);
    state = state.copyWith(selectedShots: selected);
  }

  void reset() {
    state = const _CreateShootState();
  }
}

final _createShootControllerProvider =
    NotifierProvider<_CreateShootController, _CreateShootState>(
      _CreateShootController.new,
    );
