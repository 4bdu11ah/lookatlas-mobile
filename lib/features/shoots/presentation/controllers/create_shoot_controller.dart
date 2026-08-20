part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CreateShootState {
  const _CreateShootState({
    this.step = _CreateStep.product,
    this.catalog,
    this.productMode = ProductMode.pairing,
    this.selectedProductIds = const [],
    this.selectedModelKeys = const [],
    this.selectedDirector = -1,
    this.previewDirector = 0,
    this.demoMode = false,
    this.demoDirectors = const [],
    this.useLibraryModels = false,
    this.settings = const ShootSettings(directorId: ''),
    this.plannedShots = const [],
    this.selectedShots = const {},
    this.isLoading = true,
    this.isLoadingModels = false,
    this.isLoadingDirectorSetup = false,
    this.hasLoadedModels = false,
    this.hasLoadedDirectorSetup = false,
    this.isPlanning = false,
    this.isSubmitting = false,
    this.failure,
  });

  final _CreateStep step;
  final ShootCreateCatalog? catalog;
  final ProductMode productMode;
  final List<String> selectedProductIds;
  final List<String> selectedModelKeys;
  final int selectedDirector;
  final int previewDirector;
  final bool demoMode;
  final List<DemoDirectorConfig> demoDirectors;
  final bool useLibraryModels;
  final ShootSettings settings;
  final List<PlannedShootShot> plannedShots;
  final Set<int> selectedShots;
  final bool isLoading;
  final bool isLoadingModels;
  final bool isLoadingDirectorSetup;
  final bool hasLoadedModels;
  final bool hasLoadedDirectorSetup;
  final bool isPlanning;
  final bool isSubmitting;
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
    if (selectedProducts.isEmpty ||
        selectedModels.isEmpty ||
        selectedDirector < 0 ||
        selectedDirector >= directors.length) {
      return null;
    }
    final directorId = directors[selectedDirector].id;
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

  int get totalImages => chosenShots.length * settings.variations;

  int get requiredCredits =>
      totalImages *
      switch (settings.imageSize) {
        '4K' => 3,
        '2K' => 2,
        _ => 1,
      };

  bool get canUseUnlimited => catalog?.isUnlimitedEligible ?? false;

  bool get canContinueFromDirector => demoMode
      ? demoDirectors.isNotEmpty &&
            demoDirectors.every(
              (config) => config.numberOfShots > 0 && config.variations > 0,
            )
      : directors.isNotEmpty &&
            selectedDirector >= 0 &&
            settings.useCase.isNotEmpty &&
            settings.directorId.isNotEmpty;

  int get demoRequiredCredits => demoDirectors.fold<int>(
    0,
    (total, config) => total + config.numberOfShots * config.variations * 2,
  );

  bool get canGenerateDemo =>
      canContinueFromDirector &&
      demoRequiredCredits <= (catalog?.availableCredits ?? 0);

  bool get needsPrimaryProductSubCategory {
    final product = selection?.product;
    return product?.category?.toLowerCase() == 'bags' &&
        (product?.subCategory?.trim().isEmpty ?? true);
  }

  bool get canGenerate =>
      chosenShots.isNotEmpty &&
      (settings.lane == ShootLane.relax ||
          requiredCredits <= (catalog?.availableCredits ?? 0));

  List<_CreateStep> get steps => demoMode
      ? const [
          _CreateStep.product,
          _CreateStep.model,
          _CreateStep.director,
          _CreateStep.confirm,
        ]
      : _CreateStep.values;

  _CreateShootState copyWith({
    _CreateStep? step,
    ShootCreateCatalog? catalog,
    ProductMode? productMode,
    List<String>? selectedProductIds,
    List<String>? selectedModelKeys,
    int? selectedDirector,
    int? previewDirector,
    bool? demoMode,
    List<DemoDirectorConfig>? demoDirectors,
    bool? useLibraryModels,
    ShootSettings? settings,
    List<PlannedShootShot>? plannedShots,
    Set<int>? selectedShots,
    bool? isLoading,
    bool? isLoadingModels,
    bool? isLoadingDirectorSetup,
    bool? hasLoadedModels,
    bool? hasLoadedDirectorSetup,
    bool? isPlanning,
    bool? isSubmitting,
    Failure? failure,
    bool clearFailure = false,
  }) => _CreateShootState(
    step: step ?? this.step,
    catalog: catalog ?? this.catalog,
    productMode: productMode ?? this.productMode,
    selectedProductIds: selectedProductIds ?? this.selectedProductIds,
    selectedModelKeys: selectedModelKeys ?? this.selectedModelKeys,
    selectedDirector: selectedDirector ?? this.selectedDirector,
    previewDirector: previewDirector ?? this.previewDirector,
    demoMode: demoMode ?? this.demoMode,
    demoDirectors: demoDirectors ?? this.demoDirectors,
    useLibraryModels: useLibraryModels ?? this.useLibraryModels,
    settings: settings ?? this.settings,
    plannedShots: plannedShots ?? this.plannedShots,
    selectedShots: selectedShots ?? this.selectedShots,
    isLoading: isLoading ?? this.isLoading,
    isLoadingModels: isLoadingModels ?? this.isLoadingModels,
    isLoadingDirectorSetup:
        isLoadingDirectorSetup ?? this.isLoadingDirectorSetup,
    hasLoadedModels: hasLoadedModels ?? this.hasLoadedModels,
    hasLoadedDirectorSetup:
        hasLoadedDirectorSetup ?? this.hasLoadedDirectorSetup,
    isPlanning: isPlanning ?? this.isPlanning,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class _CreateShootController extends Notifier<_CreateShootState>
    with _CreateShootDemoController {
  @override
  bool _disposed = false;
  @override
  bool _createInFlight = false;

  @override
  ShootsRepository get _repository => ref.read(shootsRepositoryProvider);

  @override
  _CreateShootState build() {
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(_loadProducts));
    return const _CreateShootState();
  }

  Future<void> load({
    String? preferredProductId,
    String? preferredModelName,
  }) async {
    if (preferredProductId != null || state.catalog == null) {
      await _loadProducts(preferredProductId: preferredProductId);
    }
    if (preferredModelName != null) {
      await _loadModels(preferredModelName: preferredModelName, force: true);
    }
  }

  Future<void> retry() => switch (state.step) {
    _CreateStep.product => _loadProducts(),
    _CreateStep.model => _loadModels(),
    _CreateStep.director => _loadDirectorSetup(),
    _ => Future.value(),
  };

  Future<void> _loadProducts({String? preferredProductId}) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.loadCreateProducts();
    if (_disposed) return;
    if (result case Err(:final failure)) {
      state = state.copyWith(isLoading: false, failure: failure);
      return;
    }
    final products = result.valueOrNull!.products;
    final catalog = _catalog.copyWith(products: products);
    final currentSettings = state.catalog == null
        ? state.settings.copyWith(aspectRatio: catalog.defaultAspectRatio)
        : catalog.supportedAspectRatios.contains(state.settings.aspectRatio)
        ? state.settings
        : state.settings.copyWith(aspectRatio: catalog.defaultAspectRatio);
    state = state.copyWith(
      catalog: catalog,
      settings: currentSettings.copyWith(
        imageSize: catalog.isUnlimitedEligible && catalog.plan == 'pro'
            ? '2K'
            : currentSettings.imageSize,
        lane: catalog.isUnlimitedEligible ? ShootLane.relax : ShootLane.fast,
      ),
      selectedProductIds: preferredProductId != null
          ? [
              ...state.selectedProductIds.where(
                (id) => id != preferredProductId,
              ),
              preferredProductId,
            ]
          : state.selectedProductIds,
      isLoading: false,
      clearFailure: true,
    );
  }

  ShootCreateCatalog get _catalog =>
      state.catalog ??
      const ShootCreateCatalog(
        products: [],
        userModels: [],
        libraryModels: [],
        looks: [],
        lookFilters: {},
        presets: [],
        availableCredits: 0,
      );

  Future<void> _loadModels({
    String? preferredModelName,
    bool force = false,
  }) async {
    if (state.isLoadingModels || (state.hasLoadedModels && !force)) return;
    state = state.copyWith(isLoadingModels: true, clearFailure: true);
    final result = await _repository.loadCreateModels();
    if (_disposed) return;
    if (result case Err(:final failure)) {
      state = state.copyWith(isLoadingModels: false, failure: failure);
      return;
    }
    final models = result.valueOrNull!;
    final catalog = _catalog.copyWith(
      userModels: models.userModels,
      libraryModels: models.libraryModels,
    );
    final preferredModel = _findModel(catalog.userModels, preferredModelName);
    state = state.copyWith(
      catalog: catalog,
      selectedModelKeys: preferredModel == null
          ? state.selectedModelKeys
          : [
              ...state.selectedModelKeys.where(
                (key) => key != _modelKey(preferredModel),
              ),
              _modelKey(preferredModel),
            ],
      useLibraryModels:
          catalog.userModels.isEmpty && catalog.libraryModels.isNotEmpty,
      isLoadingModels: false,
      hasLoadedModels: true,
      clearFailure: true,
    );
  }

  Future<void> _loadDirectorSetup() async {
    if (state.isLoadingDirectorSetup || state.hasLoadedDirectorSetup) return;
    state = state.copyWith(isLoadingDirectorSetup: true, clearFailure: true);
    final result = await _repository.loadCreateDirectorSetup();
    if (_disposed) return;
    if (result case Err(:final failure)) {
      state = state.copyWith(isLoadingDirectorSetup: false, failure: failure);
      return;
    }
    final setup = result.valueOrNull!;
    final catalog = _catalog.copyWith(
      looks: setup.looks,
      lookFilters: setup.lookFilters,
      presets: setup.presets,
      availableCredits: setup.availableCredits,
      supportedAspectRatios: setup.supportedAspectRatios,
      defaultAspectRatio: setup.defaultAspectRatio,
      relaxEnabled: setup.relaxEnabled,
      plan: setup.plan,
      isUnlimitedEligible: setup.isUnlimitedEligible,
    );
    state = state.copyWith(
      catalog: catalog,
      settings: state.settings.copyWith(
        aspectRatio:
            catalog.supportedAspectRatios.contains(
              state.settings.aspectRatio,
            )
            ? state.settings.aspectRatio
            : catalog.defaultAspectRatio,
        imageSize: catalog.isUnlimitedEligible && catalog.plan == 'pro'
            ? '2K'
            : state.settings.imageSize,
        lane: catalog.isUnlimitedEligible ? ShootLane.relax : ShootLane.fast,
      ),
      isLoadingDirectorSetup: false,
      hasLoadedDirectorSetup: true,
      clearFailure: true,
    );
  }

  void setStep(_CreateStep step) {
    state = state.copyWith(step: step);
    switch (step) {
      case _CreateStep.model:
        unawaited(_loadModels());
      case _CreateStep.director:
        unawaited(_loadDirectorSetup());
      case _CreateStep.product:
      case _CreateStep.planning:
      case _CreateStep.confirm:
        break;
    }
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

  void removeModel(String key) {
    state = state.copyWith(
      selectedModelKeys: [...state.selectedModelKeys]..remove(key),
      plannedShots: const [],
      selectedShots: const {},
    );
  }

  void clearModels() {
    state = state.copyWith(
      selectedModelKeys: const [],
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
    final maxShots = directorId == 'fine-jewelry' ? 7 : 8;
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

  void previewDirectorAt(int index) {
    if (index < 0 || index >= state.directors.length) return;
    state = state.copyWith(previewDirector: index);
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
    if (trimmedIdea.length <= 10) {
      return const ValidationFailure(
        'Shot idea must be more than 10 characters.',
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
    if (selection == null || state.chosenShots.isEmpty) {
      return const Err(
        UnknownFailure('Select a product, model, and at least one shot.'),
      );
    }
    _createInFlight = true;
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    late final Result<String> result;
    try {
      result = await _repository.createShoot(
        CreateShootRequest(selection: selection, shots: state.chosenShots),
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

String _newDemoGroupId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
