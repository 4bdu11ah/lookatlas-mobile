part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductField extends StatelessWidget {
  const _ProductField({
    required this.label,
    required this.child,
    this.required = false,
    this.note,
    this.helper,
    this.trailing,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? note;
  final String? helper;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: label),
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
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
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
          const SizedBox(height: 8),
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

class _SubtypeRow extends StatelessWidget {
  const _SubtypeRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = ['Tote', 'Crossbody', 'Clutch', 'Backpack'];
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

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.title,
    required this.existingPhotos,
    required this.replacementPhotos,
    required this.replacingPhotoId,
    required this.newPhotos,
    required this.angles,
    required this.newAngles,
    required this.onDeletePhoto,
    required this.onReplacePhoto,
    required this.onAngleChanged,
    required this.onNewAngleChanged,
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
  final void Function(int index, ProductPhoto photo) onDeletePhoto;
  final Future<void> Function(ProductPhoto photo) onReplacePhoto;
  final void Function(int index, String? angle) onAngleChanged;
  final void Function(int index, String? angle) onNewAngleChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha68,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (countLabel != null)
                Text(
                  countLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
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
          const SizedBox(height: 10),
          SizedBox(
            height: 182,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: existingPhotos.length + newPhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index >= existingPhotos.length) {
                  final upload = newPhotos[index - existingPhotos.length];
                  return _ProductThumb(
                    displayIndex: index,
                    upload: upload,
                    isNew: true,
                    angle: newAngles[index - existingPhotos.length],
                    onAngleChanged: (angle) =>
                        onNewAngleChanged(index - existingPhotos.length, angle),
                  );
                }
                final existing = existingPhotos[index];
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
                );
              },
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: upload == null
                      ? _AssetImage(url ?? '')
                      : AppImage.memory(upload!.bytes, fit: BoxFit.cover),
                ),
                if (isLoading)
                  const ColoredBox(
                    color: AppColors.inkAlpha80,
                    child: Center(
                      child: BarSpinner(color: AppColors.white),
                    ),
                  ),
                if (onReplace != null)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: _ThumbAction(
                      icon: Icons.edit_outlined,
                      onTap: onReplace!,
                    ),
                  ),
                if (onDelete != null)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: _ThumbAction(icon: Icons.close, onTap: onDelete!),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 25,
                    color: isNew
                        ? AppColors.successDarker
                        : AppColors.blackAlpha90,
                    alignment: Alignment.center,
                    child: Text(
                      isNew ? 'New' : '${displayIndex + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: AppTypography.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _MiniSelect(
            angle ?? '',
            onChanged: onAngleChanged,
          ),
        ],
      ),
    );
  }
}

class _ThumbAction extends StatelessWidget {
  const _ThumbAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        color: AppColors.blackAlpha90,
        child: Icon(icon, size: 14, color: AppColors.white),
      ),
    );
  }
}

class _MiniSelect extends StatelessWidget {
  const _MiniSelect(this.value, {required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = ['', 'front', 'back', 'side', 'detail', 'top'];
    return SizedBox(
      height: 32,
      child: AppDropdown<String>(
        value: values.contains(value) ? value : '',
        values: values,
        labelFor: (angle) => angle.isEmpty
            ? 'Choose angle'
            : '${angle[0].toUpperCase()}${angle.substring(1)}',
        onChanged: (angle) => onChanged(angle.isEmpty ? null : angle),
        config: const AppDropdownConfig(
          height: 32,
          horizontalPadding: 7,
        ),
      ),
    );
  }
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
