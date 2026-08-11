part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CreateShootState {
  const _CreateShootState({
    this.step = _CreateStep.product,
    this.catalog,
    this.productMode = ProductMode.pairing,
    this.selectedProductIds = const [],
    this.selectedModelKeys = const [],
    this.selectedDirector = 0,
    this.useLibraryModels = false,
    this.settings = const ShootSettings(),
    this.plannedShots = const [],
    this.selectedShots = const {},
    this.isLoading = true,
    this.isPlanning = false,
    this.isSubmitting = false,
    this.isAdmin = false,
    this.isDemo = false,
    this.selectedDirectorIds = const [],
    this.demoConfigs = const {},
    this.failure,
  });

  final _CreateStep step;
  final ShootCreateCatalog? catalog;
  final ProductMode productMode;
  final List<String> selectedProductIds;
  final List<String> selectedModelKeys;
  final int selectedDirector;
  final bool useLibraryModels;
  final ShootSettings settings;
  final List<PlannedShootShot> plannedShots;
  final Set<int> selectedShots;
  final bool isLoading;
  final bool isPlanning;
  final bool isSubmitting;
  final bool isAdmin;
  final bool isDemo;
  final List<String> selectedDirectorIds;
  final Map<String, DemoDirectorConfig> demoConfigs;
  final Failure? failure;

  List<ShootCatalogItem> get products => catalog?.products ?? const [];

  List<ShootCatalogItem> get models => useLibraryModels
      ? catalog?.libraryModels ?? const []
      : catalog?.userModels ?? const [];

  List<ShootCatalogItem> get selectedProducts => [
    for (final id in selectedProductIds)
      ...products.where((product) => product.id == id),
  ];

  List<ShootCatalogItem> get selectedModels {
    final allModels = [
      ...?catalog?.userModels,
      ...?catalog?.libraryModels,
    ];
    return [
      for (final key in selectedModelKeys)
        ...allModels.where((model) => _modelKey(model) == key),
    ];
  }

  List<ShootLook> get directors => catalog?.looks ?? const [];

  bool get isPlanned => plannedShots.isNotEmpty;

  ShootSelection? get selection {
    if (selectedProducts.isEmpty || selectedModels.isEmpty) return null;
    final directorId = directors.isEmpty
        ? settings.directorId
        : directors[selectedDirector.clamp(0, directors.length - 1)].id;
    return ShootSelection(
      products: selectedProducts,
      models: selectedModels,
      productMode: productMode,
      settings: settings.copyWith(directorId: directorId),
    );
  }

  List<PlannedShootShot> get chosenShots => [
    for (final (index, shot) in plannedShots.indexed)
      if (selectedShots.contains(index)) shot,
  ];

  int get totalImages =>
      isDemo ? demoTotalImages : chosenShots.length * settings.variations;

  int get requiredCredits =>
      totalImages *
      (isDemo
          ? 2
          : switch (settings.imageSize) {
              '4K' => 3,
              '2K' => 2,
              _ => 1,
            });

  bool get canUseUnlimited => catalog?.isUnlimitedEligible ?? false;

  bool get needsPrimaryProductSubCategory {
    final product = selection?.product;
    return product?.category?.toLowerCase() == 'bags' &&
        (product?.subCategory?.trim().isEmpty ?? true);
  }

  bool get canGenerate =>
      (isDemo ? selectedDirectorIds.isNotEmpty : chosenShots.isNotEmpty) &&
      (settings.lane == ShootLane.relax ||
          requiredCredits <= (catalog?.availableCredits ?? 0));

  List<_CreateStep> get steps => isDemo
      ? const [
          _CreateStep.product,
          _CreateStep.model,
          _CreateStep.director,
          _CreateStep.confirm,
        ]
      : _CreateStep.values;

  int get demoTotalImages => selectedDirectorIds.fold(
    0,
    (total, id) {
      final config = demoConfigs[id] ?? const DemoDirectorConfig();
      return total + config.numberOfShots * config.variations;
    },
  );

  _CreateShootState copyWith({
    _CreateStep? step,
    ShootCreateCatalog? catalog,
    ProductMode? productMode,
    List<String>? selectedProductIds,
    List<String>? selectedModelKeys,
    int? selectedDirector,
    bool? useLibraryModels,
    ShootSettings? settings,
    List<PlannedShootShot>? plannedShots,
    Set<int>? selectedShots,
    bool? isLoading,
    bool? isPlanning,
    bool? isSubmitting,
    bool? isAdmin,
    bool? isDemo,
    List<String>? selectedDirectorIds,
    Map<String, DemoDirectorConfig>? demoConfigs,
    Failure? failure,
    bool clearFailure = false,
  }) => _CreateShootState(
    step: step ?? this.step,
    catalog: catalog ?? this.catalog,
    productMode: productMode ?? this.productMode,
    selectedProductIds: selectedProductIds ?? this.selectedProductIds,
    selectedModelKeys: selectedModelKeys ?? this.selectedModelKeys,
    selectedDirector: selectedDirector ?? this.selectedDirector,
    useLibraryModels: useLibraryModels ?? this.useLibraryModels,
    settings: settings ?? this.settings,
    plannedShots: plannedShots ?? this.plannedShots,
    selectedShots: selectedShots ?? this.selectedShots,
    isLoading: isLoading ?? this.isLoading,
    isPlanning: isPlanning ?? this.isPlanning,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isAdmin: isAdmin ?? this.isAdmin,
    isDemo: isDemo ?? this.isDemo,
    selectedDirectorIds: selectedDirectorIds ?? this.selectedDirectorIds,
    demoConfigs: demoConfigs ?? this.demoConfigs,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class _CreateShootController extends Notifier<_CreateShootState> {
  bool _disposed = false;
  bool _createInFlight = false;

  ShootsRepository get _repository => ref.read(shootsRepositoryProvider);

  @override
  _CreateShootState build() {
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(load));
    final user = ref.read(authRepositoryProvider).currentUser;
    return _CreateShootState(isAdmin: user?.isAdmin ?? false);
  }

  Future<void> load({
    String? preferredProductId,
    String? preferredModelName,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.loadCreateCatalog();
    if (_disposed) return;
    if (result case Err(:final failure)) {
      state = state.copyWith(isLoading: false, failure: failure);
      return;
    }
    final catalog = result.valueOrNull!;
    final preferredModel = _findModel(catalog.userModels, preferredModelName);
    state = state.copyWith(
      catalog: catalog,
      settings: state.catalog == null
          ? state.settings.copyWith(aspectRatio: catalog.defaultAspectRatio)
          : catalog.supportedAspectRatios.contains(state.settings.aspectRatio)
          ? state.settings
          : state.settings.copyWith(aspectRatio: catalog.defaultAspectRatio),
      selectedProductIds: preferredProductId != null
          ? [
              ...state.selectedProductIds.where(
                (id) => id != preferredProductId,
              ),
              preferredProductId,
            ]
          : state.selectedProductIds.isEmpty && catalog.products.isNotEmpty
          ? [catalog.products.first.id]
          : state.selectedProductIds,
      selectedModelKeys: preferredModel != null
          ? [
              ...state.selectedModelKeys.where(
                (key) => key != _modelKey(preferredModel),
              ),
              _modelKey(preferredModel),
            ]
          : state.selectedModelKeys.isEmpty
          ? [
              if (catalog.userModels.isNotEmpty)
                _modelKey(catalog.userModels.first)
              else if (catalog.libraryModels.isNotEmpty)
                _modelKey(catalog.libraryModels.first),
            ]
          : state.selectedModelKeys,
      useLibraryModels:
          catalog.userModels.isEmpty && catalog.libraryModels.isNotEmpty,
      selectedDirectorIds:
          state.selectedDirectorIds.isEmpty && catalog.looks.isNotEmpty
          ? [catalog.looks.first.id]
          : state.selectedDirectorIds,
      demoConfigs: state.demoConfigs.isEmpty && catalog.looks.isNotEmpty
          ? {catalog.looks.first.id: const DemoDirectorConfig()}
          : state.demoConfigs,
      isLoading: false,
      clearFailure: true,
    );
  }

  void setStep(_CreateStep step) => state = state.copyWith(step: step);

  void setDemo({required bool isDemo}) {
    if (!state.isAdmin) return;
    state = state.copyWith(
      isDemo: isDemo,
      step: state.step == _CreateStep.planning
          ? _CreateStep.director
          : state.step,
      settings: state.settings.copyWith(
        lane: ShootLane.fast,
        imageSize: isDemo ? '2K' : state.settings.imageSize,
      ),
    );
  }

  void setProductMode(ProductMode productMode) {
    final max = productMode == ProductMode.pairing ? 3 : 6;
    state = state.copyWith(
      productMode: productMode,
      selectedProductIds: state.selectedProductIds.take(max).toList(),
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void toggleProduct(int index) {
    if (index < 0 || index >= state.products.length) return;
    final id = state.products[index].id;
    final selected = [...state.selectedProductIds];
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      final max = state.productMode == ProductMode.pairing ? 3 : 6;
      if (selected.length >= max) return;
      selected.add(id);
    }
    state = state.copyWith(
      selectedProductIds: selected,
      productMode: selected.length > 1
          ? state.productMode
          : ProductMode.pairing,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void clearProducts() {
    state = state.copyWith(
      selectedProductIds: const [],
      productMode: ProductMode.pairing,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void toggleModel(int index) {
    if (index < 0 || index >= state.models.length) return;
    final key = _modelKey(state.models[index]);
    final selected = [...state.selectedModelKeys];
    if (selected.contains(key)) {
      selected.remove(key);
    } else {
      if (selected.length >= 3) return;
      selected.add(key);
    }
    state = state.copyWith(
      selectedModelKeys: selected,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void setModelSource({required bool useLibraryModels}) {
    state = state.copyWith(
      useLibraryModels: useLibraryModels,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void selectDirector(int index) {
    if (index < 0 || index >= state.directors.length) return;
    final directorId = state.directors[index].id;
    final maxShots = directorId == 'fine-jewelry' ? 7 : 10;
    state = state.copyWith(
      selectedDirector: index,
      settings: state.settings.copyWith(
        directorId: directorId,
        numberOfShots: state.settings.numberOfShots.clamp(1, maxShots),
      ),
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void toggleDemoDirector(int index) {
    if (index < 0 || index >= state.directors.length) return;
    final id = state.directors[index].id;
    final selected = [...state.selectedDirectorIds];
    final configs = {...state.demoConfigs};
    if (selected.contains(id)) {
      selected.remove(id);
      configs.remove(id);
    } else {
      selected.add(id);
      configs[id] = const DemoDirectorConfig();
    }
    state = state.copyWith(
      selectedDirectorIds: selected,
      demoConfigs: configs,
    );
  }

  void updateSettings(ShootSettings settings) {
    state = state.copyWith(
      settings: settings,
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void setLane(ShootLane lane) {
    state = state.copyWith(settings: state.settings.copyWith(lane: lane));
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
        Iterable<int>.generate(shots.length.clamp(0, 10)),
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
    final trimmedIdea = shotIdea.trim();
    if (trimmedIdea.length < 10) {
      return const ValidationFailure(
        'Shot idea must be at least 10 characters.',
      );
    }
    if (state.plannedShots.length >= 10) {
      return const ValidationFailure('A shoot can have up to 10 shots.');
    }
    final selection = state.selection;
    if (selection == null) {
      return const UnknownFailure('Select a product and model first.');
    }
    final result = await _repository.createCustomShot(
      CustomShootShotRequest(
        selection: selection,
        shotIdea: trimmedIdea,
        poseDirection: poseDirection,
        focusArea: focusArea,
        existingShots: state.plannedShots,
      ),
    );
    if (_disposed) return null;
    if (result case Err(:final failure)) return failure;
    final customShot = result.valueOrNull!;
    final shots = [
      ...state.plannedShots,
      PlannedShootShot(
        title: customShot.title,
        description: customShot.description,
        payload: {
          ...customShot.payload,
          'models': const ['primary'],
        },
      ),
    ];
    final shouldSelect = state.selectedShots.length < 10;
    state = state.copyWith(
      plannedShots: shots,
      selectedShots: {
        ...state.selectedShots,
        if (shouldSelect) shots.length - 1,
      },
    );
    return null;
  }

  void toggleShot(int index) {
    final selected = {...state.selectedShots};
    if (selected.contains(index)) {
      selected.remove(index);
    } else if (selected.length < 10) {
      selected.add(index);
    }
    state = state.copyWith(selectedShots: selected);
  }

  Future<Result<String>> createShoot() async {
    if (_createInFlight) {
      return const Err(ValidationFailure('Shoot creation is already running.'));
    }
    final selection = state.selection;
    if (selection == null ||
        (state.isDemo
            ? state.selectedDirectorIds.isEmpty
            : state.chosenShots.isEmpty)) {
      return const Err(
        UnknownFailure('Select a product, model, and at least one shot.'),
      );
    }
    _createInFlight = true;
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    late final Result<String> result;
    try {
      result = state.isDemo
          ? await _createDemo(selection)
          : await _repository.createShoot(
              CreateShootRequest(
                selection: selection,
                shots: state.chosenShots,
              ),
            );
    } finally {
      _createInFlight = false;
    }
    if (_disposed) return result;
    final failure = result.failureOrNull;
    if (failure is NetworkFailure) _applyCreateFailure(failure);
    state = state.copyWith(
      isSubmitting: false,
      failure: failure,
      clearFailure: result.isOk,
    );
    return result;
  }

  Future<Failure?> setPrimaryProductSubCategory(String subCategory) async {
    final product = state.selection?.product;
    if (product == null) {
      return const ValidationFailure('Select a product first.');
    }
    final result = await _repository.updateProductSubCategory(
      product.id,
      subCategory,
    );
    if (result case Err(:final failure)) return failure;
    await load();
    return null;
  }

  Future<Result<String>> _createDemo(ShootSelection baseSelection) async {
    final demoGroupId = const Uuid().v4();
    final createdIds = <String>[];
    Failure? lastFailure;
    for (final directorId in state.selectedDirectorIds) {
      final config =
          state.demoConfigs[directorId] ?? const DemoDirectorConfig();
      final settings = baseSelection.settings.copyWith(
        directorId: directorId,
        numberOfShots: config.numberOfShots,
        variations: config.variations,
        imageSize: '2K',
        lane: ShootLane.fast,
      );
      final selection = ShootSelection(
        products: baseSelection.products,
        models: baseSelection.models,
        settings: settings,
        productMode: baseSelection.productMode,
      );
      final planned = await _repository.planShots(selection);
      if (planned case Err(:final failure)) {
        lastFailure = failure;
        continue;
      }
      final shots = planned.valueOrNull!.take(config.numberOfShots).toList();
      final created = await _repository.createShoot(
        CreateShootRequest(
          selection: selection,
          shots: shots,
          demoGroupId: demoGroupId,
        ),
      );
      if (created case Err(:final failure)) {
        lastFailure = failure;
      } else {
        createdIds.add(created.valueOrNull!);
      }
    }
    if (createdIds.isNotEmpty) return Ok(createdIds.first);
    return Err(lastFailure ?? const UnknownFailure('Demo shoot failed.'));
  }

  void reset() {
    state = _CreateShootState(catalog: state.catalog, isLoading: false);
  }

  void _applyCreateFailure(NetworkFailure failure) {
    switch (failure.code) {
      case 'FOUR_K_BUSINESS_ONLY':
        state = state.copyWith(
          settings: state.settings.copyWith(imageSize: '2K'),
        );
      case 'QUOTA_EXCEEDED':
        if (failure.details['relaxEligible'] == true && state.canUseUnlimited) {
          state = state.copyWith(
            settings: state.settings.copyWith(lane: ShootLane.relax),
          );
        }
      case 'RELAX_PLAN_INELIGIBLE' ||
          'RELAX_DISABLED' ||
          'RELAX_PROVIDER_UNSUPPORTED' ||
          'RELAX_UNAVAILABLE':
        state = state.copyWith(
          settings: state.settings.copyWith(lane: ShootLane.fast),
        );
      case 'RELAX_JOB_TOO_LARGE':
        final rawMax = failure.details['maxImagesPerJob'];
        final maxImages = rawMax is num ? rawMax.toInt() : null;
        if (maxImages != null && state.chosenShots.isNotEmpty) {
          final variations = (maxImages ~/ state.chosenShots.length).clamp(
            1,
            5,
          );
          state = state.copyWith(
            settings: state.settings.copyWith(variations: variations),
          );
        }
      case 'NOT_FOUND':
        state = state.copyWith(step: _CreateStep.product);
      default:
        break;
    }
  }
}

String _modelKey(ShootCatalogItem model) =>
    '${model.source ?? 'user'}:${model.id}';

ShootCatalogItem? _findModel(
  List<ShootCatalogItem> models,
  String? preferredName,
) {
  if (preferredName == null) return null;
  for (final model in models) {
    if (model.name.toLowerCase() == preferredName.toLowerCase()) return model;
  }
  return null;
}

final NotifierProvider<_CreateShootController, _CreateShootState>
_createShootControllerProvider =
    NotifierProvider<_CreateShootController, _CreateShootState>(
      _CreateShootController.new,
    );
