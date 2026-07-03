import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';

/// What came out of a photo-pick attempt, so screens can show the right
/// feedback without owning any picking state themselves.
enum PhotoPickResult {
  /// Photos were added (possibly zero because the user cancelled).
  added,

  /// Photos were added but some were dropped by the max-photos cap.
  truncated,

  /// The camera / photo library could not be opened.
  failed,
}

/// Everything the six-step wizard has collected so far.
@immutable
class WizardState {
  const WizardState({
    this.step = WizardStep.intro,
    this.productPhase = ProductPhase.category,
    this.category,
    this.photos = const [],
    this.addingPhotos = false,
    this.calibrationSubtype,
    this.calibrationSaved = false,
    this.modelGenderFilter = ModelGender.all,
    this.modelUploadTab = false,
    this.selectedModel,
    this.uploadedModelPhotos = const [],
    this.usingUploadedModel = false,
    this.uploadingModel = false,
    this.selectedDirector,
  });

  final WizardStep step;
  final ProductPhase productPhase;
  final ProductCategory? category;
  final List<WizardPhoto> photos;
  final bool addingPhotos;
  final String? calibrationSubtype;
  final bool calibrationSaved;
  final ModelGender modelGenderFilter;

  /// True while the "Upload Your Own" tab is selected on the model step.
  final bool modelUploadTab;
  final LookAtlasModel? selectedModel;
  final List<Uint8List> uploadedModelPhotos;

  /// True when the user picked their uploaded photos over a library model.
  final bool usingUploadedModel;
  final bool uploadingModel;
  final Director? selectedDirector;

  /// Steps in flow order for the current selections. Calibration only joins
  /// the flow for calibratable categories when the trial flag is on.
  List<WizardStep> get flow => [
    WizardStep.intro,
    WizardStep.product,
    if (calibrationEnabledInTrial && (category?.isCalibratable ?? false))
      WizardStep.calibrate,
    WizardStep.model,
    WizardStep.director,
    WizardStep.review,
  ];

  /// 1-based position of the current step, driving the top progress bar.
  /// Progress is always rendered out of 6 (matching the mockups) even when
  /// the calibrate step is skipped.
  double get progress => (step.index + 1) / WizardStep.values.length;

  /// Display name for the product shown on the review card.
  String get productName => category?.label ?? 'Your product';

  bool get allAnglesTagged => photos.every((p) => p.angle != null);

  /// Whether Continue should be enabled for the current step.
  bool get canContinue => switch (step) {
    WizardStep.intro => true,
    WizardStep.product =>
      productPhase == ProductPhase.category
          ? category != null
          : photos.isNotEmpty,
    WizardStep.calibrate => true,
    WizardStep.model =>
      selectedModel != null ||
          (usingUploadedModel && uploadedModelPhotos.isNotEmpty),
    WizardStep.director => selectedDirector != null,
    WizardStep.review => true,
  };

  /// Name shown under "Model" on the review card.
  String get modelName =>
      usingUploadedModel ? 'Your model' : (selectedModel?.name ?? '—');

  WizardState copyWith({
    WizardStep? step,
    ProductPhase? productPhase,
    ProductCategory? category,
    List<WizardPhoto>? photos,
    bool? addingPhotos,
    String? calibrationSubtype,
    bool? calibrationSaved,
    ModelGender? modelGenderFilter,
    bool? modelUploadTab,
    LookAtlasModel? selectedModel,
    bool clearSelectedModel = false,
    List<Uint8List>? uploadedModelPhotos,
    bool? usingUploadedModel,
    bool? uploadingModel,
    Director? selectedDirector,
  }) {
    return WizardState(
      step: step ?? this.step,
      productPhase: productPhase ?? this.productPhase,
      category: category ?? this.category,
      photos: photos ?? this.photos,
      addingPhotos: addingPhotos ?? this.addingPhotos,
      calibrationSubtype: calibrationSubtype ?? this.calibrationSubtype,
      calibrationSaved: calibrationSaved ?? this.calibrationSaved,
      modelGenderFilter: modelGenderFilter ?? this.modelGenderFilter,
      modelUploadTab: modelUploadTab ?? this.modelUploadTab,
      selectedModel: clearSelectedModel
          ? null
          : (selectedModel ?? this.selectedModel),
      uploadedModelPhotos: uploadedModelPhotos ?? this.uploadedModelPhotos,
      usingUploadedModel: usingUploadedModel ?? this.usingUploadedModel,
      uploadingModel: uploadingModel ?? this.uploadingModel,
      selectedDirector: selectedDirector ?? this.selectedDirector,
    );
  }
}

/// Drives the six-step pre-login wizard. Owns step navigation and every
/// selection made along the way; screens stay purely presentational.
class WizardController extends Notifier<WizardState> {
  @override
  WizardState build() => const WizardState();

  /// Moves forward one step (or from category picking to photo upload).
  /// Returns false when the current step isn't complete yet.
  bool next() {
    if (!state.canContinue) return false;
    if (state.step == WizardStep.product &&
        state.productPhase == ProductPhase.category) {
      state = state.copyWith(productPhase: ProductPhase.upload);
      return true;
    }
    final flow = state.flow;
    final i = flow.indexOf(state.step);
    if (i < flow.length - 1) state = state.copyWith(step: flow[i + 1]);
    return true;
  }

  /// Moves back one step (or from photo upload to category picking).
  /// Returns false when already on the first step, so the screen can hand
  /// off to sign-in instead.
  bool back() {
    if (state.step == WizardStep.product &&
        state.productPhase == ProductPhase.upload) {
      state = state.copyWith(productPhase: ProductPhase.category);
      return true;
    }
    final flow = state.flow;
    final i = flow.indexOf(state.step);
    if (i <= 0) return false;
    state = state.copyWith(step: flow[i - 1]);
    return true;
  }

  // --- Photo picking (camera / gallery) ------------------------------------

  /// Downscale + recompress settings shared by every pick in the wizard.
  static const double _pickMaxWidth = 1600;
  static const int _pickQuality = 85;

  /// Opens the camera (single shot) or gallery (multi-select up to [limit])
  /// and returns the picked files. Cancelling returns an empty list.
  Future<List<XFile>> _pickFiles(ImageSource source, {required int limit}) {
    final picker = ref.read(imagePickerProvider);
    if (source == ImageSource.camera) {
      return picker
          .pickImage(
            source: ImageSource.camera,
            maxWidth: _pickMaxWidth,
            imageQuality: _pickQuality,
          )
          .then((shot) => [?shot]);
    }
    return picker.pickMultiImage(
      maxWidth: _pickMaxWidth,
      imageQuality: _pickQuality,
      limit: limit,
    );
  }

  // --- Step 2: product -----------------------------------------------------

  void selectCategory(ProductCategory category) {
    state = state.copyWith(category: category);
  }

  /// Picks product photos from [source] and adds them (capped at
  /// [maxWizardPhotos]). Owns the whole busy/error lifecycle so the screen
  /// stays stateless.
  Future<PhotoPickResult> addProductPhotosFrom(ImageSource source) async {
    if (state.addingPhotos) return PhotoPickResult.added;
    state = state.copyWith(addingPhotos: true);
    try {
      final files = await _pickFiles(source, limit: maxWizardPhotos);
      final photos = <WizardPhoto>[
        for (final file in files) WizardPhoto(bytes: await file.readAsBytes()),
      ];
      final room = maxWizardPhotos - state.photos.length;
      addPhotos(photos);
      return photos.length > room
          ? PhotoPickResult.truncated
          : PhotoPickResult.added;
    } on Exception catch (error) {
      AppLogger.warning('Product photo pick failed: $error');
      state = state.copyWith(addingPhotos: false);
      return PhotoPickResult.failed;
    }
  }

  void addPhotos(List<WizardPhoto> photos) {
    final room = maxWizardPhotos - state.photos.length;
    state = state.copyWith(
      photos: [...state.photos, ...photos.take(room)],
      addingPhotos: false,
    );
  }

  void removePhoto(int index) {
    state = state.copyWith(photos: [...state.photos]..removeAt(index));
  }

  void setPhotoAngle(int index, String angle) {
    final photos = [...state.photos];
    photos[index] = photos[index].copyWith(angle: angle);
    state = state.copyWith(photos: photos);
  }

  void clearPhotos() => state = state.copyWith(photos: []);

  // --- Step 3: calibrate ---------------------------------------------------

  void selectCalibrationSubtype(String subtype) {
    state = state.copyWith(calibrationSubtype: subtype);
  }

  void saveCalibration() => state = state.copyWith(calibrationSaved: true);

  // --- Step 4: model -------------------------------------------------------

  void setModelGenderFilter(ModelGender filter) {
    state = state.copyWith(modelGenderFilter: filter);
  }

  void setModelUploadTab({required bool upload}) {
    state = state.copyWith(modelUploadTab: upload);
  }

  void selectModel(LookAtlasModel model) {
    state = state.copyWith(selectedModel: model, usingUploadedModel: false);
  }

  /// Picks model photos from [source] and adds them (capped at
  /// [maxWizardPhotos]).
  Future<PhotoPickResult> addModelPhotosFrom(ImageSource source) async {
    if (state.uploadingModel) return PhotoPickResult.added;
    state = state.copyWith(uploadingModel: true);
    try {
      final files = await _pickFiles(source, limit: maxWizardPhotos);
      final photos = <Uint8List>[
        for (final file in files) await file.readAsBytes(),
      ];
      if (photos.isEmpty) {
        state = state.copyWith(uploadingModel: false);
        return PhotoPickResult.added;
      }
      final room = maxWizardPhotos - state.uploadedModelPhotos.length;
      addUploadedModelPhotos(photos);
      return photos.length > room
          ? PhotoPickResult.truncated
          : PhotoPickResult.added;
    } on Exception catch (error) {
      AppLogger.warning('Model photo pick failed: $error');
      state = state.copyWith(uploadingModel: false);
      return PhotoPickResult.failed;
    }
  }

  void addUploadedModelPhotos(List<Uint8List> photos) {
    final room = maxWizardPhotos - state.uploadedModelPhotos.length;
    state = state.copyWith(
      uploadedModelPhotos: [
        ...state.uploadedModelPhotos,
        ...photos.take(room),
      ],
      uploadingModel: false,
      usingUploadedModel: true,
      clearSelectedModel: true,
    );
  }

  void useUploadedModel() {
    if (state.uploadedModelPhotos.isEmpty) return;
    state = state.copyWith(usingUploadedModel: true, clearSelectedModel: true);
  }

  // --- Step 5: director ----------------------------------------------------

  void selectDirector(Director director) {
    state = state.copyWith(selectedDirector: director);
  }

  /// Resets the whole funnel (e.g. after finishing or abandoning it).
  void reset() => state = const WizardState();
}

/// The single wizard state shared by every onboarding screen.
final wizardControllerProvider =
    NotifierProvider<WizardController, WizardState>(
      WizardController.new,
    );
