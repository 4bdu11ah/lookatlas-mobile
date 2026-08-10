part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootDetailState {
  const _ShootDetailState({
    this.jobId = '',
    this.job,
    this.isLoading = true,
    this.isActionRunning = false,
    this.failure,
    this.selectedImage,
    this.selectedShotIndex = 0,
    this.progressStatus,
    this.versions = const [],
    this.videoRequest = const ShootVideoRequest(),
  });

  final String jobId;
  final ShootJob? job;
  final bool isLoading;
  final bool isActionRunning;
  final Failure? failure;
  final ShootImage? selectedImage;
  final int selectedShotIndex;
  final ShootProgressStatus? progressStatus;
  final List<ShootImageVersion> versions;
  final ShootVideoRequest videoRequest;

  List<ShootImage> get images {
    final value = job;
    if (value == null) return const [];
    if (value.shots.isNotEmpty) {
      return [for (final shot in value.shots) ...shot.images];
    }
    return value.images;
  }

  _ShootDetailState copyWith({
    String? jobId,
    ShootJob? job,
    bool? isLoading,
    bool? isActionRunning,
    Failure? failure,
    ShootImage? selectedImage,
    int? selectedShotIndex,
    ShootProgressStatus? progressStatus,
    List<ShootImageVersion>? versions,
    ShootVideoRequest? videoRequest,
    bool clearFailure = false,
  }) => _ShootDetailState(
    jobId: jobId ?? this.jobId,
    job: job ?? this.job,
    isLoading: isLoading ?? this.isLoading,
    isActionRunning: isActionRunning ?? this.isActionRunning,
    failure: clearFailure ? null : failure ?? this.failure,
    selectedImage: selectedImage ?? this.selectedImage,
    selectedShotIndex: selectedShotIndex ?? this.selectedShotIndex,
    progressStatus: progressStatus ?? this.progressStatus,
    versions: versions ?? this.versions,
    videoRequest: videoRequest ?? this.videoRequest,
  );
}

class _ShootDetailController extends Notifier<_ShootDetailState> {
  Timer? _statusTimer;
  Timer? _detailTimer;
  Timer? _editTimer;
  bool _requestInFlight = false;
  bool _disposed = false;
  int _editPollCount = 0;

  ShootsRepository get _repository => ref.read(shootsRepositoryProvider);

  @override
  _ShootDetailState build() {
    ref.onDispose(() {
      _disposed = true;
      _cancelTimers();
    });
    return const _ShootDetailState();
  }

  Future<void> load(String jobId, {bool silent = false}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    if (!silent) {
      state = _ShootDetailState(jobId: jobId);
    }
    final result = await _repository.getJob(jobId);
    if (_disposed) return;
    _requestInFlight = false;
    if (result case Err(:final failure)) {
      state = state.copyWith(isLoading: false, failure: failure);
      return;
    }
    final job = result.valueOrNull!;
    final images = job.shots.isEmpty
        ? job.images
        : [for (final shot in job.shots) ...shot.images];
    state = state.copyWith(
      jobId: jobId,
      job: job,
      isLoading: false,
      selectedImage: state.selectedImage ?? images.firstOrNull,
      clearFailure: true,
    );
    _scheduleStatusPolling(job.isActive);
  }

  Future<Failure?> refresh() async {
    final statusResult = await _repository.getJobStatus(state.jobId);
    if (_disposed) return null;
    if (statusResult case Err(:final failure)) {
      state = state.copyWith(failure: failure);
      return failure;
    }
    _applyProgress(statusResult.valueOrNull!);
    await load(state.jobId, silent: true);
    return state.failure;
  }

  Future<Failure?> rerun() => _runJobAction(
    () => _repository.rerunJob(state.jobId),
    pollDetail: true,
  );

  Future<Failure?> cancel() => _runJobAction(
    () => _repository.cancelJob(state.jobId),
  );

  Future<Failure?> toggleApproval(ShootImage image) async {
    final approved = !image.approved;
    _replaceImage(image.copyWith(approved: approved));
    final result = await _repository.setImageApproval(
      state.jobId,
      image.id,
      approved: approved,
    );
    if (_disposed) return null;
    if (result case Err(:final failure)) {
      _replaceImage(image);
      state = state.copyWith(failure: failure);
      return failure;
    }
    return null;
  }

  Future<Result<Uint8List>> download(ShootImage image) =>
      _repository.downloadImage(state.jobId, image.id);

  Future<Failure?> exportApprovedImages() {
    final job = state.job;
    if (job == null)
      return Future.value(const UnknownFailure('Load the shoot first.'));
    return const ShootExportService().exportApprovedImages(
      job: job,
      download: download,
    );
  }

  void selectImage(ShootImage image, {int? shotIndex}) {
    state = state.copyWith(
      selectedImage: image,
      selectedShotIndex: shotIndex,
    );
  }

  Future<Failure?> loadVersions(ShootImage image) async {
    selectImage(image);
    final result = await _repository.getImageVersions(state.jobId, image.id);
    if (_disposed) return null;
    if (result case Err(:final failure)) return failure;
    state = state.copyWith(versions: result.valueOrNull);
    return null;
  }

  Future<Failure?> setActiveVersion(String versionId) async {
    final image = state.selectedImage;
    if (image == null) return const UnknownFailure('Select an image first.');
    final result = await _repository.setActiveImageVersion(
      state.jobId,
      image.id,
      versionId,
    );
    if (_disposed) return null;
    if (result case Err(:final failure)) return failure;
    await loadVersions(image);
    await load(state.jobId, silent: true);
    return null;
  }

  Future<Failure?> editImage(String prompt) async {
    final image = state.selectedImage;
    if (image == null) return const UnknownFailure('Select an image first.');
    state = state.copyWith(isActionRunning: true, clearFailure: true);
    final result = await _repository.editImage(state.jobId, image.id, prompt);
    if (_disposed) return null;
    state = state.copyWith(isActionRunning: false);
    if (result case Err(:final failure)) {
      state = state.copyWith(failure: failure);
      return failure;
    }
    _startEditPolling(image.id);
    return null;
  }

  Future<Failure?> reportImage({
    required ShootImage image,
    required String reason,
    required String comment,
  }) async {
    final trimmedComment = comment.trim();
    if (trimmedComment.length < 20 || trimmedComment.length > 1000) {
      return const UnknownFailure(
        'Tell us what is wrong in 20 to 1000 characters.',
      );
    }
    state = state.copyWith(isActionRunning: true, clearFailure: true);
    final result = await _repository.reportImage(
      state.jobId,
      image.id,
      reason: reason,
      comment: trimmedComment,
    );
    if (_disposed) return null;
    state = state.copyWith(isActionRunning: false);
    if (result case Err(:final failure)) {
      state = state.copyWith(failure: failure);
      return failure;
    }
    return null;
  }

  Future<Failure?> addVariation(String remarks) => _runJobAction(
    () => _repository.addVariation(
      state.jobId,
      state.selectedShotIndex,
      remarks,
    ),
    pollDetail: true,
  );

  Future<Failure?> redoHandShots() => _runJobAction(
    () => _repository.redoHandShots(state.jobId),
    pollDetail: true,
  );

  Future<Failure?> requestVideo() => _runJobAction(
    () => _repository.requestVideo(state.jobId, state.videoRequest),
    pollDetail: true,
  );

  void updateVideo({
    int? variationIndex,
    String? aspectRatio,
    String? videoTier,
    String? startingImageId,
  }) {
    final current = state.videoRequest;
    state = state.copyWith(
      videoRequest: ShootVideoRequest(
        variationIndex: variationIndex ?? current.variationIndex,
        aspectRatio: aspectRatio ?? current.aspectRatio,
        videoTier: videoTier ?? current.videoTier,
        startingImageId: startingImageId ?? current.startingImageId,
      ),
    );
  }

  Future<Failure?> _runJobAction(
    Future<Result<void>> Function() action, {
    bool pollDetail = false,
  }) async {
    state = state.copyWith(isActionRunning: true, clearFailure: true);
    final result = await action();
    if (_disposed) return null;
    state = state.copyWith(isActionRunning: false);
    if (result case Err(:final failure)) {
      state = state.copyWith(failure: failure);
      return failure;
    }
    await load(state.jobId, silent: true);
    if (pollDetail) _startDetailPolling();
    return null;
  }

  void _replaceImage(ShootImage replacement) {
    final job = state.job;
    if (job == null) return;
    List<ShootImage> replace(List<ShootImage> images) => [
      for (final image in images)
        if (image.id == replacement.id) replacement else image,
    ];
    state = state.copyWith(
      job: job.copyWith(
        images: replace(job.images),
        shots: [
          for (final shot in job.shots)
            ShootShot(
              index: shot.index,
              title: shot.title,
              description: shot.description,
              images: replace(shot.images),
            ),
        ],
      ),
      selectedImage: replacement,
    );
  }

  void _scheduleStatusPolling(bool active) {
    _statusTimer?.cancel();
    if (!active) return;
    _statusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_pollStatus()),
    );
  }

  Future<void> _pollStatus() async {
    final result = await _repository.getJobStatus(state.jobId);
    if (_disposed) return;
    final progress = result.valueOrNull;
    if (progress == null) return;
    final previous = state.job;
    final detailNeedsRefresh =
        previous == null ||
        previous.status != progress.status ||
        previous.progress != progress.progress;
    _applyProgress(progress);
    if (detailNeedsRefresh || !progress.isActive) {
      await load(state.jobId, silent: true);
    }
    if (!progress.isActive) {
      _statusTimer?.cancel();
    }
  }

  void _applyProgress(ShootProgressStatus progress) {
    final job = state.job;
    state = state.copyWith(
      progressStatus: progress,
      job: job?.copyWith(status: progress.status, progress: progress.progress),
    );
  }

  void _startDetailPolling() {
    _detailTimer?.cancel();
    var pollCount = 0;
    _detailTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await load(state.jobId, silent: true);
      pollCount++;
      final job = state.job;
      if (pollCount >= 60 ||
          (job != null && !job.isActive && !job.hasActiveMediaWork)) {
        timer.cancel();
      }
    });
  }

  void _startEditPolling(String imageId) {
    _editTimer?.cancel();
    _editPollCount = 0;
    _editTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _editPollCount++;
      final result = await _repository.getImageEditStatus(
        state.jobId,
        imageId,
      );
      if (_disposed) {
        timer.cancel();
        return;
      }
      final status = result.valueOrNull;
      if (status == ShootImageEditState.completed) {
        timer.cancel();
        await load(state.jobId, silent: true);
      } else if (status == ShootImageEditState.failed ||
          _editPollCount >= 100) {
        timer.cancel();
      }
    });
  }

  void _cancelTimers() {
    _statusTimer?.cancel();
    _detailTimer?.cancel();
    _editTimer?.cancel();
  }
}

final NotifierProvider<_ShootDetailController, _ShootDetailState>
_shootDetailControllerProvider =
    NotifierProvider.autoDispose<_ShootDetailController, _ShootDetailState>(
      _ShootDetailController.new,
    );
