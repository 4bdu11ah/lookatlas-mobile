part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _showModelFormSheet(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String> onToast, [
  _HouseModel? model,
]) {
  Future<void> submit(
    BuildContext formContext,
    _ModelFormInput input,
  ) async {
    final controller = ref.read(_houseModelControllerProvider.notifier);
    final result = model == null
        ? await controller.addModel(input)
        : await controller.updateModel(model, input);
    if (!formContext.mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(formContext, failure.message);
      return;
    }
    onToast(model == null ? 'Model added to Your Models' : 'Model updated');
    Navigator.pop(formContext);
  }

  Future<void> deleteFromForm(BuildContext formContext) async {
    final deleted = await _showDeleteSheet(
      formContext,
      ref,
      model!,
      onToast,
    );
    if (deleted && formContext.mounted) Navigator.pop(formContext);
  }

  if (model == null) {
    return showAppDialog<void>(
      context: context,
      builder: (context) => _ModelFormSheet(
        dialog: true,
        onSubmit: (input) => submit(context, input),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.neutral50,
    shape: const RoundedRectangleBorder(),
    builder: (context) => _ModelFormSheet(
      model: model,
      onSubmit: (input) => submit(context, input),
      onDelete: () => unawaited(deleteFromForm(context)),
    ),
  );
}

Future<void> _showAiSheet(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String> onToast,
) {
  return showAppDialog<void>(
    context: context,
    builder: (context) => _AiModelSheet(
      dialog: true,
      onGenerated: (gender, age, description) async {
        final result = await ref
            .read(_houseModelControllerProvider.notifier)
            .addAiModel(gender: gender, age: age, description: description);
        if (!context.mounted) return false;
        final failure = result.failureOrNull;
        if (failure != null) {
          AppSnackBar.showError(context, failure.message);
          return false;
        }
        onToast('AI model is ready');
        return true;
      },
    ),
  );
}

Future<bool> _showDeleteSheet(
  BuildContext context,
  WidgetRef ref,
  _HouseModel model,
  ValueChanged<String> onToast,
) async {
  var deleting = false;
  final deleted = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => SafeArea(
        child: _SheetFrame(
          actions: [
            _ModelActionButton.secondary(
              label: 'Cancel',
              full: true,
              onTap: () => Navigator.pop(context),
            ),
            _DangerButton(
              label: 'Delete model',
              isLoading: deleting,
              onTap: () async {
                setModalState(() => deleting = true);
                final result = await ref
                    .read(_houseModelControllerProvider.notifier)
                    .deleteModel(model);
                if (!context.mounted) return;
                final failure = result.failureOrNull;
                if (failure != null) {
                  setModalState(() => deleting = false);
                  AppSnackBar.showError(context, failure.message);
                  return;
                }
                Navigator.pop(context, true);
                onToast('Model deleted');
              },
            ),
          ],
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConfirmIcon(),
              Text(
                'Delete model?',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This permanently removes the model and all associated photos. This action cannot be undone.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return deleted ?? false;
}

class _ModelDialogHeader extends StatelessWidget {
  const _ModelDialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.neutral100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: AppTypography.medium,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: 'Close',
            button: true,
            child: InkWell(
              onTap: onClose,
              child: const SizedBox.square(
                dimension: 40,
                child: Icon(Icons.close, size: 20, color: AppColors.neutral500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelDialogFooter extends StatelessWidget {
  const _ModelDialogFooter({required this.actions, this.stacked = false});

  final List<Widget> actions;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (var i = 0; i < actions.length; i++) ...[
        if (stacked) actions[i] else Expanded(child: actions[i]),
        if (i != actions.length - 1)
          SizedBox(width: stacked ? 0 : 12, height: stacked ? 12 : 0),
      ],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(top: BorderSide(color: AppColors.neutral100)),
      ),
      child: stacked
          ? Column(mainAxisSize: MainAxisSize.min, children: children)
          : Row(children: children),
    );
  }
}

class _ModelFormSheet extends ConsumerStatefulWidget {
  const _ModelFormSheet({
    required this.onSubmit,
    this.model,
    this.onDelete,
    this.dialog = false,
  });

  final _HouseModel? model;
  final Future<void> Function(_ModelFormInput input) onSubmit;
  final VoidCallback? onDelete;
  final bool dialog;

  @override
  ConsumerState<_ModelFormSheet> createState() => _ModelFormSheetState();
}

class _ModelFormSheetState extends ConsumerState<_ModelFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late _ModelGender _gender;
  late final List<String> _existingPhotos;
  final List<HouseModelUpload> _newPhotos = [];
  final Set<int> _removedPhotoIndexes = {};
  bool _heightEstimated = false;
  bool _submitted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final model = widget.model;
    _nameController = TextEditingController(text: model?.name ?? '');
    _heightController = TextEditingController(
      text: model == null ? '' : model.heightCm.toString(),
    );
    _gender = model?.gender ?? _ModelGender.female;
    _existingPhotos = model == null
        ? []
        : model.photoUrls.isNotEmpty
        ? [...model.photoUrls]
        : List.filled(model.photoCount, model.asset);
    _heightEstimated = model?.heightEstimated ?? false;
  }

  int get _photoCount =>
      _existingPhotos.length - _removedPhotoIndexes.length + _newPhotos.length;

  Future<void> _pickPhotos() async {
    final remaining = 5 - _photoCount;
    if (remaining <= 0) {
      AppSnackBar.show(context, 'You can upload up to 5 photos.');
      return;
    }
    final source = await showImageSourceSheet(
      context,
      title: 'Add model photos',
    );
    if (source == null || !mounted) return;
    try {
      final picker = ref.read(imagePickerProvider);
      final files = source == ImageSource.camera
          ? [
              ?await picker.pickImage(
                source: source,
                maxWidth: 1600,
                imageQuality: 85,
              ),
            ]
          : await picker.pickMultiImage(
              maxWidth: 1600,
              imageQuality: 85,
              limit: remaining,
            );
      final uploads = <HouseModelUpload>[];
      for (final file in files.take(remaining)) {
        final bytes = await file.readAsBytes();
        if (bytes.lengthInBytes > 10 * 1024 * 1024) {
          if (mounted) {
            AppSnackBar.showError(
              context,
              '${file.name} is larger than 10MB.',
            );
          }
          continue;
        }
        uploads.add(HouseModelUpload(bytes: bytes, fileName: file.name));
      }
      if (mounted) setState(() => _newPhotos.addAll(uploads));
    } on Exception {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Could not open your camera or photo library.',
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.model != null;
    final nameValid = _nameController.text.trim().isNotEmpty;
    final height = int.tryParse(_heightController.text);
    final heightValid = height != null && height >= 100 && height <= 250;
    final photosValid = _photoCount > 0;
    final formValid = nameValid && heightValid && photosValid;
    final body = SingleChildScrollView(
      padding: widget.dialog
          ? const EdgeInsets.fromLTRB(20, 18, 20, 20)
          : const EdgeInsets.fromLTRB(18, 24, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.dialog)
            _IntroCopy(
              title: editing ? 'Update model details' : 'Add your house model',
              body: editing
                  ? 'Keep this profile accurate so future shoots preserve the right appearance and proportions.'
                  : 'Upload clear photos and a few details so the same face and proportions stay consistent across every shoot.',
            ),
          _TextFieldBlock(
            label: 'Model Name',
            required: true,
            controller: _nameController,
            hint: 'Sarah Martinez',
            invalid: _submitted && !nameValid,
            error: 'Enter a model name.',
            onChanged: (_) => setState(() {}),
          ),
          _SelectBlock<_ModelGender>(
            label: 'Gender',
            required: true,
            value: _gender,
            values: _ModelGender.values,
            labelFor: (value) => value.label,
            onChanged: (value) => setState(() => _gender = value),
          ),
          _HeightBlock(
            controller: _heightController,
            estimated: _heightEstimated,
            invalid: _submitted && !heightValid,
            onEstimatedChanged: (value) =>
                setState(() => _heightEstimated = value),
            onChanged: (_) => setState(() {}),
          ),
          _PhotoUploadBlock(
            existingPhotos: _existingPhotos,
            newPhotos: _newPhotos,
            removedExistingIndexes: _removedPhotoIndexes,
            invalid: _submitted && !photosValid,
            onAdd: () => unawaited(_pickPhotos()),
            onRemoveExisting: (index) =>
                setState(() => _removedPhotoIndexes.add(index)),
            onRemoveNew: (index) => setState(() => _newPhotos.removeAt(index)),
          ),
          const _TipCard(
            icon: Icons.info_outline,
            title: 'Pro Tip',
            body:
                'Upload 3-5 photos showing different angles and poses for best AI results.',
          ),
        ],
      ),
    );
    final actions = [
      _ModelActionButton.secondary(
        label: 'Cancel',
        full: true,
        onTap: () => Navigator.pop(context),
      ),
      Opacity(
        opacity: widget.dialog && !formValid ? 0.48 : 1,
        child: _ModelActionButton(
          key: const ValueKey('submit-model-form'),
          label: editing ? 'Save changes' : 'Add Model',
          icon: Icons.check,
          full: true,
          isLoading: _submitting,
          onTap: () async {
            setState(() => _submitted = true);
            final parsedHeight = int.tryParse(_heightController.text);
            if (!nameValid || parsedHeight == null || !heightValid) {
              return;
            }
            if (!photosValid) return;
            setState(() => _submitting = true);
            await widget.onSubmit(
              _ModelFormInput(
                name: _nameController.text.trim(),
                gender: _gender,
                heightCm: parsedHeight,
                photos: List.unmodifiable(_newPhotos),
                removedPhotoIndexes: _removedPhotoIndexes.toList(
                  growable: false,
                )..sort(),
                heightEstimated: _heightEstimated,
              ),
            );
            if (mounted) setState(() => _submitting = false);
          },
        ),
      ),
    ];

    if (widget.dialog) {
      return Column(
        children: [
          _ModelDialogHeader(
            title: 'Add New Model',
            subtitle: 'Upload photos and details for your house model',
            onClose: () => Navigator.pop(context),
          ),
          Expanded(child: body),
          _ModelDialogFooter(actions: actions),
        ],
      );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.94,
      child: Column(
        children: [
          _InnerHeader(
            title: editing ? 'Edit model' : 'Add new model',
            onClose: () => Navigator.pop(context),
            trailing: widget.onDelete == null
                ? null
                : IconButton(
                    tooltip: 'Delete model',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: widget.onDelete,
                  ),
          ),
          Expanded(child: body),
          _SheetActionBar(actions: actions),
        ],
      ),
    );
  }
}
