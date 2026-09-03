part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductField extends StatelessWidget {
  const _ProductField({
    required this.label,
    required this.child,
    this.required = false,
    this.note,
    this.helper,
    this.trailing,
    this.galleryStyle = false,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? note;
  final String? helper;
  final String? trailing;
  final bool galleryStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: galleryStyle ? 13 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: galleryStyle ? label.toUpperCase() : label,
                      ),
                      if (required)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      if (note != null)
                        TextSpan(
                          text: ' ($note)',
                          style: const TextStyle(
                            color: AppColors.neutral500,
                            fontWeight: AppTypography.medium,
                            textBaseline: TextBaseline.alphabetic,
                          ),
                        ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: galleryStyle ? 9 : 12,
                    height: 1.1,
                    fontWeight: galleryStyle
                        ? AppTypography.bold
                        : FontWeight.w900,
                    letterSpacing: galleryStyle ? 0.72 : null,
                    color: galleryStyle
                        ? const Color(0xFF696964)
                        : AppColors.black,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
            ],
          ),
          SizedBox(height: galleryStyle ? 6 : 8),
          child,
          if (helper != null) ...[
            const SizedBox(height: 5),
            Text(
              helper!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddProductUploadStack extends StatelessWidget {
  const _AddProductUploadStack({
    required this.form,
    required this.onPickPhotos,
    required this.onAngleChanged,
    required this.onMovePhoto,
    required this.onCropPhoto,
    required this.onRemovePhoto,
  });

  final _ProductFormState form;
  final VoidCallback onPickPhotos;
  final void Function(int index, String? angle) onAngleChanged;
  final void Function(String token, int delta) onMovePhoto;
  final ValueChanged<int> onCropPhoto;
  final ValueChanged<int> onRemovePhoto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.all(22),
    decoration: const BoxDecoration(
      color: Color(0xFFECECE7),
      border: Border(bottom: BorderSide(color: Color(0xFFD5D5CF))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AddProductUploadBox(
          enabled: form.photoCount < PRODUCT_PHOTO_UPLOAD_MAX_COUNT,
          hasPhotos: form.photoCount > 0,
          onTap: onPickPhotos,
        ),
        for (final (displayIndex, token) in form.orderedPhotoTokens.indexed)
          if (token.startsWith('new:'))
            for (final (newIndex, photo) in form.newPhotos.indexed)
              if (photo.orderKey == token.substring(4))
                _AddProductPhotoRow(
                  displayIndex: displayIndex,
                  upload: photo,
                  angle: form.newAngles[newIndex],
                  onAngleChanged: (angle) => onAngleChanged(newIndex, angle),
                  onMoveUp: displayIndex == 0
                      ? null
                      : () => onMovePhoto(token, -1),
                  onMoveDown: displayIndex == form.orderedPhotoTokens.length - 1
                      ? null
                      : () => onMovePhoto(token, 1),
                  onCrop: () => onCropPhoto(newIndex),
                  onRemove: () => onRemovePhoto(newIndex),
                ),
      ],
    ),
  );
}

class _AddProductUploadBox extends StatelessWidget {
  const _AddProductUploadBox({
    required this.enabled,
    required this.hasPhotos,
    required this.onTap,
  });

  final bool enabled;
  final bool hasPhotos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: 'Upload 1 to 8 reference views',
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: AppDottedBorder(
        color: const Color(0xFFDEDED8),
        dotWidth: 7,
        gap: 5,
        child: Container(
          constraints: const BoxConstraints(minHeight: 142),
          color: const Color(0xFFF1F1EE),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.file_upload_outlined,
                size: 24,
                color: Color(0xFF696964),
              ),
              const SizedBox(height: 10),
              Text(
                enabled
                    ? hasPhotos
                          ? 'Add more reference views'
                          : 'Upload 1–8 reference views'
                    : '8 reference views added',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF121211),
                  fontFamily: _productDisplayFontFamily,
                  fontSize: 23,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'JPG, PNG · 20MB each',
                style: TextStyle(color: Color(0xFF696964), fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AddProductPhotoRow extends StatelessWidget {
  const _AddProductPhotoRow({
    required this.displayIndex,
    required this.upload,
    required this.angle,
    required this.onAngleChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onCrop,
    required this.onRemove,
  });

  final int displayIndex;
  final ProductUpload upload;
  final String? angle;
  final ValueChanged<String?> onAngleChanged;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onCrop;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFD),
      border: Border.all(color: const Color(0xFFDEDED8)),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: AppImage.memory(upload.bytes, fit: BoxFit.cover),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View ${displayIndex + 1}'.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF696964),
                      fontSize: 8,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _MiniSelect(
                    angle,
                    angleLabel:
                        'Angle for new product view ${displayIndex + 1}',
                    onChanged: onAngleChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AddPhotoAction(
                display: '↑',
                label: 'Move up',
                onTap: onMoveUp,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _AddPhotoAction(
                display: '↓',
                label: 'Move down',
                onTap: onMoveDown,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _AddPhotoAction(
                display: '',
                icon: Icons.crop,
                label: 'Crop',
                onTap: onCrop,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _AddPhotoAction(
                display: '×',
                label: 'Remove',
                onTap: onRemove,
                danger: true,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AddPhotoAction extends StatelessWidget {
  const _AddPhotoAction({
    required this.display,
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
  });

  final String display;
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Opacity(
      opacity: onTap == null ? 0.38 : 1,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDEDED8)),
          ),
          child: icon != null
              ? Icon(
                  icon,
                  size: 18,
                  color: danger
                      ? const Color(0xFF8A2D2D)
                      : const Color(0xFF121211),
                )
              : Text(
                  display,
                  style: TextStyle(
                    fontSize: 18,
                    color: danger
                        ? const Color(0xFF8A2D2D)
                        : const Color(0xFF121211),
                  ),
                ),
        ),
      ),
    ),
  );
}

class _SubtypeRow extends StatelessWidget {
  const _SubtypeRow({
    required this.category,
    required this.value,
    required this.onChanged,
  });

  final String category;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = category == 'Jewelry'
        ? const ['Ring', 'Necklace', 'Pendant', 'Earrings', 'Bracelet']
        : const ['Tote', 'Crossbody', 'Clutch', 'Backpack', 'Other Bag'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in values)
          InkWell(
            onTap: () => onChanged(item),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item == value ? AppColors.black : AppColors.white,
                border: Border.all(
                  color: item == value ? AppColors.black : AppColors.neutral200,
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.semiBold,
                  color: item == value ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductUploadBox extends StatelessWidget {
  const _ProductUploadBox({
    required this.label,
    required this.copy,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final String copy;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AppDottedBorder(
        color: AppColors.neutral200,
        strokeWidth: 2,
        dotWidth: 8,
        gap: 6,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 118 : 148),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 48 : 54,
                  height: compact ? 48 : 54,
                  color: AppColors.black,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.upload,
                    size: 24,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProductUploadBox extends StatelessWidget {
  const _EditProductUploadBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Add reference views',
    child: InkWell(
      onTap: onTap,
      child: const AppDottedBorder(
        color: Color(0xFFB8B8B1),
        dotWidth: 7,
        gap: 5,
        child: SizedBox(
          height: 86,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 22),
              SizedBox(width: 10),
              Text(
                'Add reference views',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.title,
    required this.existingPhotos,
    required this.replacementPhotos,
    required this.replacingPhotoId,
    required this.newPhotos,
    required this.angles,
    required this.newAngles,
    required this.photoOrder,
    required this.onDeletePhoto,
    required this.onReplacePhoto,
    required this.onAngleChanged,
    required this.onNewAngleChanged,
    required this.onMovePhoto,
    required this.onCropNew,
    required this.onRemoveNew,
    this.onClear,
    this.countLabel,
    this.clearLabel,
  });

  final String title;
  final String? countLabel;
  final String? clearLabel;
  final List<(int, ProductPhoto)> existingPhotos;
  final Map<String, ProductUpload> replacementPhotos;
  final String? replacingPhotoId;
  final List<ProductUpload> newPhotos;
  final Map<int, String?> angles;
  final Map<int, String?> newAngles;
  final List<String> photoOrder;
  final void Function(int index, ProductPhoto photo) onDeletePhoto;
  final Future<void> Function(ProductPhoto photo) onReplacePhoto;
  final void Function(int index, String? angle) onAngleChanged;
  final void Function(int index, String? angle) onNewAngleChanged;
  final void Function(String token, int delta) onMovePhoto;
  final ValueChanged<int> onCropNew;
  final ValueChanged<int> onRemoveNew;
  final VoidCallback? onClear;

  Widget _buildPhoto(int index, String token) {
    if (token.startsWith('new:')) {
      final newIndex = newPhotos.indexWhere(
        (photo) => photo.orderKey == token.substring(4),
      );
      final upload = newPhotos[newIndex];
      return _ProductThumb(
        displayIndex: index,
        upload: upload,
        isNew: true,
        angle: newAngles[newIndex],
        onAngleChanged: (angle) => onNewAngleChanged(newIndex, angle),
        onMoveUp: index == 0 ? null : () => onMovePhoto(token, -1),
        onMoveDown: index == photoOrder.length - 1
            ? null
            : () => onMovePhoto(token, 1),
        onCrop: () => onCropNew(newIndex),
        onDelete: () => onRemoveNew(newIndex),
      );
    }
    final existing = existingPhotos.firstWhere(
      (entry) => entry.$2.id == token.substring(9),
    );
    return _ProductThumb(
      displayIndex: index,
      url: existing.$2.url,
      upload: replacementPhotos[existing.$2.id],
      isLoading: replacingPhotoId == existing.$2.id,
      angle: angles[existing.$1],
      onAngleChanged: (angle) => onAngleChanged(existing.$1, angle),
      onReplace: replacingPhotoId == existing.$2.id
          ? null
          : () => onReplacePhoto(existing.$2),
      onDelete: replacingPhotoId == existing.$2.id
          ? null
          : () => onDeletePhoto(existing.$1, existing.$2),
      onMoveUp: index == 0 ? null : () => onMovePhoto(token, -1),
      onMoveDown: index == photoOrder.length - 1
          ? null
          : () => onMovePhoto(token, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.neutral200),
          bottom: BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ),
                if (countLabel != null)
                  Text(
                    countLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                if (clearLabel != null)
                  InkWell(
                    onTap: onClear,
                    child: Text(
                      clearLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: AppTypography.semiBold,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final (index, token) in photoOrder.indexed)
            _buildPhoto(index, token),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({
    required this.displayIndex,
    required this.angle,
    required this.onAngleChanged,
    this.url,
    this.upload,
    this.isNew = false,
    this.isLoading = false,
    this.onReplace,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    this.onCrop,
  });

  final int displayIndex;
  final String? url;
  final ProductUpload? upload;
  final bool isNew;
  final bool isLoading;
  final String? angle;
  final ValueChanged<String?> onAngleChanged;
  final VoidCallback? onReplace;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onCrop;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.neutral200)),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (upload == null)
                    _AssetImage(url ?? '', fit: BoxFit.contain)
                  else
                    AppImage.memory(upload!.bytes),
                  if (isLoading)
                    const ColoredBox(
                      color: AppColors.inkAlpha80,
                      child: Center(
                        child: BarSpinner(color: AppColors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isNew ? 'New' : 'Saved'} view · Position ${displayIndex + 1}'
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 9,
                      fontWeight: AppTypography.bold,
                      letterSpacing: .55,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MiniSelect(
                    angle,
                    angleLabel:
                        'Angle for ${isNew ? 'new' : 'saved'} product view ${displayIndex + 1}',
                    onChanged: onAngleChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _AddPhotoAction(
                display: '↑',
                label: 'Move view up',
                onTap: onMoveUp,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _AddPhotoAction(
                display: '↓',
                label: 'Move view down',
                onTap: onMoveDown,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _AddPhotoAction(
                display: '',
                icon: isNew ? Icons.crop : Icons.file_upload_outlined,
                label: isNew ? 'Crop view' : 'Replace view',
                onTap: isNew ? onCrop : onReplace,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _AddPhotoAction(
                display: '',
                icon: Icons.delete_outline,
                label: 'Delete view',
                onTap: onDelete,
                danger: true,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MiniSelect extends StatelessWidget {
  const _MiniSelect(
    this.value, {
    required this.onChanged,
    required this.angleLabel,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String angleLabel;

  static const _standardAngles = [
    'front',
    'back',
    'side',
    'top',
    'bottom',
    'detail',
    'inside',
  ];
  static const _noneToken = '__none__';
  static const _customToken = '__custom__';

  void _select(String token) {
    if (token == _noneToken) {
      onChanged(null);
      return;
    }
    if (token == _customToken) {
      onChanged('');
      return;
    }
    onChanged(token);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = value != null && !_standardAngles.contains(value);
    final dropdownValue = value == null
        ? _noneToken
        : isCustom
        ? _customToken
        : value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: angleLabel,
          child: AppDropdown<String>(
            value: dropdownValue,
            values: const [_noneToken, ..._standardAngles, _customToken],
            labelFor: (angle) {
              if (angle == _noneToken) return 'None';
              if (angle == _customToken) return 'Custom…';
              return '${angle[0].toUpperCase()}${angle.substring(1)}';
            },
            onChanged: _select,
            config: const AppDropdownConfig(
              height: 44,
              horizontalPadding: 7,
              menuMaxHeight: 320,
            ),
          ),
        ),
        if (isCustom) ...[
          const SizedBox(height: 5),
          SizedBox(
            height: 44,
            child: Semantics(
              textField: true,
              label: '$angleLabel custom name',
              child: _ControlledCustomAngleField(
                value: value!,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ControlledCustomAngleField extends StatefulWidget {
  const _ControlledCustomAngleField({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  State<_ControlledCustomAngleField> createState() =>
      _ControlledCustomAngleFieldState();
}

class _ControlledCustomAngleFieldState
    extends State<_ControlledCustomAngleField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    if (widget.value.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ControlledCustomAngleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text == widget.value) return;
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: _focusNode,
    maxLength: 40,
    inputFormatters: [LengthLimitingTextInputFormatter(40)],
    onChanged: (text) => widget.onChanged(
      text.substring(0, min(text.length, 40)),
    ),
    decoration: const InputDecoration(
      hintText: 'e.g., Logo, Tag',
      counterText: '',
      contentPadding: EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFFDEDED8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF121211), width: 2),
      ),
    ),
    style: const TextStyle(fontSize: 12, color: Color(0xFF121211)),
  );
}

class _ProductIdCard extends StatelessWidget {
  const _ProductIdCard(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(left: BorderSide(color: AppColors.black, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product ID',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            id,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}

class _ProductTip extends StatelessWidget {
  const _ProductTip({required this.title, required this.copy});

  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(left: BorderSide(color: AppColors.black, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            copy,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}
