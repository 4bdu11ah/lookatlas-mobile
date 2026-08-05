import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/logging/app_logger.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/workshop/di/workshop_providers.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/domain/repositories/workshop_repository.dart';
import 'package:look_atlas/features/workshop/domain/workshop_image_metadata.dart';
import 'package:look_atlas/features/workshop/presentation/controllers/workshop_error_messages.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';

class WorkshopController extends Notifier<WorkshopState> {
  static const double _pickMaxWidth = 1600;
  static const int _pickQuality = 85;
  static const int _maxImageBytes = 30 * 1024 * 1024;

  Timer? _pollTimer;
  bool _pollInFlight = false;
  bool _disposed = false;
  int _nextReferenceId = 0;

  WorkshopRepository get _repository => ref.read(workshopRepositoryProvider);

  @override
  WorkshopState build() {
    ref.onDispose(() {
      _disposed = true;
      _pollTimer?.cancel();
    });
    unawaited(Future<void>.microtask(load));
    return WorkshopState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading: state.history.isEmpty,
      failure: null,
    );
    final result = await _repository.load();
    if (_disposed) return;
    if (result case Err(:final failure)) {
      state = state.copyWith(isLoading: false, failure: failure);
      return;
    }
    final workspace = result.valueOrNull!;
    state = state.copyWith(
      isLoading: false,
      activeGeneration: workspace.active,
      history: _mergeActive(workspace.history, workspace.active),
      failure: null,
    );
    _schedulePolling(workspace.active);
  }

  Future<void> pickBaseImageFrom(ImageSource source) async {
    try {
      final image = await _pickImage(source);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!_acceptImage(bytes)) return;
      state = state.copyWith(
        baseImage: WorkshopBaseImage(
          source: image.path,
          bytes: bytes,
          fileName: _fileName(image, 'workshop-base.jpg'),
          orientation: readWorkshopImageOrientation(bytes),
        ),
        editMode: WorkshopEditMode.lock,
        result: null,
        validationMessage: null,
      );
    } on Exception catch (error) {
      AppLogger.warning('Workshop base image pick failed: $error');
      _showPickerFailure();
    }
  }

  void removeBaseImage() {
    state = state.copyWith(
      baseImage: null,
      result: null,
      validationMessage: null,
    );
  }

  void setMode(WorkshopEditMode mode) {
    state = state.copyWith(editMode: mode);
  }

  void updatePrompt(String prompt) {
    state = state.copyWith(prompt: prompt, validationMessage: null);
  }

  Future<void> addReferenceFrom(ImageSource source) async {
    if (state.referenceLimitReached) return;
    try {
      final image = await _pickImage(source);
      if (image == null || state.referenceLimitReached) return;
      final bytes = await image.readAsBytes();
      if (!_acceptImage(bytes)) return;
      _nextReferenceId++;
      final reference = WorkshopSample(
        id: 'picked-reference-$_nextReferenceId',
        label: 'Reference ${state.references.length + 1}',
        asset: image.path,
        bytes: bytes,
        fileName: _fileName(image, 'workshop-reference.jpg'),
      );
      state = state.copyWith(
        references: [...state.references, reference],
        validationMessage: null,
      );
    } on Exception catch (error) {
      AppLogger.warning('Workshop reference pick failed: $error');
      _showPickerFailure();
    }
  }

  void removeReference(String id) {
    state = state.copyWith(
      references: [
        for (final reference in state.references)
          if (reference.id != id) reference,
      ],
    );
  }

  Future<bool> generate() async {
    final base = state.baseImage;
    if (base == null) {
      state = state.copyWith(
        validationMessage: 'Upload a base image first.',
      );
      return false;
    }
    if (!state.hasPrompt) {
      state = state.copyWith(
        validationMessage: 'Write a prompt describing the edit you want.',
      );
      return false;
    }
    if (state.prompt.length > WorkshopState.maxPromptLength) {
      state = state.copyWith(
        validationMessage: 'Prompt must be 1000 characters or fewer.',
      );
      return false;
    }
    final baseBytes = base.bytes;
    if (baseBytes == null) {
      state = state.copyWith(
        validationMessage:
            'We lost track of your uploaded images. Please try again — '
            'your credit was refunded.',
      );
      return false;
    }
    if (state.isGenerating) return false;

    final pending = WorkshopGeneration(
      id: 'pending',
      status: WorkshopGenerationStatus.pending,
      prompt: state.prompt.trim(),
    );
    state = state.copyWith(
      activeGeneration: pending,
      result: null,
      validationMessage: null,
      failure: null,
    );
    final result = await _repository.generate(
      WorkshopGenerateRequest(
        base: WorkshopUpload(
          bytes: baseBytes,
          fileName: base.fileName ?? 'workshop-base.jpg',
        ),
        references: [
          for (final reference in state.references)
            WorkshopUpload(
              bytes: reference.bytes,
              fileName: reference.fileName,
            ),
        ],
        prompt: state.prompt.trim(),
        mode: state.editMode,
      ),
    );
    if (_disposed) return false;
    if (result case Err(:final failure)) {
      state = state.copyWith(
        activeGeneration: null,
        failure: failure,
        validationMessage: workshopGenerationFailureMessage(failure),
      );
      return false;
    }
    final generation = result.valueOrNull!;
    _applyGeneration(generation);
    return true;
  }

  void selectHistory(int index) {
    if (index < 0 || index >= state.history.length) return;
    state = state.copyWith(selectedHistoryIndex: index);
  }

  Future<Result<Uint8List>> downloadGeneration(
    WorkshopGeneration generation,
  ) {
    final imageUrl = generation.imageUrl;
    if (imageUrl == null) {
      return Future.value(
        const Err(ValidationFailure('This generation has no image yet.')),
      );
    }
    return _repository.downloadImage(imageUrl);
  }

  Future<Failure?> saveGeneration(WorkshopGeneration generation) async {
    final result = await downloadGeneration(generation);
    if (result case Err(:final failure)) return failure;
    try {
      await ref
          .read(imageSaveServiceProvider)
          .save(
            result.valueOrNull!,
            fileName: workshopImageFileName(
              result.valueOrNull!,
              prefix: 'look-atlas',
              generationId: generation.id,
            ),
          );
      return null;
    } on Object catch (error, stack) {
      AppLogger.warning('Workshop image save failed: $error');
      return UnknownFailure(
        'Could not save this image.',
        cause: error,
        stackTrace: stack,
      );
    }
  }

  Future<bool> useGenerationAsBase(WorkshopGeneration generation) async {
    final result = await downloadGeneration(generation);
    if (_disposed) return false;
    if (result case Err(:final failure)) {
      state = state.copyWith(failure: failure);
      return false;
    }
    final bytes = result.valueOrNull!;
    state = state.copyWith(
      baseImage: WorkshopBaseImage(
        source: generation.imageUrl!,
        bytes: bytes,
        fileName: workshopImageFileName(
          bytes,
          prefix: 'workshop',
          generationId: generation.id,
        ),
        orientation: readWorkshopImageOrientation(bytes),
      ),
      editMode: WorkshopEditMode.lock,
      result: null,
      validationMessage: null,
      failure: null,
    );
    return true;
  }

  Future<bool> useResultAsBase() async {
    final result = state.result;
    return result != null && await useGenerationAsBase(result);
  }

  Future<Failure?> deleteGeneration(String generationId) async {
    if (state.deletingGenerationId != null) return null;
    state = state.copyWith(deletingGenerationId: generationId, failure: null);
    final result = await _repository.deleteGeneration(generationId);
    if (_disposed) return null;
    state = state.copyWith(deletingGenerationId: null);
    if (result case Err(:final failure)) {
      state = state.copyWith(failure: failure);
      return failure;
    }
    final history = [
      for (final generation in state.history)
        if (generation.id != generationId) generation,
    ];
    state = state.copyWith(
      history: history,
      selectedHistoryIndex: history.isEmpty
          ? 0
          : state.selectedHistoryIndex.clamp(0, history.length - 1),
      result: state.result?.id == generationId ? null : state.result,
      activeGeneration: state.activeGeneration?.id == generationId
          ? null
          : state.activeGeneration,
      failure: null,
    );
    return null;
  }

  Future<XFile?> _pickImage(ImageSource source) => ref
      .read(imagePickerProvider)
      .pickImage(
        source: source,
        maxWidth: _pickMaxWidth,
        imageQuality: _pickQuality,
      );

  bool _acceptImage(Uint8List bytes) {
    if (bytes.isEmpty) {
      state = state.copyWith(
        validationMessage: 'The selected image is empty. Choose another.',
      );
      return false;
    }
    if (bytes.length > _maxImageBytes) {
      state = state.copyWith(
        validationMessage: 'Images must be 30 MB or smaller.',
      );
      return false;
    }
    return true;
  }

  void _showPickerFailure() {
    state = state.copyWith(
      validationMessage: 'Could not open your camera or photo library.',
    );
  }

  void _applyGeneration(WorkshopGeneration generation) {
    final history = _replaceGeneration(state.history, generation);
    if (generation.isActive) {
      state = state.copyWith(
        activeGeneration: generation,
        history: history,
        failure: null,
      );
      _schedulePolling(generation);
      return;
    }
    _pollTimer?.cancel();
    state = state.copyWith(
      activeGeneration: null,
      history: history,
      result: generation.hasImage ? generation : null,
      failure: null,
      validationMessage: workshopCompletedGenerationMessage(generation),
    );
    unawaited(_refreshHistory());
  }

  void _schedulePolling(WorkshopGeneration? active) {
    _pollTimer?.cancel();
    if (active == null || !active.isActive || active.id == 'pending') return;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_poll(active.id)),
    );
  }

  Future<void> _poll(String generationId) async {
    if (_pollInFlight) return;
    _pollInFlight = true;
    final result = await _repository.getGeneration(generationId);
    _pollInFlight = false;
    if (_disposed) return;
    if (result case Err(:final failure)) {
      state = state.copyWith(failure: failure);
      return;
    }
    _applyGeneration(result.valueOrNull!);
  }

  Future<void> _refreshHistory() async {
    final result = await _repository.getGenerations();
    if (_disposed) return;
    if (result case Ok(:final value)) {
      state = state.copyWith(history: value, failure: null);
    }
  }

  List<WorkshopGeneration> _mergeActive(
    List<WorkshopGeneration> history,
    WorkshopGeneration? active,
  ) => active == null ? history : _replaceGeneration(history, active);

  List<WorkshopGeneration> _replaceGeneration(
    List<WorkshopGeneration> history,
    WorkshopGeneration generation,
  ) => [
    generation,
    for (final item in history)
      if (item.id != generation.id) item,
  ];

  String _fileName(XFile image, String fallback) =>
      image.name.trim().isEmpty ? fallback : image.name;
}
