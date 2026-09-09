import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateContentUIState {
  const CreateContentUIState({
    this.leftOpen = false,
    this.rightOpen = false,
    this.preview = false,
    this.canvasZoom = 0.94,
    this.exportOpen = false,
    this.leaving = false,
    this.tool,
    this.search = '',
    this.exportStatus = 'idle',
    this.exportProgress,
    this.exportError,
    this.signedUrl,
    this.sessionVersion = 0,
    this.discardingDraftId,
  });

  final bool leftOpen;
  final bool rightOpen;
  final bool preview;
  final double canvasZoom;
  final bool exportOpen;
  final bool leaving;
  final String? tool;
  final String search;
  final String exportStatus;
  final double? exportProgress;
  final String? exportError;
  final String? signedUrl;
  final int sessionVersion;
  final String? discardingDraftId;

  CreateContentUIState copyWith({
    bool? leftOpen,
    bool? rightOpen,
    bool? preview,
    double? canvasZoom,
    bool? exportOpen,
    bool? leaving,
    String? Function()? tool,
    String? search,
    String? exportStatus,
    double? Function()? exportProgress,
    String? Function()? exportError,
    String? Function()? signedUrl,
    int? sessionVersion,
    String? Function()? discardingDraftId,
  }) {
    return CreateContentUIState(
      leftOpen: leftOpen ?? this.leftOpen,
      rightOpen: rightOpen ?? this.rightOpen,
      preview: preview ?? this.preview,
      canvasZoom: canvasZoom ?? this.canvasZoom,
      exportOpen: exportOpen ?? this.exportOpen,
      leaving: leaving ?? this.leaving,
      tool: tool != null ? tool() : this.tool,
      search: search ?? this.search,
      exportStatus: exportStatus ?? this.exportStatus,
      exportProgress: exportProgress != null
          ? exportProgress()
          : this.exportProgress,
      exportError: exportError != null ? exportError() : this.exportError,
      signedUrl: signedUrl != null ? signedUrl() : this.signedUrl,
      sessionVersion: sessionVersion ?? this.sessionVersion,
      discardingDraftId: discardingDraftId != null
          ? discardingDraftId()
          : this.discardingDraftId,
    );
  }
}

class CreateContentController extends Notifier<CreateContentUIState> {
  @override
  CreateContentUIState build() => const CreateContentUIState();

  void openPanel({required bool left, bool export = false}) {
    state = state.copyWith(
      leftOpen: left,
      rightOpen: !left,
      exportOpen: export,
      preview: false,
    );
  }

  void openRightPanel() {
    state = state.copyWith(
      rightOpen: true,
      leftOpen: false,
      exportOpen: false,
    );
  }

  void closePanels() {
    state = state.copyWith(
      leftOpen: false,
      rightOpen: false,
      exportOpen: false,
    );
  }

  void togglePreview() {
    state = state.copyWith(
      preview: !state.preview,
      leftOpen: false,
      rightOpen: false,
    );
  }

  void setPreview({required bool preview}) {
    state = state.copyWith(preview: preview);
  }

  void setCanvasZoom(double zoom) {
    state = state.copyWith(canvasZoom: zoom);
  }

  void setTool(String? tool) {
    state = state.copyWith(tool: () => tool);
  }

  void setSearch(String query) {
    state = state.copyWith(search: query);
  }

  void setLeaving({required bool leaving}) {
    state = state.copyWith(leaving: leaving);
  }

  void startExport() {
    state = state.copyWith(
      exportStatus: 'preparing',
      exportProgress: () => null,
      exportError: () => null,
      signedUrl: () => null,
    );
  }

  void updateExportProgress(double? progress) {
    state = state.copyWith(exportProgress: () => progress);
  }

  void setExportIdle() {
    state = state.copyWith(exportStatus: 'idle');
  }

  void setExportDone({String? signedUrl}) {
    state = state.copyWith(
      exportStatus: 'done',
      signedUrl: () => signedUrl,
    );
  }

  void setExportError(String error) {
    state = state.copyWith(
      exportStatus: 'error',
      exportProgress: () => null,
      exportError: () => error,
    );
  }

  void notifySessionChanged() {
    state = state.copyWith(sessionVersion: state.sessionVersion + 1);
  }

  void setDiscardingDraftId(String? id) {
    state = state.copyWith(discardingDraftId: () => id);
  }
}

final NotifierProvider<CreateContentController, CreateContentUIState>
createContentControllerProvider =
    NotifierProvider.autoDispose<CreateContentController, CreateContentUIState>(
      CreateContentController.new,
    );

class VideoReviewState {
  const VideoReviewState({this.isInitialized = false, this.failed = false});
  final bool isInitialized;
  final bool failed;

  VideoReviewState copyWith({bool? isInitialized, bool? failed}) =>
      VideoReviewState(
        isInitialized: isInitialized ?? this.isInitialized,
        failed: failed ?? this.failed,
      );
}

class VideoReviewStateController extends Notifier<VideoReviewState> {
  VideoReviewStateController(this.url);
  final String url;

  @override
  VideoReviewState build() => const VideoReviewState();

  void setInitialized() =>
      state = state.copyWith(isInitialized: true, failed: false);
  void setFailed({required bool failed}) =>
      state = state.copyWith(failed: failed, isInitialized: false);
  void reset() => state = const VideoReviewState();
}

// Riverpod does not expose a stable public family type for this provider.
// ignore: specify_nonobvious_property_types
final videoReviewStateProvider = NotifierProvider.autoDispose
    .family<VideoReviewStateController, VideoReviewState, String>(
      VideoReviewStateController.new,
    );
