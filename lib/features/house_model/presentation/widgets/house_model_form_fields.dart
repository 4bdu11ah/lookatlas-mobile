part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _TextFieldBlock extends StatelessWidget {
  const _TextFieldBlock({
    required this.label,
    required this.controller,
    this.onChanged,
    this.required = false,
    this.hint,
    this.keyboardType,
    this.invalid = false,
    this.error = '',
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool required;
  final String? hint;
  final TextInputType? keyboardType;
  final bool invalid;
  final String error;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      required: required,
      invalid: invalid,
      error: error,
      child: AppTextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        hintText: hint,
      ),
    );
  }
}

class _TextAreaBlock extends StatelessWidget {
  const _TextAreaBlock({
    required this.controller,
    required this.onChanged,
    required this.invalid,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Describe the model',
      required: true,
      invalid: invalid,
      error: 'Please add at least 10 characters.',
      footer: '${controller.text.length}/600',
      child: AppTextField(
        key: const ValueKey('ai-description'),
        controller: controller,
        minLines: 4,
        maxLines: 6,
        maxLength: 600,
        showCounter: false,
        onChanged: onChanged,
        hintText: 'Share vibe, hair, complexion, styling cues...',
      ),
    );
  }
}

class _SelectBlock<T> extends StatelessWidget {
  const _SelectBlock({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      required: required,
      child: AppDropdown<T>(
        value: value,
        values: values,
        labelFor: labelFor,
        onChanged: onChanged,
      ),
    );
  }
}

class _HeightBlock extends StatelessWidget {
  const _HeightBlock({
    required this.controller,
    required this.estimated,
    required this.invalid,
    required this.onEstimatedChanged,
  });

  final TextEditingController controller;
  final bool estimated;
  final bool invalid;
  final ValueChanged<bool> onEstimatedChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Height',
      required: true,
      invalid: invalid,
      error: 'Enter a height between 100 and 250 cm.',
      footer: 'Typical range 150-200 cm. Check "Est." if approximate.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    hintText: '170',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 54,
                  height: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: const Text(
                    'cm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: AppTypography.bold,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => onEstimatedChanged(!estimated),
            child: Container(
              width: 86,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: estimated ? AppColors.black : AppColors.white,
                      border: Border.all(color: AppColors.neutral250),
                    ),
                    child: estimated
                        ? const Icon(
                            Icons.check,
                            size: 11,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Est.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoUploadBlock extends StatelessWidget {
  const _PhotoUploadBlock({
    required this.existingPhotos,
    required this.newPhotos,
    required this.editing,
    required this.invalid,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<String> existingPhotos;
  final List<HouseModelUpload> newPhotos;
  final bool editing;
  final bool invalid;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  int get count => existingPhotos.length + newPhotos.length;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: editing ? 'Current Photos' : 'Model Photos',
      required: true,
      invalid: invalid,
      error: 'Add at least one clear model photo.',
      trailingLabel: editing
          ? '(${existingPhotos.length} existing)'
          : '($count/${HouseModelDraft.maxPhotoCount})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (editing && existingPhotos.isNotEmpty)
            _CurrentPhotosStrip(
              photos: existingPhotos,
              onRemove: onRemoveExisting,
            ),
          if (editing) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Add New Photos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '($count/${HouseModelDraft.maxPhotoCount})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          InkWell(
            key: const ValueKey('model-photo-upload'),
            onTap: onAdd,
            child: AppDottedBorder(
              color: AppColors.neutral200,
              strokeWidth: 2,
              dotWidth: 8,
              gap: 6,
              child: Container(
                height: 132,
                width: double.infinity,
                alignment: Alignment.center,
                color: AppColors.white,
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.file_upload_outlined,
                      size: 34,
                      color: AppColors.neutral500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      editing
                          ? 'Click to add more photos'
                          : 'Click to upload photos',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: AppTypography.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'PNG, JPG up to 10MB each',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (newPhotos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 132,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemExtent: 105,
                itemCount: newPhotos.length,
                itemBuilder: (context, index) {
                  return _PhotoPreview(
                    source: null,
                    bytes: newPhotos[index].bytes,
                    onRemove: () => onRemoveNew(index),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentPhotosStrip extends StatelessWidget {
  const _CurrentPhotosStrip({required this.photos, required this.onRemove});

  final List<String> photos;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 181,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemExtent: 112,
        itemCount: photos.length,
        itemBuilder: (context, index) => _CurrentPhotoPreview(
          source: photos[index],
          label: index + 1,
          onDelete: () => onRemove(index),
        ),
      ),
    );
  }
}

class _CurrentPhotoPreview extends StatelessWidget {
  const _CurrentPhotoPreview({
    required this.source,
    required this.label,
    required this.onDelete,
  });

  final String source;
  final int label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        key: ValueKey('existing-model-photo-${label - 1}'),
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.neutral100,
            child: _AssetImage(source),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Tooltip(
              message: 'Delete photo',
              child: InkWell(
                key: ValueKey('delete-existing-model-photo-${label - 1}'),
                onTap: onDelete,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.inkAlpha80,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 13,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                color: AppColors.blackAlpha60,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$label',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: AppTypography.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.source,
    required this.bytes,
    required this.onRemove,
  });

  final String? source;
  final Uint8List? bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.neutral100,
            child: bytes == null
                ? _AssetImage(source ?? '')
                : AppImage.memory(bytes!, fit: BoxFit.cover),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.inkAlpha80,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 13,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.label,
    required this.child,
    this.required = false,
    this.invalid = false,
    this.error = '',
    this.footer,
    this.trailingLabel,
  });

  final String label;
  final Widget child;
  final bool required;
  final bool invalid;
  final String error;
  final String? footer;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: AppColors.dangerDark)),
              if (trailingLabel != null)
                Expanded(
                  child: Text(
                    trailingLabel!,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (footer != null || invalid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                invalid ? error : footer!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: invalid ? AppColors.dangerDark : AppColors.neutral500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inkAlpha04,
        border: Border.all(color: AppColors.inkAlpha20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 17, color: AppColors.black),
              SizedBox(width: 8),
              Text(
                "What you'll get",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '- 4 studio-ready angles: front, left, right, back\n- Consistent face, hair, skin tone, and body\n- Flat 20 credit charge for the full set',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.neutral800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerationStatus extends StatelessWidget {
  const _GenerationStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Model generated',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          Text(
            'Four angles were saved to Your Models.',
            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: 1,
            minHeight: 6,
            backgroundColor: AppColors.neutral100,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
          ),
        ],
      ),
    );
  }
}
