part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _HouseModelScreenState {
  const _HouseModelScreenState({
    required this.libraryModels,
    required this.userModels,
    this.genderFilter,
    this.bodyFilter,
    this.expanded = false,
  });

  final List<_HouseModel> libraryModels;
  final List<_HouseModel> userModels;
  final _ModelGender? genderFilter;
  final _ModelBody? bodyFilter;
  final bool expanded;

  List<_HouseModel> get filteredLibraryModels {
    return libraryModels
        .where(
          (model) =>
              (genderFilter == null || model.gender == genderFilter) &&
              (bodyFilter == null || model.body == bodyFilter),
        )
        .toList(growable: false);
  }

  List<_HouseModel> get visibleLibraryModels {
    final models = filteredLibraryModels;
    return expanded ? models : models.take(4).toList(growable: false);
  }

  bool get hasActiveFilters => genderFilter != null || bodyFilter != null;
}

class _HouseModelController extends Notifier<_HouseModelScreenState> {
  @override
  _HouseModelScreenState build() {
    return const _HouseModelScreenState(
      libraryModels: _modelLibrary,
      userModels: _starterUserModels,
    );
  }

  void applyFilters({_ModelGender? gender, _ModelBody? body}) {
    state = _HouseModelScreenState(
      libraryModels: state.libraryModels,
      userModels: state.userModels,
      genderFilter: gender,
      bodyFilter: body,
    );
  }

  void clearGenderFilter() {
    state = _HouseModelScreenState(
      libraryModels: state.libraryModels,
      userModels: state.userModels,
      bodyFilter: state.bodyFilter,
    );
  }

  void clearBodyFilter() {
    state = _HouseModelScreenState(
      libraryModels: state.libraryModels,
      userModels: state.userModels,
      genderFilter: state.genderFilter,
    );
  }

  void showMore() {
    state = _HouseModelScreenState(
      libraryModels: state.libraryModels,
      userModels: state.userModels,
      genderFilter: state.genderFilter,
      bodyFilter: state.bodyFilter,
      expanded: true,
    );
  }

  _HouseModel addModel(_ModelFormInput input) {
    final model = _HouseModel(
      id: _slug('${input.name}-${state.userModels.length + 1}'),
      name: input.name,
      gender: input.gender,
      body: _ModelBody.slimAthletic,
      ethnicity: 'Brand owned',
      ageRange: '25-35',
      heightCm: input.heightCm,
      asset: '$_img/angle-example-front.png',
      source: _ModelSource.user,
      photoCount: input.photoCount,
      heightEstimated: input.heightEstimated,
    );
    state = _HouseModelScreenState(
      libraryModels: state.libraryModels,
      userModels: [model, ...state.userModels],
      genderFilter: state.genderFilter,
      bodyFilter: state.bodyFilter,
      expanded: state.expanded,
    );
    return model;
  }

  _HouseModel addAiModel({
    required _ModelGender gender,
    required int age,
    required String description,
  }) {
    final name = description
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    return addModel(
      _ModelFormInput(
        name: name.isEmpty ? 'AI Model ${state.userModels.length + 1}' : name,
        gender: gender,
        heightCm: gender == _ModelGender.male ? 182 : 172,
        photoCount: 4,
      ),
    );
  }

  void updateModel(_HouseModel model, _ModelFormInput input) {
    state = _HouseModelScreenState(
      libraryModels: state.libraryModels,
      userModels: [
        for (final item in state.userModels)
          if (item.id == model.id)
            item.copyWith(
              name: input.name,
              gender: input.gender,
              heightCm: input.heightCm,
              photoCount: input.photoCount,
              heightEstimated: input.heightEstimated,
            )
          else
            item,
      ],
      genderFilter: state.genderFilter,
      bodyFilter: state.bodyFilter,
      expanded: state.expanded,
    );
  }

  void deleteModel(_HouseModel model) {
    state = _HouseModelScreenState(
      libraryModels: state.libraryModels,
      userModels: [
        for (final item in state.userModels)
          if (item.id != model.id) item,
      ],
      genderFilter: state.genderFilter,
      bodyFilter: state.bodyFilter,
      expanded: state.expanded,
    );
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

final _houseModelControllerProvider =
    NotifierProvider<_HouseModelController, _HouseModelScreenState>(
      _HouseModelController.new,
    );
