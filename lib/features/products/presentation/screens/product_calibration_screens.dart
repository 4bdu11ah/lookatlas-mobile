part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

void _openReplacePhotoScreen(
  BuildContext context,
  WidgetRef ref,
  _Product product,
  int photoIndex,
  ValueChanged<String> onToast,
) {
  unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ProductPhotoReplaceScreen(
          product: product,
          photoIndex: photoIndex,
          onReplace: (replacement) async {
            if (product.productPhotos.isEmpty) {
              return const Err(
                ValidationFailure('This product has no photo to replace.'),
              );
            }
            final index = photoIndex.clamp(0, product.productPhotos.length - 1);
            final result = await ref
                .read(_productsControllerProvider.notifier)
                .replacePhoto(
                  product,
                  product.productPhotos[index],
                  replacement,
                );
            if (result.isOk) onToast('Photo replaced');
            return result;
          },
        ),
      ),
    ),
  );
}

Future<void> _openCalibration(
  BuildContext context,
  WidgetRef ref,
  _Product product,
  ValueChanged<String> onToast,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ProductCalibrationScreen(
        product: product,
        repository: ref.read(productsRepositoryProvider),
        onSaved: () {
          unawaited(ref.read(_productsControllerProvider.notifier).reload());
          onToast('Calibration saved');
        },
      ),
    ),
  );
}

class _ProductPhotoReplaceState {
  const _ProductPhotoReplaceState({this.replacement, this.isSaving = false});

  final ProductUpload? replacement;
  final bool isSaving;

  _ProductPhotoReplaceState copyWith({
    ProductUpload? replacement,
    bool? isSaving,
  }) => _ProductPhotoReplaceState(
    replacement: replacement ?? this.replacement,
    isSaving: isSaving ?? this.isSaving,
  );
}

class _ProductPhotoReplaceController
    extends Notifier<_ProductPhotoReplaceState> {
  _ProductPhotoReplaceController(this.productId);

  final String productId;

  @override
  _ProductPhotoReplaceState build() => const _ProductPhotoReplaceState();

  _ProductPhotoReplaceState get _value => state;
  set _value(_ProductPhotoReplaceState value) {
    if (_value == value) return;
    state = value;
  }
}

// Riverpod does not expose a stable public family type for this provider.
// ignore: specify_nonobvious_property_types
final _productPhotoReplaceProvider = NotifierProvider.autoDispose
    .family<_ProductPhotoReplaceController, _ProductPhotoReplaceState, String>(
      _ProductPhotoReplaceController.new,
    );

class _ProductCalibrationState {
  const _ProductCalibrationState({
    this.step = _CalibrationStep.method,
    this.workspace,
    this.failure,
    this.bodyArea = 'full_body_front',
    this.isLoading = true,
    this.isMutating = false,
    this.cutout,
    this.bodyZoom = 1,
    this.placementX = 0.5,
    this.placementY = 0.56,
    this.placementScale = 1,
  });

  final _CalibrationStep step;
  final ProductCalibrationWorkspace? workspace;
  final Failure? failure;
  final String bodyArea;
  final bool isLoading;
  final bool isMutating;
  final ProductUpload? cutout;
  final double bodyZoom;
  final double placementX;
  final double placementY;
  final double placementScale;

  _ProductCalibrationState copyWith({
    _CalibrationStep? step,
    ProductCalibrationWorkspace? workspace,
    Failure? failure,
    String? bodyArea,
    bool? isLoading,
    bool? isMutating,
    ProductUpload? cutout,
    double? bodyZoom,
    double? placementX,
    double? placementY,
    double? placementScale,
    bool clearFailure = false,
  }) => _ProductCalibrationState(
    step: step ?? this.step,
    workspace: workspace ?? this.workspace,
    failure: clearFailure ? null : failure ?? this.failure,
    bodyArea: bodyArea ?? this.bodyArea,
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    cutout: cutout ?? this.cutout,
    bodyZoom: bodyZoom ?? this.bodyZoom,
    placementX: placementX ?? this.placementX,
    placementY: placementY ?? this.placementY,
    placementScale: placementScale ?? this.placementScale,
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

class _ProductPhotoReplaceScreen extends ConsumerWidget {
  const _ProductPhotoReplaceScreen({
    required this.product,
    required this.photoIndex,
    required this.onReplace,
  });

  final _Product product;
  final int photoIndex;
  final Future<Result<void>> Function(ProductUpload replacement) onReplace;

  Future<void> _chooseReplacement(BuildContext context, WidgetRef ref) async {
    final replacement = await _pickProductPhoto(
      context,
      ref,
      title: 'Choose replacement photo',
    );
    if (context.mounted && replacement != null) {
      ref.read(_productPhotoReplaceProvider(product.id).notifier)._value =
          _ProductPhotoReplaceState(replacement: replacement);
    }
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final provider = _productPhotoReplaceProvider(product.id);
    final state = ref.read(provider);
    final replacement = state.replacement;
    if (replacement == null || state.isSaving) return;
    ref.read(provider.notifier)._value = state.copyWith(isSaving: true);
    final result = await onReplace(replacement);
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      ref.read(provider.notifier)._value = state.copyWith(isSaving: false);
      AppSnackBar.showError(context, failure.message);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_productPhotoReplaceProvider(product.id));
    final assets = product.photoAssets;
    final currentAsset = assets.isEmpty
        ? ''
        : assets[photoIndex.clamp(0, assets.length - 1)];
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ProductFlowHeader(
              title: 'Replace photo',
              subtitle:
                  'Choose a replacement photo, then save it to this product.',
              action: AppOutlinedButton(
                label: 'Choose photo',
                icon: Icons.photo_library_outlined,
                onPressed: () => _chooseReplacement(context, ref),
                fitToContent: true,
                height: 34,
                borderColor: AppColors.transparent,
                backgroundColor: AppColors.transparent,
                iconSize: 16,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.black,
                padding: const EdgeInsets.all(18),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 284,
                  height: 420,
                  child: state.replacement == null
                      ? _AssetImage(currentAsset)
                      : AppImage.memory(
                          state.replacement!.bytes,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            _ProductFlowFooter(
              primaryLabel: 'Save replacement',
              onBack: () => Navigator.pop(context),
              onPrimary: state.replacement == null || state.isSaving
                  ? null
                  : () => _save(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCalibrationScreen extends ConsumerStatefulWidget {
  const _ProductCalibrationScreen({
    required this.product,
    required this.repository,
    required this.onSaved,
  });

  final _Product product;
  final ProductsRepository repository;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ProductCalibrationScreen> createState() =>
      _ProductCalibrationScreenState();
}

class _ProductCalibrationScreenState
    extends ConsumerState<_ProductCalibrationScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  var _isInitialCalibrationLoad = true;
  var _openedWithSavedCalibration = false;

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

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_load));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _isLoading = true;
    _failure = null;
    final result = await widget.repository.loadCalibration(widget.product.id);
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
        if (value.calibration.isLegacyOnly) {
          _step = _CalibrationStep.review;
        } else if (value.calibration.hasPlacement ||
            value.calibration.wornPhotoUrl != null) {
          _step = _CalibrationStep.review;
        } else if (value.calibration.cutoutUrl != null) {
          _step = _CalibrationStep.placeProduct;
        }
        _isLoading = false;
      case Err(:final failure):
        _isLoading = false;
        _failure = failure;
    }
  }

  Future<ProductUpload?> _pickUpload(String title) =>
      _pickProductPhoto(context, ref, title: title);

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

  void _updatePlacement(double x, double y, double scale) {
    _placementX = x.clamp(0.1, 0.9);
    _placementY = y.clamp(0.1, 0.9);
    _placementScale = scale.clamp(0.5, 2);
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
      );
    } on Exception {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not load that product photo.');
      }
      return null;
    }
  }

  Future<void> _processCutout(ProductUpload upload) async {
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
    final cutout = _cutout;
    if (cutout == null || _isMutating) return;
    _isMutating = true;
    final result = await widget.repository.uploadCutout(
      widget.product.id,
      cutout,
    );
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      _isMutating = false;
      _failure = failure;
      AppSnackBar.showError(context, failure.message);
      return;
    }
    _isMutating = false;
    await _load();
    if (!mounted) return;
    _step = _CalibrationStep.placeProduct;
  }

  Future<ProductUpload?> _removeBackground(ProductUpload upload) async {
    final imagePath = upload.path;
    if (imagePath == null || imagePath.isEmpty) {
      AppSnackBar.showError(
        context,
        'We could not remove the background for that photo. Please try a different photo.',
      );
      return null;
    }
    try {
      final isModelReady = await NativeCutout.isModelAvailable();
      if (!isModelReady && !await NativeCutout.downloadModel()) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            'The background-removal model could not download. Check your connection and try again.',
          );
        }
        return null;
      }
      final result = await NativeCutout.removeBackground(
        imagePath,
        options: const CutoutOptions(cropToSubject: true, writeToCache: false),
      );
      if (!mounted) return null;
      switch (result) {
        case CutoutBytesSuccess(:final pngBytes):
          return ProductUpload(
            bytes: pngBytes,
            fileName: '${widget.product.id}-cutout.png',
          );
        case CutoutFailure(:final message):
          AppSnackBar.showError(
            context,
            message.isEmpty
                ? 'We could not remove the background for that photo. Please try a different photo.'
                : message,
          );
        case CutoutFileSuccess():
          AppSnackBar.showError(
            context,
            'We could not remove the background for that photo. Please try a different photo.',
          );
      }
    } on Exception {
      if (!mounted) return null;
      AppSnackBar.showError(
        context,
        'We could not remove the background for that photo. Please try a different photo.',
      );
    }
    return null;
  }

  Future<void> _uploadWornPhoto() async {
    final upload = await _pickUpload('Upload worn product photo');
    if (upload == null || !mounted) return;
    _isMutating = true;
    final result = await widget.repository.uploadWornPhoto(
      widget.product.id,
      upload,
    );
    if (!mounted) return;
    _isMutating = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    await _load();
    if (mounted) _step = _CalibrationStep.review;
  }

  Future<void> _save() async {
    if (_isMutating) return;
    _isMutating = true;
    final calibration = _workspace?.calibration;
    final hasPlacement = calibration?.cutoutUrl != null || _cutout != null;
    if (!hasPlacement && calibration?.wornPhotoUrl == null) {
      _isMutating = false;
      AppSnackBar.showError(
        context,
        'Place the product on the body outline first.',
      );
      return;
    }
    final result = await widget.repository.saveCalibration(
      widget.product.id,
      ProductCalibrationDraft(
        bodyArea: _bodyArea,
        shapes: const [],
        userNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        cutoutPlacement: hasPlacement
            ? {
                'x': _placementX * 1000,
                'y': _placementY * 1500,
                'w': 220 * _placementScale,
                'h': 260 * _placementScale,
              }
            : null,
      ),
    );
    if (!mounted) return;
    _isMutating = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    widget.onSaved();
    Navigator.pop(context);
  }

  Future<void> _copyFrom(ProductCatalogItem source) async {
    if (_isMutating) return;
    _isMutating = true;
    final result = await widget.repository.copyCalibration(
      widget.product.id,
      source.id,
    );
    if (!mounted) return;
    _isMutating = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    await _load();
    if (mounted) _step = _CalibrationStep.review;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(_productCalibrationStateProvider(widget.product.id));
    final workspace = _workspace;
    final Widget body = _isLoading
        ? const _ProductCalibrationLoadingShimmer()
        : workspace == null
        ? _ProductLoadFailure(
            message: _failure?.message ?? 'Could not load calibration.',
            onRetry: _load,
          )
        : switch (_step) {
            _CalibrationStep.method => _CalibrationMethodStep(
              onBody: () => _step = _CalibrationStep.bodyView,
              onWorn: () => _step = _CalibrationStep.wornPhoto,
              onCopy: () => _step = _CalibrationStep.copyFrom,
            ),
            _CalibrationStep.bodyView => _CalibrationBodyStep(
              outlines: workspace.outlines,
              selectedBodyArea: _bodyArea,
              onSelected: (value) => _bodyArea = value,
              onBack: () => _step = _CalibrationStep.method,
              onNext: () => _step = _CalibrationStep.pickPhoto,
            ),
            _CalibrationStep.pickPhoto => _CalibrationPickPhotoStep(
              product: widget.product,
              bodyArea: _bodyArea,
              onBack: () => _step = _CalibrationStep.bodyView,
              onNext: _uploadCutout,
              onPhotoSelected: _useExistingProductPhoto,
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
            ),
            _CalibrationStep.placeProduct => _CalibrationPlaceStep(
              product: widget.product,
              bodyArea: _bodyArea,
              cutout: _cutout,
              bodyZoom: _bodyZoom,
              placementX: _placementX,
              placementY: _placementY,
              placementScale: _placementScale,
              onPlacementChanged: _updatePlacement,
              onBodyZoomChanged: (value) => _bodyZoom = value,
              onBack: () => _step = _CalibrationStep.confirmCutout,
              onNext: () => _step = _CalibrationStep.review,
            ),
            _CalibrationStep.review => _CalibrationReviewStep(
              product: widget.product,
              bodyArea: _bodyArea,
              cutout: _cutout,
              placementX: _placementX,
              placementY: _placementY,
              placementScale: _placementScale,
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
              isSaving: _isMutating,
              wornPhotoUrl: workspace.calibration.wornPhotoUrl,
              isLegacy: workspace.calibration.isLegacyOnly,
            ),
            _CalibrationStep.wornPhoto => _CalibrationWornStep(
              onBack: () => _step = _CalibrationStep.method,
              onUpload: _uploadWornPhoto,
              isUploading: _isMutating,
            ),
            _CalibrationStep.copyFrom => _CalibrationCopyStep(
              searchController: _searchController,
              onBack: () => _step = _CalibrationStep.method,
              products: workspace.calibratedProducts
                  .where((product) => product.id != widget.product.id)
                  .toList(growable: false),
              onCopy: _copyFrom,
              isCopying: _isMutating,
            ),
          };
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(
        title: 'Set real-world size',
        showBackButton: true,
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}
