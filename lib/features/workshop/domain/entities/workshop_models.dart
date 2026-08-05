import 'dart:typed_data';

import 'package:look_atlas/core/error/failure.dart';

enum WorkshopEditMode {
  lock(
    'locked',
    'Lock this image',
    'Keep this exact image. Only change what you describe face, outfit, background detail, etc. The rest stays pixel-for-pixel identical.',
  ),
  inspiration(
    'inspiration',
    'Use as inspiration',
    "Generate a brand-new image, using this photo (and any references) as style and composition cues. Output won't match the base it'll be inspired by it.",
  );

  const WorkshopEditMode(this.apiValue, this.title, this.body);

  final String apiValue;
  final String title;
  final String body;
}

enum WorkshopImageOrientation {
  portrait('Portrait'),
  landscape('Landscape'),
  square('Square');

  const WorkshopImageOrientation(this.label);

  factory WorkshopImageOrientation.fromDimensions(int width, int height) {
    if (width == height) return WorkshopImageOrientation.square;
    return width > height
        ? WorkshopImageOrientation.landscape
        : WorkshopImageOrientation.portrait;
  }

  final String label;
}

class WorkshopBaseImage {
  const WorkshopBaseImage({
    required this.source,
    this.bytes,
    this.fileName,
    this.orientation,
  });

  final String source;
  final Uint8List? bytes;
  final String? fileName;
  final WorkshopImageOrientation? orientation;
}

class WorkshopSample {
  const WorkshopSample({
    required this.id,
    required this.label,
    required this.asset,
    required this.bytes,
    required this.fileName,
  });

  final String id;
  final String label;
  final String asset;
  final Uint8List bytes;
  final String fileName;
}

class WorkshopUpload {
  const WorkshopUpload({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

class WorkshopGenerateRequest {
  const WorkshopGenerateRequest({
    required this.base,
    required this.references,
    required this.prompt,
    required this.mode,
  });

  final WorkshopUpload base;
  final List<WorkshopUpload> references;
  final String prompt;
  final WorkshopEditMode mode;
}

enum WorkshopGenerationStatus {
  pending,
  queued,
  processing,
  completed,
  failed,
  cancelled,
  unknown;

  factory WorkshopGenerationStatus.fromApi(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return WorkshopGenerationStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => WorkshopGenerationStatus.unknown,
    );
  }

  bool get isActive => const {
    WorkshopGenerationStatus.pending,
    WorkshopGenerationStatus.queued,
    WorkshopGenerationStatus.processing,
  }.contains(this);
}

class WorkshopGeneration {
  const WorkshopGeneration({
    required this.id,
    required this.status,
    this.prompt = '',
    this.imageUrl,
    this.createdAt,
    this.creditCost,
    this.errorMessage,
  });

  final String id;
  final WorkshopGenerationStatus status;
  final String prompt;
  final String? imageUrl;
  final DateTime? createdAt;
  final int? creditCost;
  final String? errorMessage;

  bool get isActive => status.isActive;
  bool get hasImage => imageUrl?.isNotEmpty ?? false;
}

class WorkshopWorkspace {
  const WorkshopWorkspace({required this.history, this.active});

  final WorkshopGeneration? active;
  final List<WorkshopGeneration> history;
}

class WorkshopState {
  const WorkshopState({
    required this.editMode,
    required this.references,
    required this.prompt,
    required this.history,
    required this.selectedHistoryIndex,
    required this.isLoading,
    this.baseImage,
    this.activeGeneration,
    this.result,
    this.failure,
    this.validationMessage,
    this.deletingGenerationId,
  });

  factory WorkshopState.initial() => const WorkshopState(
    editMode: WorkshopEditMode.lock,
    references: [],
    prompt: '',
    history: [],
    selectedHistoryIndex: 0,
    isLoading: true,
  );

  static const int maxPromptLength = 1000;

  final WorkshopEditMode editMode;
  final WorkshopBaseImage? baseImage;
  final List<WorkshopSample> references;
  final String prompt;
  final List<WorkshopGeneration> history;
  final int selectedHistoryIndex;
  final bool isLoading;
  final WorkshopGeneration? activeGeneration;
  final WorkshopGeneration? result;
  final Failure? failure;
  final String? validationMessage;
  final String? deletingGenerationId;

  bool get hasBaseImage => baseImage != null;
  bool get hasPrompt => prompt.trim().isNotEmpty;
  bool get hasResult => result?.hasImage ?? false;
  bool get isGenerating => activeGeneration?.isActive ?? false;
  bool get isStarting => activeGeneration?.id == 'pending';
  bool get isProcessing => isGenerating && !isStarting;
  bool get referenceLimitReached => references.length >= 4;
  bool get canGenerate =>
      hasBaseImage &&
      hasPrompt &&
      prompt.length <= maxPromptLength &&
      !isGenerating;

  WorkshopState copyWith({
    WorkshopEditMode? editMode,
    Object? baseImage = _sentinel,
    List<WorkshopSample>? references,
    String? prompt,
    List<WorkshopGeneration>? history,
    int? selectedHistoryIndex,
    bool? isLoading,
    Object? activeGeneration = _sentinel,
    Object? result = _sentinel,
    Object? failure = _sentinel,
    Object? validationMessage = _sentinel,
    Object? deletingGenerationId = _sentinel,
  }) {
    return WorkshopState(
      editMode: editMode ?? this.editMode,
      baseImage: baseImage == _sentinel
          ? this.baseImage
          : baseImage as WorkshopBaseImage?,
      references: references ?? this.references,
      prompt: prompt ?? this.prompt,
      history: history ?? this.history,
      selectedHistoryIndex: selectedHistoryIndex ?? this.selectedHistoryIndex,
      isLoading: isLoading ?? this.isLoading,
      activeGeneration: activeGeneration == _sentinel
          ? this.activeGeneration
          : activeGeneration as WorkshopGeneration?,
      result: result == _sentinel ? this.result : result as WorkshopGeneration?,
      failure: failure == _sentinel ? this.failure : failure as Failure?,
      validationMessage: validationMessage == _sentinel
          ? this.validationMessage
          : validationMessage as String?,
      deletingGenerationId: deletingGenerationId == _sentinel
          ? this.deletingGenerationId
          : deletingGenerationId as String?,
    );
  }
}

const Object _sentinel = Object();
