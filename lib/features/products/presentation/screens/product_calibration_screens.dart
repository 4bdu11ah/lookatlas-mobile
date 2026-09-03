part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _openCalibration(
  BuildContext context,
  WidgetRef ref,
  _Product product,
  ValueChanged<String> onToast, {
  String? initialStage,
}) {
  if (!_requestProductsManageAccess(context, ref)) return Future.value();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'product_size'),
      builder: (_) => _ProductCalibrationScreen(
        product: product,
        repository: ref.read(productsRepositoryProvider),
        initialStage: initialStage,
        onSaved: () {
          unawaited(ref.read(_productsControllerProvider.notifier).reload());
          onToast('Calibration saved');
        },
      ),
    ),
  );
}

class _ProductCalibrationState {
  const _ProductCalibrationState({
    this.step = _CalibrationStep.method,
    this.workspace,
    this.failure,
    this.bodyArea = 'full_body_front',
    this.isLoading = true,
    this.isMutating = false,
    this.cutout,
    this.sourceUpload,
    this.bodyZoom = 1,
    this.placementX = 0.5,
    this.placementY = 0.56,
    this.placementScale = 1,
    this.placementRotation = 0,
    this.bodyPreset = 'Female',
    this.renders = const [],
    this.feedback = '',
  });

  final _CalibrationStep step;
  final ProductCalibrationWorkspace? workspace;
  final Failure? failure;
  final String bodyArea;
  final bool isLoading;
  final bool isMutating;
  final ProductUpload? cutout;
  final ProductUpload? sourceUpload;
  final double bodyZoom;
  final double placementX;
  final double placementY;
  final double placementScale;
  final double placementRotation;
  final String bodyPreset;
  final List<CalibrationRender> renders;
  final String feedback;

  CalibrationRender? get selectedRender => renders.firstOrNull;

  _ProductCalibrationState copyWith({
    _CalibrationStep? step,
    ProductCalibrationWorkspace? workspace,
    Failure? failure,
    String? bodyArea,
    bool? isLoading,
    bool? isMutating,
    ProductUpload? cutout,
    ProductUpload? sourceUpload,
    double? bodyZoom,
    double? placementX,
    double? placementY,
    double? placementScale,
    double? placementRotation,
    String? bodyPreset,
    List<CalibrationRender>? renders,
    String? feedback,
    bool clearFailure = false,
  }) => _ProductCalibrationState(
    step: step ?? this.step,
    workspace: workspace ?? this.workspace,
    failure: clearFailure ? null : failure ?? this.failure,
    bodyArea: bodyArea ?? this.bodyArea,
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    cutout: cutout ?? this.cutout,
    sourceUpload: sourceUpload ?? this.sourceUpload,
    bodyZoom: bodyZoom ?? this.bodyZoom,
    placementX: placementX ?? this.placementX,
    placementY: placementY ?? this.placementY,
    placementScale: placementScale ?? this.placementScale,
    placementRotation: placementRotation ?? this.placementRotation,
    bodyPreset: bodyPreset ?? this.bodyPreset,
    renders: renders ?? this.renders,
    feedback: feedback ?? this.feedback,
  );
}

class _ProductCalibrationStateController
    extends Notifier<_ProductCalibrationState> {
  _ProductCalibrationStateController(this.productId);

  final String productId;

  @override
  _ProductCalibrationState build() => const _ProductCalibrationState();

  _ProductCalibrationState get _value => state;
  set _value(_ProductCalibrationState value) {
    if (_value == value) return;
    state = value;
  }
}

// Riverpod does not expose a stable public family type for this provider.
// ignore: specify_nonobvious_property_types
final _productCalibrationStateProvider = NotifierProvider.autoDispose
    .family<
      _ProductCalibrationStateController,
      _ProductCalibrationState,
      String
    >(
      _ProductCalibrationStateController.new,
    );

class _ProductCalibrationScreen extends ConsumerStatefulWidget {
  const _ProductCalibrationScreen({
    required this.product,
    required this.repository,
    required this.onSaved,
    this.initialStage,
  });

  final _Product product;
  final ProductsRepository repository;
  final VoidCallback onSaved;
  final String? initialStage;

  @override
  ConsumerState<_ProductCalibrationScreen> createState() =>
      _ProductCalibrationScreenState();
}

class _ProductCalibrationScreenState
    extends ConsumerState<_ProductCalibrationScreen>
    with WidgetsBindingObserver {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _renderFeedbackController =
      TextEditingController();
  Timer? _renderPollTimer;
  DateTime? _renderPollStartedAt;
  final Map<String, String> _pendingMutationIds = {};
  var _isInitialCalibrationLoad = true;
  var _openedWithSavedCalibration = false;
  var _didApplyInitialStage = false;

  _ProductCalibrationStateController get _stateController => ref.read(
    _productCalibrationStateProvider(widget.product.id).notifier,
  );

  _ProductCalibrationState get _state =>
      ref.read(_productCalibrationStateProvider(widget.product.id));
  set _state(_ProductCalibrationState value) => _stateController._value = value;

  _CalibrationStep get _step => _state.step;
  set _step(_CalibrationStep value) => _state = _state.copyWith(step: value);
  ProductCalibrationWorkspace? get _workspace => _state.workspace;
  set _workspace(ProductCalibrationWorkspace? value) {
    if (value != null) _state = _state.copyWith(workspace: value);
  }

  Failure? get _failure => _state.failure;
  set _failure(Failure? value) => _state = _state.copyWith(
    failure: value,
    clearFailure: value == null,
  );
  String get _bodyArea => _state.bodyArea;
  set _bodyArea(String value) => _state = _state.copyWith(bodyArea: value);
  bool get _isLoading => _state.isLoading;
  set _isLoading(bool value) => _state = _state.copyWith(isLoading: value);
  bool get _isMutating => _state.isMutating;
  set _isMutating(bool value) => _state = _state.copyWith(isMutating: value);
  ProductUpload? get _cutout => _state.cutout;
  set _cutout(ProductUpload? value) {
    if (value != null) _state = _state.copyWith(cutout: value);
  }

  ProductUpload? get _sourceUpload => _state.sourceUpload;
  set _sourceUpload(ProductUpload? value) {
    if (value != null) _state = _state.copyWith(sourceUpload: value);
  }

  double get _bodyZoom => _state.bodyZoom;
  set _bodyZoom(double value) =>
      _state = _state.copyWith(bodyZoom: value.clamp(0.7, 2).toDouble());

  double get _placementX => _state.placementX;
  set _placementX(double value) => _state = _state.copyWith(placementX: value);
  double get _placementY => _state.placementY;
  set _placementY(double value) => _state = _state.copyWith(placementY: value);
  double get _placementScale => _state.placementScale;
  set _placementScale(double value) =>
      _state = _state.copyWith(placementScale: value);
  double get _placementRotation => _state.placementRotation;
  set _placementRotation(double value) =>
      _state = _state.copyWith(placementRotation: value);
  String get _bodyPreset => _state.bodyPreset;
  set _bodyPreset(String value) => _state = _state.copyWith(bodyPreset: value);
  List<CalibrationRender> get _renders => _state.renders;
  set _renders(List<CalibrationRender> value) =>
      _state = _state.copyWith(renders: value);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(Future.microtask(_load));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_renders.firstOrNull?.status.isPending ?? false)) {
      _startRenderPolling();
      unawaited(_pollRender());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _renderPollTimer?.cancel();
    _notesController.dispose();
    _searchController.dispose();
    _renderFeedbackController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _isLoading = true;
    _failure = null;
    final results = await Future.wait([
      widget.repository.loadCalibration(widget.product.id),
      widget.repository.getCalibrationRenders(widget.product.id),
    ]);
    final result = results[0] as Result<ProductCalibrationWorkspace>;
    final renderResult = results[1] as Result<List<CalibrationRender>>;
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        if (_isInitialCalibrationLoad) {
          _openedWithSavedCalibration =
              value.calibration.isLegacyOnly ||
              value.calibration.wornPhotoUrl != null ||
              value.calibration.cutoutUrl != null;
          _isInitialCalibrationLoad = false;
        }
        _workspace = value;
        _renders = renderResult.valueOrNull ?? const [];
        final preferredAreas = _recommendedBodyAreas(widget.product);
        _bodyArea =
            value.calibration.bodyArea ??
            value.outlines
                .map((outline) => outline.id)
                .firstWhere(
                  preferredAreas.contains,
                  orElse: () => value.outlines.isEmpty
                      ? _bodyArea
                      : value.outlines.first.id,
                );
        _notesController.text = value.calibration.userNotes ?? '';
        final placement = value.calibration.cutoutPlacement;
        _placementX = _normalizedPlacement(placement['x'], 1000, _placementX);
        _placementY = _normalizedPlacement(placement['y'], 1500, _placementY);
        _placementScale = _placementValue(placement['w'], 220) / 220;
        _placementRotation = switch (placement['rotation']) {
          final num value => value.toDouble(),
          _ => 0,
        };
        _step = switch (value.calibration.status) {
          ProductCalibrationStatus.fitPending ||
          ProductCalibrationStatus.fitRendering ||
          ProductCalibrationStatus.fitReady ||
          ProductCalibrationStatus.fitFailed => _CalibrationStep.fit,
          ProductCalibrationStatus.calibrated ||
          ProductCalibrationStatus.changesPending ||
          ProductCalibrationStatus.saveReady => _CalibrationStep.review,
          _ when value.calibration.isLegacyOnly => _CalibrationStep.review,
          _
              when value.calibration.hasPlacement ||
                  value.calibration.wornPhotoUrl != null =>
            _CalibrationStep.review,
          _ when value.calibration.cutoutUrl != null =>
            _CalibrationStep.placeProduct,
          _ => _CalibrationStep.method,
        };
        if (_renders.firstOrNull?.status.isPending ?? false) {
          _step = _CalibrationStep.fit;
          _startRenderPolling();
        }
        if (!_didApplyInitialStage && widget.initialStage != null) {
          _step = _stepForRouteStage(widget.initialStage!);
          _didApplyInitialStage = true;
        }
        _isLoading = false;
      case Err(:final failure):
        _isLoading = false;
        _failure = failure;
    }
  }

  Future<ProductUpload?> _pickUpload(String title) =>
      _pickProductPhoto(context, ref, title: title);

  bool get _navigationBlocked =>
      _isMutating && _step != _CalibrationStep.removingBackground;

  void _handleSystemBack() {
    if (_navigationBlocked) return;
    switch (_step) {
      case _CalibrationStep.method:
        Navigator.pop(context);
      case _CalibrationStep.overview:
        _step = _CalibrationStep.method;
      case _CalibrationStep.bodyView:
        _step = _CalibrationStep.pickPhoto;
      case _CalibrationStep.pickPhoto:
        _step = _CalibrationStep.overview;
      case _CalibrationStep.removingBackground:
        _step = _CalibrationStep.pickPhoto;
      case _CalibrationStep.confirmCutout:
        _step = _CalibrationStep.pickPhoto;
      case _CalibrationStep.placeProduct:
        _step = _cutout == null
            ? _CalibrationStep.pickPhoto
            : _CalibrationStep.confirmCutout;
      case _CalibrationStep.fit:
        _step = _CalibrationStep.placeProduct;
      case _CalibrationStep.review:
        if (_openedWithSavedCalibration) {
          Navigator.pop(context);
        } else {
          _step = _workspace?.calibration.wornPhotoUrl != null
              ? _CalibrationStep.wornPhoto
              : _CalibrationStep.placeProduct;
        }
      case _CalibrationStep.success:
        widget.onSaved();
        Navigator.pop(context);
      case _CalibrationStep.wornPhoto || _CalibrationStep.copyFrom:
        _step = _CalibrationStep.method;
    }
  }

  static double _placementValue(Object? value, double fallback) =>
      value is num && value > 0 ? value.toDouble() : fallback;

  static double _normalizedPlacement(
    Object? value,
    double maximum,
    double fallback,
  ) => value is num ? (value.toDouble() / maximum).clamp(0.1, 0.9) : fallback;

  static Set<String> _recommendedBodyAreas(_Product product) {
    final category = product.category.toLowerCase();
    final subtype = (product.subtype ?? '').toLowerCase();
    if (category == 'jewelry') {
      if (subtype.contains('ring')) return {'hand_palm', 'hand_side'};
      if (subtype.contains('necklace') || subtype.contains('pendant')) {
        return {'neck_chest'};
      }
      if (subtype.contains('earring')) return {'ear_profile', 'face_front'};
      if (subtype.contains('bracelet')) return {'wrist_side'};
    }
    if (category == 'bags') {
      if (subtype.contains('tote')) return {'full_body_front', 'hand_side'};
      if (subtype.contains('clutch')) return {'hand_side', 'full_body_front'};
      return {'full_body_front', 'hand_side'};
    }
    if (category == 'watches') return {'wrist_side'};
    if (category == 'eyewear') return {'face_front', 'head_3q'};
    if (category == 'shoes') return {'foot_side', 'full_body_front'};
    if (category == 'accessories') {
      return {'full_body_front', 'waist_front', 'head_3q'};
    }
    return {'full_body_front'};
  }

  static _CalibrationStep _stepForRouteStage(String stage) => switch (stage) {
    'overview' => _CalibrationStep.overview,
    'photo' => _CalibrationStep.wornPhoto,
    'body' => _CalibrationStep.bodyView,
    'source' => _CalibrationStep.pickPhoto,
    'cutout' || 'crop' || 'fix' => _CalibrationStep.confirmCutout,
    'place' => _CalibrationStep.placeProduct,
    'render' => _CalibrationStep.fit,
    'copy-from' => _CalibrationStep.copyFrom,
    'review' || 'legacy-preview' => _CalibrationStep.review,
    _ => _CalibrationStep.method,
  };

  void _updatePlacement(double x, double y, double scale) {
    _placementX = x.clamp(0.1, 0.9);
    _placementY = y.clamp(0.1, 0.9);
    _placementScale = scale.clamp(0.5, 2);
  }

  void _changeBodyArea(String value) {
    if (_bodyArea == value) return;
    _bodyArea = value;
    _updatePlacement(0.5, 0.56, 1);
    _placementRotation = 0;
  }

  Future<void> _uploadCutout() async {
    final upload = await _pickUpload('Pick a product photo');
    if (upload == null || !mounted) return;
    await _processCutout(upload);
  }

  Future<void> _useExistingProductPhoto(String source) async {
    final upload = await _existingProductPhotoUpload(source);
    if (upload == null || !mounted) return;
    try {
      await _processCutout(upload);
    } finally {
      final path = upload.path;
      if (path != null) {
        try {
          await File(path).delete();
        } on FileSystemException {
          // Temporary file may already have been removed by the platform.
        }
      }
    }
  }

  Future<ProductUpload?> _existingProductPhotoUpload(String source) async {
    try {
      final Uint8List bytes;
      if (source.startsWith('assets/')) {
        final asset = await rootBundle.load(source);
        bytes = asset.buffer.asUint8List();
      } else {
        final request = await HttpClient().getUrl(Uri.parse(source));
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) return null;
        final data = await response.fold<List<int>>(
          <int>[],
          (value, chunk) => value..addAll(chunk),
        );
        bytes = Uint8List.fromList(data);
      }
      final file = await File(
        '${Directory.systemTemp.path}/${widget.product.id}-source-${DateTime.now().microsecondsSinceEpoch}.jpg',
      ).writeAsBytes(bytes);
      return ProductUpload(
        bytes: bytes,
        fileName: '${widget.product.id}-source.jpg',
        path: file.path,
        localKey: widget.product.productPhotos
            .where((photo) => photo.url == source)
            .firstOrNull
            ?.id,
      );
    } on Exception {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not load that product photo.');
      }
      return null;
    }
  }

  Future<void> _processCutout(ProductUpload upload) async {
    _sourceUpload = upload;
    _isMutating = true;
    _step = _CalibrationStep.removingBackground;
    final cutout = await _removeBackground(upload);
    if (!mounted) return;
    if (cutout == null) {
      _isMutating = false;
      _step = _CalibrationStep.pickPhoto;
      return;
    }
    _cutout = cutout;
    _isMutating = false;
    _step = _CalibrationStep.confirmCutout;
  }

  Future<void> _confirmCutout() async {
    if (_cutout == null || _isMutating) return;
    _step = _CalibrationStep.placeProduct;
  }

  Future<void> _cropCutout() async {
    final cutout = _cutout;
    if (cutout == null || _isMutating) return;
    await _showProductReferenceCrop(
      context,
      source: cutout,
      isReplacement: true,
      preserveTransparency: true,
      onSave: (cropped) async {
        _cutout = ProductUpload(
          bytes: cropped.bytes,
          fileName: cropped.fileName,
          localKey: cutout.localKey,
        );
        return true;
      },
    );
  }

  Future<void> _fixCutout() async {
    final source = _sourceUpload;
    if (source == null || _isMutating) return;
    final temporary = File(
      '${Directory.systemTemp.path}/${widget.product.id}-cutout-fix-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    try {
      await temporary.writeAsBytes(source.bytes);
      final retrySource = ProductUpload(
        bytes: source.bytes,
        fileName: source.fileName,
        path: temporary.path,
        localKey: source.localKey,
      );
      await _processCutout(retrySource);
    } finally {
      try {
        await temporary.delete();
      } on FileSystemException {
        // The platform may clean temporary files before this callback runs.
      }
    }
  }

  Future<ProductUpload?> _removeBackground(ProductUpload upload) async {
    final imagePath = upload.path;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final isModelReady = await NativeCutout.isModelAvailable();
        if (isModelReady || await NativeCutout.downloadModel()) {
          final result = await NativeCutout.removeBackground(
            imagePath,
            options: const CutoutOptions(
              cropToSubject: true,
              writeToCache: false,
            ),
          );
          if (!mounted) return null;
          if (result case CutoutBytesSuccess(:final pngBytes)) {
            return ProductUpload(
              bytes: pngBytes,
              fileName: '${widget.product.id}-cutout.png',
              localKey: upload.localKey,
            );
          }
        }
      } on Exception {
        // The authenticated server fallback below handles unsupported devices,
        // model-download failures, and native processing errors.
      }
    }
    final fallback = await widget.repository.removeBackgroundFallback(
      widget.product.id,
      upload,
    );
    if (!mounted) return null;
    switch (fallback) {
      case Ok(:final value):
        return value;
      case Err(:final failure):
        AppSnackBar.showError(
          context,
          failure.message.isEmpty
              ? 'We could not remove the background for that photo. Please try a different photo.'
              : failure.message,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(_productCalibrationStateProvider(widget.product.id));
    final workspace = _workspace;
    final body = _isLoading
        ? const _ProductCalibrationLoadingShimmer()
        : workspace == null
        ? _ProductLoadFailure(
            message: _failure?.message ?? 'Could not load calibration.',
            onRetry: _load,
          )
        : switch (_step) {
            _CalibrationStep.method => _CalibrationMethodStep(
              onBody: () => _step = _CalibrationStep.overview,
              onWorn: () => _step = _CalibrationStep.wornPhoto,
              onCopy: () => _step = _CalibrationStep.copyFrom,
            ),
            _CalibrationStep.overview => _CalibrationOverviewStep(
              product: widget.product,
              onBack: () => _step = _CalibrationStep.method,
              onNext: () => _step = _CalibrationStep.pickPhoto,
            ),
            _CalibrationStep.bodyView => _CalibrationBodyStep(
              outlines: workspace.outlines,
              selectedBodyArea: _bodyArea,
              onSelected: _changeBodyArea,
              onBack: () => _step = _CalibrationStep.pickPhoto,
              onNext: () => _step = _CalibrationStep.pickPhoto,
            ),
            _CalibrationStep.pickPhoto => _CalibrationPickPhotoStep(
              product: widget.product,
              bodyArea: _bodyArea,
              onBack: () => _step = _CalibrationStep.overview,
              onNext: _uploadCutout,
              onPhotoSelected: _useExistingProductPhoto,
              onChangeBody: () => _step = _CalibrationStep.bodyView,
            ),
            _CalibrationStep.removingBackground => _CalibrationProgressStep(
              onBack: () => _step = _CalibrationStep.pickPhoto,
            ),
            _CalibrationStep.confirmCutout => _CalibrationConfirmCutoutStep(
              product: widget.product,
              cutout: _cutout,
              isUploading: _isMutating,
              onBack: () => _step = _CalibrationStep.pickPhoto,
              onNext: _confirmCutout,
              onCrop: _cropCutout,
              onFix: _fixCutout,
            ),
            _CalibrationStep.placeProduct => _CalibrationPlaceStep(
              product: widget.product,
              bodyArea: _bodyArea,
              cutout: _cutout,
              bodyZoom: _bodyZoom,
              placementX: _placementX,
              placementY: _placementY,
              placementScale: _placementScale,
              placementRotation: _placementRotation,
              onPlacementChanged: _updatePlacement,
              onRotationChanged: (value) => _placementRotation = value,
              onBodyZoomChanged: (value) => _bodyZoom = value,
              onBack: () => _step = _CalibrationStep.confirmCutout,
              onNext: _continueToFit,
            ),
            _CalibrationStep.fit => _CalibrationFitStep(
              bodyPreset: _bodyPreset,
              renders: _renders,
              feedbackController: _renderFeedbackController,
              isMutating: _isMutating,
              onBodyPresetChanged: (value) => _bodyPreset = value,
              onRender: _startRender,
              onRegenerate: () => _startRender(regenerate: true),
              onApprove: _approveRender,
              onSelectRender: (render) => _renders = [
                render,
                ..._renders.where((item) => item.id != render.id),
              ],
              onBack: () => _step = _CalibrationStep.placeProduct,
            ),
            _CalibrationStep.review => _CalibrationReviewStep(
              product: widget.product,
              bodyArea: _bodyArea,
              cutout: _cutout,
              placementX: _placementX,
              placementY: _placementY,
              placementScale: _placementScale,
              placementRotation: _placementRotation,
              notesController: _notesController,
              onAdjust: () => _step = workspace.calibration.wornPhotoUrl != null
                  ? _CalibrationStep.wornPhoto
                  : _CalibrationStep.placeProduct,
              onClose: _openedWithSavedCalibration
                  ? () => Navigator.pop(context)
                  : () => _step = workspace.calibration.wornPhotoUrl != null
                        ? _CalibrationStep.wornPhoto
                        : _CalibrationStep.placeProduct,
              onSave: _save,
              onDiscard: _confirmDiscardChanges,
              onRemoveWornPhoto: _confirmDeleteWornPhoto,
              isSaving: _isMutating,
              canDiscard:
                  workspace.calibration.status ==
                      ProductCalibrationStatus.changesPending ||
                  workspace.calibration.status ==
                      ProductCalibrationStatus.saveReady,
              isActive:
                  workspace.calibration.status ==
                  ProductCalibrationStatus.calibrated,
              wornPhotoUrl: workspace.calibration.wornPhotoUrl,
              fitImageUrl: _renders.firstOrNull?.imageUrl,
              isLegacy: workspace.calibration.isLegacyOnly,
            ),
            _CalibrationStep.success => _CalibrationSuccessStep(
              onDone: () {
                widget.onSaved();
                Navigator.pop(context);
              },
            ),
            _CalibrationStep.wornPhoto => _CalibrationWornStep(
              onBack: () => _step = _CalibrationStep.method,
              onUpload: _uploadWornPhoto,
              isUploading: _isMutating,
            ),
            _CalibrationStep.copyFrom => _CalibrationCopyStep(
              searchController: _searchController,
              onBack: () => _step = _CalibrationStep.method,
              products:
                  (workspace.calibratedProducts
                      .where((product) => product.id != widget.product.id)
                      .toList()
                    ..sort((left, right) {
                      final leftMatches =
                          left.category.toLowerCase() ==
                          widget.product.category.toLowerCase();
                      final rightMatches =
                          right.category.toLowerCase() ==
                          widget.product.category.toLowerCase();
                      if (leftMatches != rightMatches) {
                        return leftMatches ? -1 : 1;
                      }
                      return left.name.compareTo(right.name);
                    })),
              onCopy: _copyFrom,
              isCopying: _isMutating,
            ),
          };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: _CalibrationHeader(
          productName: widget.product.name,
          onExit: _navigationBlocked
              ? null
              : () {
                  if (_step == _CalibrationStep.success) widget.onSaved();
                  Navigator.pop(context);
                },
        ),
        body: Semantics(
          liveRegion: true,
          container: true,
          child: SafeArea(top: false, child: body),
        ),
      ),
    );
  }
}
