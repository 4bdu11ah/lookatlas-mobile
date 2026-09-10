import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/house_model/di/house_model_providers.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:look_atlas/features/house_model/domain/repositories/house_models_repository.dart';
import 'package:look_atlas/features/house_model/presentation/models/house_model_view_model.dart';
import 'package:look_atlas/services/service_providers.dart';

class HouseModelScreenState {
  const HouseModelScreenState({
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

  final List<HouseModelViewModel> libraryModels;
  final List<HouseModelViewModel> userModels;
  final HouseModelGender? genderFilter;
  final HouseModelBody? bodyFilter;
  final bool expanded;
  final bool isLoading;
  final bool isMutating;
  final bool isGeneratingAiModel;
  final Failure? failure;

  List<HouseModelViewModel> get filteredLibraryModels => libraryModels
      .where(
        (model) =>
            (genderFilter == null || model.gender == genderFilter) &&
            (bodyFilter == null || model.body == bodyFilter),
      )
      .toList(growable: false);

  List<HouseModelViewModel> get visibleLibraryModels {
    final models = filteredLibraryModels;
    return expanded ? models : models.take(4).toList(growable: false);
  }

  bool get hasActiveFilters => genderFilter != null || bodyFilter != null;

  HouseModelScreenState copyWith({
    List<HouseModelViewModel>? libraryModels,
    List<HouseModelViewModel>? userModels,
    HouseModelGender? genderFilter,
    HouseModelBody? bodyFilter,
    bool clearGenderFilter = false,
    bool clearBodyFilter = false,
    bool? expanded,
    bool? isLoading,
    bool? isMutating,
    bool? isGeneratingAiModel,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return HouseModelScreenState(
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

class HouseModelController extends Notifier<HouseModelScreenState> {
  HouseModelsRepository get _repository =>
      ref.read(houseModelsRepositoryProvider);

  @override
  HouseModelScreenState build() {
    unawaited(Future.microtask(reload));
    return const HouseModelScreenState();
  }

  Future<void> reload() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.loadCatalog();
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        libraryModels: [
          for (final model in value.libraryModels)
            HouseModelViewModel.fromProfile(model),
        ],
        userModels: [
          for (final model in value.userModels)
            HouseModelViewModel.fromProfile(model),
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

  void applyFilters({HouseModelGender? gender, HouseModelBody? body}) {
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

  Future<Result<void>> addModel(HouseModelFormInput input) =>
      _mutate(() => ref.read(createHouseModelUseCaseProvider)(input.toDraft()));

  Future<Result<void>> updateModel(
    HouseModelViewModel model,
    HouseModelFormInput input,
  ) async {
    if (state.isMutating) {
      return const Err(ValidationFailure('Another model action is running.'));
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    return _finishMutation(
      await _repository.updateModel(model.id, input.toDraft()),
      reloadAfter: true,
    );
  }

  Future<Result<void>> deleteModel(HouseModelViewModel model) =>
      _mutate(() => _repository.deleteModel(model.id));

  Future<Result<void>> deletePhoto(
    HouseModelViewModel model,
    String photoId,
  ) async {
    final result = await _mutate(
      () => _repository.deletePhoto(model.id, photoId),
      reloadAfter: false,
    );
    if (result.isOk) unawaited(Future.microtask(reload));
    return result;
  }

  Future<Result<void>> addAiModel({
    required HouseModelGender gender,
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
          HouseModelGender.nonBinary => 'non_binary',
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
    final result = await ref.read(completeHouseModelGenerationUseCaseProvider)(
      generation,
    );
    if (result case Err(:final failure)) {
      state = state.copyWith(isGeneratingAiModel: false, failure: failure);
      return;
    }
    final catalog = result.valueOrNull!;
    state = state.copyWith(
      libraryModels: [
        for (final model in catalog.libraryModels)
          HouseModelViewModel.fromProfile(model),
      ],
      userModels: [
        for (final model in catalog.userModels)
          HouseModelViewModel.fromProfile(model),
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
    Future<Result<void>> Function() operation, {
    bool reloadAfter = true,
  }) async {
    if (state.isMutating) {
      return const Err(ValidationFailure('Another model action is running.'));
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    return _finishMutation(await operation(), reloadAfter: reloadAfter);
  }

  Future<Result<void>> _finishMutation(
    Result<void> result, {
    required bool reloadAfter,
  }) async {
    if (result case Err(:final failure)) {
      state = state.copyWith(isMutating: false, failure: failure);
      return Err(failure);
    }
    if (!reloadAfter) {
      state = state.copyWith(isMutating: false, clearFailure: true);
      return const Ok(null);
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
          HouseModelViewModel.fromProfile(model),
      ],
      userModels: [
        for (final model in catalog.userModels)
          HouseModelViewModel.fromProfile(model),
      ],
      isLoading: false,
      isMutating: false,
      clearFailure: true,
    );
    return const Ok(null);
  }
}

final houseModelControllerProvider =
    NotifierProvider<HouseModelController, HouseModelScreenState>(
      HouseModelController.new,
    );
