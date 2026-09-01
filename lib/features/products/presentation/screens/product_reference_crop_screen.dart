part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

typedef _SaveCroppedReference = Future<bool> Function(ProductUpload upload);

Future<bool> _showProductReferenceCrop(
  BuildContext context, {
  required ProductUpload source,
  required bool isReplacement,
  required _SaveCroppedReference onSave,
}) async =>
    await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => _ProductReferenceCropScreen(
          source: source,
          isReplacement: isReplacement,
          onSave: onSave,
        ),
      ),
    ) ??
    false;

@immutable
class _ReferenceCropEditorState {
  const _ReferenceCropEditorState({
    this.selection = const Rect.fromLTWH(.1, .1, .8, .8),
    this.naturalSize,
    this.saving = false,
    this.error,
  });

  final Rect selection;
  final Size? naturalSize;
  final bool saving;
  final String? error;

  _ReferenceCropEditorState copyWith({
    Rect? selection,
    Size? naturalSize,
    bool? saving,
    String? error,
    bool clearError = false,
  }) => _ReferenceCropEditorState(
    selection: selection ?? this.selection,
    naturalSize: naturalSize ?? this.naturalSize,
    saving: saving ?? this.saving,
    error: clearError ? null : error ?? this.error,
  );
}

class _ReferenceCropEditorController
    extends Notifier<_ReferenceCropEditorState> {
  _ReferenceCropEditorController(this.source);

  final ProductUpload source;
  Rect _dragStartSelection = const Rect.fromLTWH(.1, .1, .8, .8);
  Offset _dragStart = Offset.zero;
  _CropDragMode _dragMode = _CropDragMode.none;

  @override
  _ReferenceCropEditorState build() => const _ReferenceCropEditorState();

  void imageLoaded(Size size) => state = state.copyWith(naturalSize: size);

  void imageFailed() => state = state.copyWith(
    error: 'This photo could not be opened. / Close the editor and try the upload again.',
  );

  void reset() {
    if (state.saving) return;
    state = state.copyWith(
      selection: const Rect.fromLTWH(.1, .1, .8, .8),
      clearError: true,
    );
  }

  void beginSaving() => state = state.copyWith(saving: true, clearError: true);

  void finishSaving({String? error}) =>
      state = state.copyWith(saving: false, error: error);

  _CropDragMode _modeAt(Offset point, Size size) {
    final selection = state.selection;
    final rect = Rect.fromLTRB(
      selection.left * size.width,
      selection.top * size.height,
      selection.right * size.width,
      selection.bottom * size.height,
    );
    const hit = 24.0;
    final left = (point.dx - rect.left).abs() <= hit;
    final right = (point.dx - rect.right).abs() <= hit;
    final top = (point.dy - rect.top).abs() <= hit;
    final bottom = (point.dy - rect.bottom).abs() <= hit;
    if (left && top) return _CropDragMode.topLeft;
    if (right && top) return _CropDragMode.topRight;
    if (left && bottom) return _CropDragMode.bottomLeft;
    if (right && bottom) return _CropDragMode.bottomRight;
    if (left && point.dy >= rect.top - hit && point.dy <= rect.bottom + hit) {
      return _CropDragMode.left;
    }
    if (right && point.dy >= rect.top - hit && point.dy <= rect.bottom + hit) {
      return _CropDragMode.right;
    }
    if (top && point.dx >= rect.left - hit && point.dx <= rect.right + hit) {
      return _CropDragMode.top;
    }
    if (bottom && point.dx >= rect.left - hit && point.dx <= rect.right + hit) {
      return _CropDragMode.bottom;
    }
    return rect.contains(point) ? _CropDragMode.move : _CropDragMode.none;
  }

  void startDrag(DragStartDetails details, Size size) {
    if (state.saving) return;
    _dragMode = _modeAt(details.localPosition, size);
    _dragStart = details.localPosition;
    _dragStartSelection = state.selection;
  }

  void updateDrag(DragUpdateDetails details, Size size) {
    if (state.saving || _dragMode == _CropDragMode.none) return;
    final dx = (details.localPosition.dx - _dragStart.dx) / size.width;
    final dy = (details.localPosition.dy - _dragStart.dy) / size.height;
    final minWidth = min(1.0, 16 / size.width);
    final minHeight = min(1.0, 16 / size.height);
    var left = _dragStartSelection.left;
    var top = _dragStartSelection.top;
    var right = _dragStartSelection.right;
    var bottom = _dragStartSelection.bottom;

    if (_dragMode == _CropDragMode.move) {
      final width = _dragStartSelection.width;
      final height = _dragStartSelection.height;
      left = (_dragStartSelection.left + dx).clamp(0.0, 1 - width);
      top = (_dragStartSelection.top + dy).clamp(0.0, 1 - height);
      right = left + width;
      bottom = top + height;
    } else {
      if ({
        _CropDragMode.left,
        _CropDragMode.topLeft,
        _CropDragMode.bottomLeft,
      }.contains(_dragMode)) {
        left = (_dragStartSelection.left + dx).clamp(0.0, right - minWidth);
      }
      if ({
        _CropDragMode.right,
        _CropDragMode.topRight,
        _CropDragMode.bottomRight,
      }.contains(_dragMode)) {
        right = (_dragStartSelection.right + dx).clamp(left + minWidth, 1.0);
      }
      if ({
        _CropDragMode.top,
        _CropDragMode.topLeft,
        _CropDragMode.topRight,
      }.contains(_dragMode)) {
        top = (_dragStartSelection.top + dy).clamp(0.0, bottom - minHeight);
      }
      if ({
        _CropDragMode.bottom,
        _CropDragMode.bottomLeft,
        _CropDragMode.bottomRight,
      }.contains(_dragMode)) {
        bottom = (_dragStartSelection.bottom + dy).clamp(top + minHeight, 1.0);
      }
    }
    state = state.copyWith(selection: Rect.fromLTRB(left, top, right, bottom));
  }

  void endDrag() => _dragMode = _CropDragMode.none;
}

final _referenceCropEditorProvider = NotifierProvider.autoDispose
    .family<
      _ReferenceCropEditorController,
      _ReferenceCropEditorState,
      ProductUpload
    >(_ReferenceCropEditorController.new);

class _ProductReferenceCropScreen extends ConsumerStatefulWidget {
  const _ProductReferenceCropScreen({
    required this.source,
    required this.isReplacement,
    required this.onSave,
  });

  final ProductUpload source;
  final bool isReplacement;
  final _SaveCroppedReference onSave;

  @override
  ConsumerState<_ProductReferenceCropScreen> createState() =>
      _ProductReferenceCropScreenState();
}

enum _CropDragMode {
  none,
  move,
  left,
  right,
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _ProductReferenceCropScreenState
    extends ConsumerState<_ProductReferenceCropScreen> {
  NotifierProvider<_ReferenceCropEditorController, _ReferenceCropEditorState>
  get _provider => _referenceCropEditorProvider(widget.source);

  @override
  void initState() {
    super.initState();
    unawaited(_loadImageSize());
  }

  Future<void> _loadImageSize() async {
    try {
      final dimensions = await compute(
        _referenceImageSize,
        widget.source.bytes,
      );
      if (!mounted) return;
      ref
          .read(_provider.notifier)
          .imageLoaded(
            Size(dimensions[0].toDouble(), dimensions[1].toDouble()),
          );
    } on Object {
      if (!mounted) return;
      ref.read(_provider.notifier).imageFailed();
    }
  }

  void _close() {
    if (!ref.read(_provider).saving) Navigator.of(context).pop(false);
  }

  void _reset() => ref.read(_provider.notifier).reset();

  Future<void> _save() async {
    final cropState = ref.read(_provider);
    if (cropState.saving || cropState.naturalSize == null) return;
    ref.read(_provider.notifier).beginSaving();
    try {
      final outputBytes = await compute(
        _encodeReferenceCrop,
        _ReferenceCropRequest(widget.source.bytes, cropState.selection),
      );
      final dot = widget.source.fileName.lastIndexOf('.');
      final baseName = dot > 0
          ? widget.source.fileName.substring(0, dot)
          : 'cropped';
      final cropped = ProductUpload(
        bytes: outputBytes,
        fileName: '$baseName.jpg',
        localKey: widget.source.orderKey,
      );
      final saved = await widget.onSave(cropped);
      if (!mounted) return;
      if (saved) {
        Navigator.of(context).pop(true);
      } else {
        ref.read(_provider.notifier).finishSaving();
      }
    } on Object {
      if (!mounted) return;
      ref.read(_provider.notifier).finishSaving(error: 'Failed to crop photo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropState = ref.watch(_provider);
    final compact = MediaQuery.sizeOf(context).width <= 420;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: PopScope(
        canPop: !cropState.saving,
        child: Scaffold(
          backgroundColor: const Color(0xFFFBFBF9),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(cropState),
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  color: const Color(0xFF242422),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '↔  DRAG TO COMPOSE',
                        style: TextStyle(
                          color: Color(0xFFF5F5F1),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '⌗  FREE CROP',
                        style: TextStyle(
                          color: Color(0xFFBDBDB7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildCanvas(cropState)),
                if (!compact) _buildGuide(),
                if (cropState.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
                    child: Text(
                      cropState.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ),
                _buildFooter(cropState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_ReferenceCropEditorState cropState) => SizedBox(
    height: 88,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(17, 15, 14, 15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REFERENCE EDITOR',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF696964),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.isReplacement
                      ? 'Crop replacement photo'
                      : 'Crop reference photo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _productDisplayFontFamily,
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF121211),
                  ),
                ),
              ],
            ),
          ),
          _CropHeaderButton(
            icon: Icons.refresh,
            label: 'Reset crop',
            onTap: cropState.saving ? null : _reset,
            autofocus: true,
          ),
          const SizedBox(width: 7),
          _CropHeaderButton(
            icon: Icons.close,
            label: 'Close crop editor',
            onTap: cropState.saving ? null : _close,
          ),
        ],
      ),
    ),
  );

  Widget _buildCanvas(_ReferenceCropEditorState cropState) => ColoredBox(
    color: const Color(0xFF121211),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (cropState.naturalSize == null) {
          return Center(
            child: cropState.error == null
                ? const BarSpinner(color: AppColors.white)
                : const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFBDBDB7),
                    size: 34,
                  ),
          );
        }
        final available = Size(
          max(1, constraints.maxWidth - 28),
          max(1, constraints.maxHeight - 28),
        );
        final ratio =
            cropState.naturalSize!.width / cropState.naturalSize!.height;
        var width = available.width;
        var height = width / ratio;
        if (height > available.height) {
          height = available.height;
          width = height * ratio;
        }
        final imageSize = Size(width, height);
        return Center(
          child: SizedBox.fromSize(
            size: imageSize,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) =>
                  ref.read(_provider.notifier).startDrag(details, imageSize),
              onPanUpdate: (details) =>
                  ref.read(_provider.notifier).updateDrag(details, imageSize),
              onPanEnd: (_) => ref.read(_provider.notifier).endDrag(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    widget.source.bytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                  _CropSelectionOverlay(selection: cropState.selection),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildGuide() => Container(
    padding: const EdgeInsets.fromLTRB(17, 13, 17, 13),
    decoration: const BoxDecoration(
      color: Color(0xFFF1F1EE),
      border: Border(top: BorderSide(color: Color(0xFFDEDED8))),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CropGuideItem(
            number: '01',
            title: 'Shape the frame',
            copy: 'Drag any edge or corner to set the crop.',
          ),
        ),
        SizedBox(width: 18),
        Expanded(
          child: _CropGuideItem(
            number: '02',
            title: 'Place the subject',
            copy: 'Drag inside the frame to reposition it.',
          ),
        ),
      ],
    ),
  );

  Widget _buildFooter(_ReferenceCropEditorState cropState) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFDEDED8))),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 11, 17, 11),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: cropState.saving ? null : _close,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(),
                  side: const BorderSide(color: Color(0xFF121211)),
                  foregroundColor: const Color(0xFF121211),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: FilledButton(
                onPressed: cropState.saving || cropState.naturalSize == null
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(),
                  backgroundColor: const Color(0xFF121211),
                  disabledBackgroundColor: const Color(0xFF696964),
                ),
                child: cropState.saving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Saving crop…'),
                        ],
                      )
                    : const Text('Save crop'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CropHeaderButton extends StatelessWidget {
  const _CropHeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.autofocus = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Focus(
      autofocus: autofocus,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDEDED8)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onTap == null
                ? const Color(0xFFBDBDB7)
                : const Color(0xFF121211),
          ),
        ),
      ),
    ),
  );
}

class _CropGuideItem extends StatelessWidget {
  const _CropGuideItem({
    required this.number,
    required this.title,
    required this.copy,
  });
  final String number;
  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 28,
        child: Text(
          number,
          style: const TextStyle(
            fontFamily: _productDisplayFontFamily,
            fontStyle: FontStyle.italic,
            fontSize: 16,
            color: Color(0xFF121211),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF121211),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              copy,
              style: const TextStyle(
                fontSize: 11,
                height: 1.45,
                color: Color(0xFF696964),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CropSelectionOverlay extends StatelessWidget {
  const _CropSelectionOverlay({required this.selection});
  final Rect selection;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rect = Rect.fromLTRB(
        selection.left * constraints.maxWidth,
        selection.top * constraints.maxHeight,
        selection.right * constraints.maxWidth,
        selection.bottom * constraints.maxHeight,
      );
      const shade = Color(0x99000000);
      return Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: rect.top,
            child: const ColoredBox(color: shade),
          ),
          Positioned(
            left: 0,
            top: rect.top,
            width: rect.left,
            height: rect.height,
            child: const ColoredBox(color: shade),
          ),
          Positioned(
            left: rect.right,
            top: rect.top,
            right: 0,
            height: rect.height,
            child: const ColoredBox(color: shade),
          ),
          Positioned(
            left: 0,
            top: rect.bottom,
            right: 0,
            bottom: 0,
            child: const ColoredBox(color: shade),
          ),
          Positioned.fromRect(
            rect: rect,
            child: CustomPaint(painter: const _CropFramePainter()),
          ),
          for (final point in [
            rect.topLeft,
            rect.topRight,
            rect.bottomLeft,
            rect.bottomRight,
          ])
            Positioned(
              left: point.dx - 7.5,
              top: point.dy - 7.5,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF121211),
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _CropFramePainter extends CustomPainter {
  const _CropFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final thirds = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, border);
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      thirds,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      thirds,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      thirds,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      thirds,
    );
  }

  @override
  bool shouldRepaint(_CropFramePainter oldDelegate) => false;
}

class _ReferenceCropRequest {
  const _ReferenceCropRequest(this.bytes, this.selection);
  final Uint8List bytes;
  final Rect selection;
}

List<int> _referenceImageSize(Uint8List bytes) {
  var decoded = image_lib.decodeImage(bytes);
  if (decoded == null || decoded.width < 4 || decoded.height < 4) {
    throw const FormatException('Invalid image');
  }
  decoded = image_lib.bakeOrientation(decoded);
  return [decoded.width, decoded.height];
}

Uint8List _encodeReferenceCrop(_ReferenceCropRequest request) {
  var decoded = image_lib.decodeImage(request.bytes);
  if (decoded == null || decoded.width < 4 || decoded.height < 4) {
    throw const FormatException('Invalid image');
  }
  decoded = image_lib.bakeOrientation(decoded);
  final x = (request.selection.left * decoded.width).round().clamp(
    0,
    decoded.width - 1,
  );
  final y = (request.selection.top * decoded.height).round().clamp(
    0,
    decoded.height - 1,
  );
  final width = (request.selection.width * decoded.width).round().clamp(
    4,
    decoded.width - x,
  );
  final height = (request.selection.height * decoded.height).round().clamp(
    4,
    decoded.height - y,
  );
  final cropped = image_lib.copyCrop(
    decoded,
    x: x,
    y: y,
    width: width,
    height: height,
  );
  return Uint8List.fromList(image_lib.encodeJpg(cropped, quality: 95));
}
