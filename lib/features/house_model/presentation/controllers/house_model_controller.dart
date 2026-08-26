part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _HouseModelScreenState {
  const _HouseModelScreenState({
    this.libraryModels = const [],
    this.userModels = const [],
    this.genderFilter,
    this.bodyFilter,
    this.expanded = false,
    this.isLoading = true,
    this.isMutating = false,
    this.isGeneratingAiModel = false,
    this.failure,
  });

  final List<_HouseModel> libraryModels;
  final List<_HouseModel> userModels;
  final _ModelGender? genderFilter;
  final _ModelBody? bodyFilter;
  final bool expanded;
  final bool isLoading;
  final bool isMutating;
  final bool isGeneratingAiModel;
  final Failure? failure;

  List<_HouseModel> get filteredLibraryModels => libraryModels
      .where(
        (model) =>
            (genderFilter == null || model.gender == genderFilter) &&
            (bodyFilter == null || model.body == bodyFilter),
      )
      .toList(growable: false);

  List<_HouseModel> get visibleLibraryModels {
    final models = filteredLibraryModels;
    return expanded ? models : models.take(4).toList(growable: false);
  }

  bool get hasActiveFilters => genderFilter != null || bodyFilter != null;

  _HouseModelScreenState copyWith({
    List<_HouseModel>? libraryModels,
    List<_HouseModel>? userModels,
    _ModelGender? genderFilter,
    _ModelBody? bodyFilter,
    bool clearGenderFilter = false,
    bool clearBodyFilter = false,
    bool? expanded,
    bool? isLoading,
    bool? isMutating,
    bool? isGeneratingAiModel,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return _HouseModelScreenState(
      libraryModels: libraryModels ?? this.libraryModels,
      userModels: userModels ?? this.userModels,
      genderFilter: clearGenderFilter
          ? null
          : genderFilter ?? this.genderFilter,
      bodyFilter: clearBodyFilter ? null : bodyFilter ?? this.bodyFilter,
      expanded: expanded ?? this.expanded,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      isGeneratingAiModel: isGeneratingAiModel ?? this.isGeneratingAiModel,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

class _HouseModelController extends Notifier<_HouseModelScreenState> {
  HouseModelsRepository get _repository =>
      ref.read(houseModelsRepositoryProvider);

  @override
  _HouseModelScreenState build() {
    unawaited(Future.microtask(reload));
    return const _HouseModelScreenState();
  }

  Future<void> reload() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.loadCatalog();
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        libraryModels: [
          for (final model in value.libraryModels)
            _HouseModel.fromProfile(model),
        ],
        userModels: [
          for (final model in value.userModels) _HouseModel.fromProfile(model),
        ],
        isLoading: false,
        clearFailure: true,
      ),
      Err(:final failure) => state.copyWith(
        isLoading: false,
        failure: failure,
      ),
    };
  }

  void applyFilters({_ModelGender? gender, _ModelBody? body}) {
    state = state.copyWith(
      genderFilter: gender,
      bodyFilter: body,
      clearGenderFilter: gender == null,
      clearBodyFilter: body == null,
      expanded: false,
    );
  }

  void clearGenderFilter() =>
      state = state.copyWith(clearGenderFilter: true, expanded: false);

  void clearBodyFilter() =>
      state = state.copyWith(clearBodyFilter: true, expanded: false);

  void showMore() => state = state.copyWith(expanded: true);

  Future<Result<void>> addModel(_ModelFormInput input) =>
      _mutate(() => _repository.createModel(input.toDraft()));

  Future<Result<void>> updateModel(
    _HouseModel model,
    _ModelFormInput input,
  ) async {
    if (state.isMutating) {
      return const Err(ValidationFailure('Another model action is running.'));
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    return _finishMutation(
      await _repository.updateModel(model.id, input.toDraft()),
    );
  }

  Future<Result<void>> deleteModel(_HouseModel model) =>
      _mutate(() => _repository.deleteModel(model.id));

  Future<Result<void>> deletePhoto(_HouseModel model, int photoIndex) =>
      _mutate(() => _repository.deletePhoto(model.id, photoIndex));

  Future<Result<void>> addAiModel({
    required _ModelGender gender,
    required int age,
    required String description,
  }) async {
    if (state.isMutating || state.isGeneratingAiModel) {
      return const Err(ValidationFailure('Another model action is running.'));
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    final started = await _repository.startModelGeneration(
      AiHouseModelDraft(
        gender: switch (gender) {
          _ModelGender.nonBinary => 'non_binary',
          _ => gender.name,
        },
        age: age,
        description: description,
      ),
    );
    final generation = started.valueOrNull;
    if (generation == null) {
      final failure = started.failureOrNull!;
      state = state.copyWith(isMutating: false, failure: failure);
      return Err(failure);
    }
    state = state.copyWith(isMutating: false, isGeneratingAiModel: true);
    unawaited(_finishAiGeneration(generation));
    return const Ok(null);
  }

  Future<void> _finishAiGeneration(HouseModelGeneration generation) async {
    final result = await _repository.waitForModelGeneration(generation);
    if (result case Err(:final failure)) {
      state = state.copyWith(isGeneratingAiModel: false, failure: failure);
      return;
    }
    final refreshed = await _repository.loadCatalog();
    if (refreshed case Err(:final failure)) {
      state = state.copyWith(isGeneratingAiModel: false, failure: failure);
      return;
    }
    final catalog = refreshed.valueOrNull!;
    state = state.copyWith(
      libraryModels: [
        for (final model in catalog.libraryModels)
          _HouseModel.fromProfile(model),
      ],
      userModels: [
        for (final model in catalog.userModels) _HouseModel.fromProfile(model),
      ],
      isGeneratingAiModel: false,
      clearFailure: true,
    );
    unawaited(
      ref
          .read(localNotificationServiceProvider)
          .showCompletion(
            taskId: 'house-model-${DateTime.now().microsecondsSinceEpoch}',
            title: 'AI model completed',
            body: 'Your AI model is ready to use in a shoot.',
            destination: AppRoutes.dashboardModels,
          ),
    );
  }

  Future<Result<void>> _mutate(
    Future<Result<void>> Function() operation,
  ) async {
    if (state.isMutating) {
      return const Err(ValidationFailure('Another model action is running.'));
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    return _finishMutation(await operation());
  }

  Future<Result<void>> _finishMutation(Result<void> result) async {
    if (result case Err(:final failure)) {
      state = state.copyWith(isMutating: false, failure: failure);
      return Err(failure);
    }
    final refreshed = await _repository.loadCatalog();
    if (refreshed case Err(:final failure)) {
      state = state.copyWith(isMutating: false, failure: failure);
      return const Ok(null);
    }
    final catalog = refreshed.valueOrNull!;
    state = state.copyWith(
      libraryModels: [
        for (final model in catalog.libraryModels)
          _HouseModel.fromProfile(model),
      ],
      userModels: [
        for (final model in catalog.userModels) _HouseModel.fromProfile(model),
      ],
      isLoading: false,
      isMutating: false,
      clearFailure: true,
    );
    return const Ok(null);
  }
}

final _houseModelControllerProvider =
    NotifierProvider<_HouseModelController, _HouseModelScreenState>(
      _HouseModelController.new,
    );
