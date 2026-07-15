enum WorkshopEditMode {
  lock(
    'Lock this image',
    'Keep this exact image. Only change what you describe face, outfit, background detail, etc. The rest stays pixel-for-pixel identical.',
  ),
  inspiration(
    'Use as inspiration',
    "Generate a brand-new image, using this photo (and any references) as style and composition cues. Output won't match the base it'll be inspired by it.",
  );

  const WorkshopEditMode(this.title, this.body);

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
  const WorkshopBaseImage({required this.source, this.orientation});

  final String source;
  final WorkshopImageOrientation? orientation;
}

class WorkshopSample {
  const WorkshopSample({
    required this.id,
    required this.label,
    required this.asset,
  });

  final String id;
  final String label;
  final String asset;
}

class WorkshopHistoryItem {
  const WorkshopHistoryItem({
    required this.id,
    required this.image,
    required this.prompt,
    required this.createdAtLabel,
  });

  final String id;
  final String image;
  final String prompt;
  final String createdAtLabel;
}

class WorkshopState {
  const WorkshopState({
    required this.isUnlocked,
    required this.editMode,
    required this.references,
    required this.prompt,
    required this.isGenerating,
    required this.history,
    required this.selectedHistoryIndex,
    this.baseImage,
    this.resultImage,
    this.validationMessage,
  });

  factory WorkshopState.initial() => const WorkshopState(
    isUnlocked: false,
    editMode: WorkshopEditMode.lock,
    references: [],
    prompt: '',
    isGenerating: false,
    history: [],
    selectedHistoryIndex: 0,
  );

  final bool isUnlocked;
  final WorkshopEditMode editMode;
  final WorkshopBaseImage? baseImage;
  final List<WorkshopSample> references;
  final String prompt;
  final bool isGenerating;
  final String? resultImage;
  final List<WorkshopHistoryItem> history;
  final int selectedHistoryIndex;
  final String? validationMessage;

  bool get hasBaseImage => baseImage != null;
  bool get hasPrompt => prompt.trim().isNotEmpty;
  bool get hasResult => resultImage != null;
  bool get referenceLimitReached => references.length >= 4;
  bool get canGenerate => isUnlocked && hasBaseImage && hasPrompt;

  WorkshopState copyWith({
    bool? isUnlocked,
    WorkshopEditMode? editMode,
    Object? baseImage = _sentinel,
    List<WorkshopSample>? references,
    String? prompt,
    bool? isGenerating,
    Object? resultImage = _sentinel,
    List<WorkshopHistoryItem>? history,
    int? selectedHistoryIndex,
    Object? validationMessage = _sentinel,
  }) {
    return WorkshopState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      editMode: editMode ?? this.editMode,
      baseImage: baseImage == _sentinel
          ? this.baseImage
          : baseImage as WorkshopBaseImage?,
      references: references ?? this.references,
      prompt: prompt ?? this.prompt,
      isGenerating: isGenerating ?? this.isGenerating,
      resultImage: resultImage == _sentinel
          ? this.resultImage
          : resultImage as String?,
      history: history ?? this.history,
      selectedHistoryIndex: selectedHistoryIndex ?? this.selectedHistoryIndex,
      validationMessage: validationMessage == _sentinel
          ? this.validationMessage
          : validationMessage as String?,
    );
  }
}

const Object _sentinel = Object();
