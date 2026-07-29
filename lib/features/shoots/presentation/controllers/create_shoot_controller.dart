part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CreateShootState {
  const _CreateShootState({
    this.step = _CreateStep.product,
    this.catalog,
    this.selectedProduct = 0,
    this.selectedModel = 0,
    this.selectedDirector = 0,
    this.useLibraryModels = false,
    this.settings = const ShootSettings(),
    this.plannedShots = const [],
    this.selectedShots = const {},
    this.isLoading = true,
    this.isPlanning = false,
    this.isSubmitting = false,
    this.failure,
  });

  final _CreateStep step;
  final ShootCreateCatalog? catalog;
  final int selectedProduct;
  final int selectedModel;
  final int selectedDirector;
  final bool useLibraryModels;
  final ShootSettings settings;
  final List<PlannedShootShot> plannedShots;
  final Set<int> selectedShots;
  final bool isLoading;
  final bool isPlanning;
  final bool isSubmitting;
  final Failure? failure;

  List<ShootCatalogItem> get products => catalog?.products ?? const [];

  List<ShootCatalogItem> get models => useLibraryModels
      ? catalog?.libraryModels ?? const []
      : catalog?.userModels ?? const [];

  List<ShootLook> get directors => catalog?.looks ?? const [];

  bool get isPlanned => plannedShots.isNotEmpty;

  ShootSelection? get selection {
    if (products.isEmpty || models.isEmpty) return null;
    final directorId = directors.isEmpty
        ? settings.directorId
        : directors[selectedDirector.clamp(0, directors.length - 1)].id;
    return ShootSelection(
      product: products[selectedProduct.clamp(0, products.length - 1)],
      model: models[selectedModel.clamp(0, models.length - 1)],
      settings: settings.copyWith(directorId: directorId),
    );
  }

  List<PlannedShootShot> get chosenShots => [
    for (final (index, shot) in plannedShots.indexed)
      if (selectedShots.contains(index)) shot,
  ];

  _CreateShootState copyWith({
    _CreateStep? step,
    ShootCreateCatalog? catalog,
    int? selectedProduct,
    int? selectedModel,
    int? selectedDirector,
    bool? useLibraryModels,
    ShootSettings? settings,
    List<PlannedShootShot>? plannedShots,
    Set<int>? selectedShots,
    bool? isLoading,
    bool? isPlanning,
    bool? isSubmitting,
    Failure? failure,
    bool clearFailure = false,
  }) => _CreateShootState(
    step: step ?? this.step,
    catalog: catalog ?? this.catalog,
    selectedProduct: selectedProduct ?? this.selectedProduct,
    selectedModel: selectedModel ?? this.selectedModel,
    selectedDirector: selectedDirector ?? this.selectedDirector,
    useLibraryModels: useLibraryModels ?? this.useLibraryModels,
    settings: settings ?? this.settings,
    plannedShots: plannedShots ?? this.plannedShots,
    selectedShots: selectedShots ?? this.selectedShots,
    isLoading: isLoading ?? this.isLoading,
    isPlanning: isPlanning ?? this.isPlanning,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class _CreateShootController extends Notifier<_CreateShootState> {
  bool _disposed = false;

  ShootsRepository get _repository => ref.read(shootsRepositoryProvider);

  @override
  _CreateShootState build() {
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(load));
    return const _CreateShootState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.loadCreateCatalog();
    if (_disposed) return;
    if (result case Err(:final failure)) {
      state = state.copyWith(isLoading: false, failure: failure);
      return;
    }
    final catalog = result.valueOrNull!;
    state = state.copyWith(
      catalog: catalog,
      useLibraryModels:
          catalog.userModels.isEmpty && catalog.libraryModels.isNotEmpty,
      isLoading: false,
      clearFailure: true,
    );
  }

  void setStep(_CreateStep step) => state = state.copyWith(step: step);

  void selectProduct(int index) {
    state = state.copyWith(
      selectedProduct: index,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void selectModel(int index) {
    state = state.copyWith(
      selectedModel: index,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void setModelSource({required bool useLibraryModels}) {
    state = state.copyWith(
      useLibraryModels: useLibraryModels,
      selectedModel: 0,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void selectDirector(int index) {
    state = state.copyWith(
      selectedDirector: index,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void updateSettings(ShootSettings settings) {
    state = state.copyWith(
      settings: settings,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  Future<Failure?> planShots() async {
    final selection = state.selection;
    if (selection == null) {
      return const UnknownFailure('Select a product and model first.');
    }
    state = state.copyWith(isPlanning: true, clearFailure: true);
    final result = await _repository.planShots(selection);
    if (_disposed) return null;
    if (result case Err(:final failure)) {
      state = state.copyWith(isPlanning: false, failure: failure);
      return failure;
    }
    final shots = result.valueOrNull!;
    state = state.copyWith(
      plannedShots: shots,
      selectedShots: Set<int>.from(
        Iterable<int>.generate(shots.length),
      ),
      isPlanning: false,
      clearFailure: true,
    );
    return null;
  }

  Future<Failure?> addCustomShot({
    required String shotIdea,
    required String poseDirection,
    required String focusArea,
  }) async {
    final selection = state.selection;
    if (selection == null) {
      return const UnknownFailure('Select a product and model first.');
    }
    final result = await _repository.createCustomShot(
      CustomShootShotRequest(
        selection: selection,
        shotIdea: shotIdea,
        poseDirection: poseDirection,
        focusArea: focusArea,
        existingShots: state.plannedShots,
      ),
    );
    if (_disposed) return null;
    if (result case Err(:final failure)) return failure;
    final shots = [...state.plannedShots, result.valueOrNull!];
    state = state.copyWith(
      plannedShots: shots,
      selectedShots: {...state.selectedShots, shots.length - 1},
    );
    return null;
  }

  void toggleShot(int index) {
    final selected = {...state.selectedShots};
    selected.contains(index) ? selected.remove(index) : selected.add(index);
    state = state.copyWith(selectedShots: selected);
  }

  Future<Result<String>> createShoot() async {
    final selection = state.selection;
    if (selection == null || state.chosenShots.isEmpty) {
      return const Err(
        UnknownFailure('Select a product, model, and at least one shot.'),
      );
    }
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    final result = await _repository.createShoot(
      CreateShootRequest(selection: selection, shots: state.chosenShots),
    );
    if (_disposed) return result;
    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      clearFailure: result.isOk,
    );
    return result;
  }

  void reset() {
    state = _CreateShootState(catalog: state.catalog, isLoading: false);
  }
}

final NotifierProvider<_CreateShootController, _CreateShootState>
_createShootControllerProvider =
    NotifierProvider.autoDispose<_CreateShootController, _CreateShootState>(
      _CreateShootController.new,
    );
