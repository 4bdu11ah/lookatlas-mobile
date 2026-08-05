part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ModelFormData {
  const _ModelFormData({
    this.name = '',
    this.heightText = '',
    this.gender = _ModelGender.female,
    this.heightEstimated = false,
    this.existingPhotos = const [],
    this.newPhotos = const [],
    this.submitted = false,
    this.submitting = false,
  });

  final String name;
  final String heightText;
  final _ModelGender gender;
  final bool heightEstimated;
  final List<String> existingPhotos;
  final List<HouseModelUpload> newPhotos;
  final bool submitted;
  final bool submitting;

  int get photoCount => existingPhotos.length + newPhotos.length;

  bool get nameValid => name.trim().isNotEmpty;

  bool get heightValid {
    final h = int.tryParse(heightText);
    return h != null &&
        h >= HouseModelDraft.minHeightCm &&
        h <= HouseModelDraft.maxHeightCm;
  }

  bool get photosValid =>
      photoCount >= HouseModelDraft.minPhotoCount &&
      photoCount <= HouseModelDraft.maxPhotoCount;

  bool get isValid => nameValid && heightValid && photosValid;

  _ModelFormData copyWith({
    String? name,
    String? heightText,
    _ModelGender? gender,
    bool? heightEstimated,
    List<String>? existingPhotos,
    List<HouseModelUpload>? newPhotos,
    bool? submitted,
    bool? submitting,
  }) {
    return _ModelFormData(
      name: name ?? this.name,
      heightText: heightText ?? this.heightText,
      gender: gender ?? this.gender,
      heightEstimated: heightEstimated ?? this.heightEstimated,
      existingPhotos: existingPhotos ?? this.existingPhotos,
      newPhotos: newPhotos ?? this.newPhotos,
      submitted: submitted ?? this.submitted,
      submitting: submitting ?? this.submitting,
    );
  }
}

class _ModelFormNotifier extends Notifier<_ModelFormData> {
  @override
  _ModelFormData build() => const _ModelFormData();

  void initialize(_HouseModel? model) {
    if (model == null) return;
    state = state.copyWith(
      name: model.name,
      heightText: model.heightCm.toString(),
      gender: model.gender,
      heightEstimated: model.heightEstimated,
      existingPhotos: model.photoUrls.isNotEmpty
          ? [...model.photoUrls]
          : List.filled(model.photoCount, model.asset),
    );
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setHeightText(String value) => state = state.copyWith(heightText: value);
  void setGender(_ModelGender value) => state = state.copyWith(gender: value);
  void setHeightEstimated({required bool value}) =>
      state = state.copyWith(heightEstimated: value);

  void addPhotos(List<HouseModelUpload> photos) =>
      state = state.copyWith(newPhotos: [...state.newPhotos, ...photos]);

  void removeExistingPhoto(int index) {
    final photos = [...state.existingPhotos]..removeAt(index);
    state = state.copyWith(existingPhotos: photos);
  }

  void removeNewPhoto(int index) {
    final photos = [...state.newPhotos]..removeAt(index);
    state = state.copyWith(newPhotos: photos);
  }

  void setSubmitted() => state = state.copyWith(submitted: true);
  void setSubmitting({required bool value}) =>
      state = state.copyWith(submitting: value);

  Future<void> submit(
    Future<void> Function(_ModelFormInput input) onSubmit,
  ) async {
    state = state.copyWith(submitted: true);
    if (!state.isValid) return;
    final parsedHeight = int.tryParse(state.heightText);
    if (parsedHeight == null) return;
    state = state.copyWith(submitting: true);
    await onSubmit(
      _ModelFormInput(
        name: state.name.trim(),
        gender: state.gender,
        heightCm: parsedHeight,
        photos: List.unmodifiable(state.newPhotos),
        heightEstimated: state.heightEstimated,
      ),
    );
    if (state.submitting) {
      state = state.copyWith(submitting: false);
    }
  }
}

final NotifierProvider<_ModelFormNotifier, _ModelFormData> _modelFormProvider =
    NotifierProvider<_ModelFormNotifier, _ModelFormData>(
      _ModelFormNotifier.new,
    );

Future<void> _showModelFormDialog(
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

  final dialogConfig = model == null
      ? AppDialogConfig.standard
      : const AppDialogConfig(
          insetPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          maxWidth: 390,
        );
  return showAppDialog<void>(
    context: context,
    config: dialogConfig,
    title: model == null ? 'Add New Model' : 'Edit Model',
    subtitle: model == null
        ? 'Upload photos and details for your house model'
        : 'Update photos and details for ${model.name}',
    builder: (context) => _ModelFormDialog(
      model: model,
      onSubmit: (input) => submit(context, input),
    ),
    footer: Consumer(
      builder: (context, ref, _) {
        final formState = ref.watch(_modelFormProvider);
        final editing = model != null;
        return AppDialogActionFooter(
          primaryButtonKey: const ValueKey('submit-model-form'),
          primaryLabel: editing ? 'Update Model' : 'Add Model',
          primaryIcon: Icons.check,
          primaryOpacity: formState.isValid ? 1 : 0.48,
          isLoading: formState.submitting,
          onCancel: () => Navigator.pop(context),
          onPrimary: () => ref
              .read(_modelFormProvider.notifier)
              .submit(
                (input) => submit(context, input),
              ),
        );
      },
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
  final deleted = await showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    title: 'Delete Model',
    subtitle: 'This action cannot be undone',
    icon: Icons.delete_outline,
    iconBackgroundColor: AppColors.dangerDark,
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Text(
        'Are you sure you want to permanently delete this model? All associated photos and data will be removed from the system.',
        style: TextStyle(
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    ),
    footer: Consumer(
      builder: (context, ref, _) {
        final isMutating = ref.watch(
          _houseModelControllerProvider.select((s) => s.isMutating),
        );
        return AppDialogActionFooter(
          primaryLabel: 'Delete Model',
          primaryIcon: Icons.delete_outline,
          danger: true,
          isLoading: isMutating,
          onCancel: () => Navigator.pop(context, false),
          onPrimary: () async {
            final result = await ref
                .read(_houseModelControllerProvider.notifier)
                .deleteModel(model);
            if (!context.mounted) return;
            final failure = result.failureOrNull;
            if (failure != null) {
              AppSnackBar.showError(context, failure.message);
              return;
            }
            onToast('Model deleted');
            Navigator.pop(context, true);
          },
        );
      },
    ),
  );
  return deleted ?? false;
}

Future<bool> _showDeletePhotoDialog(
  BuildContext context,
  WidgetRef ref,
  Future<Result<void>> Function() onDelete,
) async {
  final deleted = await showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    title: 'Delete Photo',
    subtitle: 'This action cannot be undone',
    icon: Icons.delete_outline,
    iconBackgroundColor: AppColors.dangerDark,
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Text(
        'Are you sure you want to permanently delete this photo? It will be removed from the model.',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    ),

    footer: Consumer(
      builder: (context, ref, _) {
        final isMutating = ref.watch(
          _houseModelControllerProvider.select((s) => s.isMutating),
        );
        return AppDialogActionFooter(
          primaryLabel: 'Delete Photo',
          primaryIcon: Icons.delete_outline,
          danger: true,
          isLoading: isMutating,
          onCancel: () => Navigator.pop(context, false),
          onPrimary: () async {
            final result = await onDelete();
            if (!context.mounted) return;
            final failure = result.failureOrNull;
            if (failure != null) {
              AppSnackBar.showError(context, failure.message);
              return;
            }
            Navigator.pop(context, true);
          },
        );
      },
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
        if (stacked) actions[i] else actions[i],
        if (i != actions.length - 1)
          const SizedBox(
            height: 12,
          ),
      ],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(top: BorderSide(color: AppColors.neutral100)),
      ),
      child:
          // stacked
          //     ?
          Column(mainAxisSize: MainAxisSize.min, children: children),
      // : Row(children: children),
    );
  }
}

class _ModelFormDialog extends ConsumerStatefulWidget {
  const _ModelFormDialog({required this.onSubmit, this.model});

  final _HouseModel? model;
  final Future<void> Function(_ModelFormInput input) onSubmit;

  @override
  ConsumerState<_ModelFormDialog> createState() => _ModelFormDialogState();
}

class _ModelFormDialogState extends ConsumerState<_ModelFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    final model = widget.model;
    _nameController = TextEditingController(text: model?.name ?? '');
    _heightController = TextEditingController(
      text: model?.heightCm.toString() ?? '',
    );
    _nameController.addListener(
      () => ref.read(_modelFormProvider.notifier).setName(_nameController.text),
    );
    _heightController.addListener(
      () => ref
          .read(_modelFormProvider.notifier)
          .setHeightText(_heightController.text),
    );
    if (model != null) {
      unawaited(
        Future.microtask(() {
          if (mounted) ref.read(_modelFormProvider.notifier).initialize(model);
        }),
      );
    }
  }

  Future<void> _deleteExistingPhoto(int index) async {
    final formState = ref.read(_modelFormProvider);
    if (formState.submitting || widget.model == null) return;
    final deleted = await _showDeletePhotoDialog(
      context,
      ref,
      () => ref
          .read(_houseModelControllerProvider.notifier)
          .deletePhoto(widget.model!, index),
    );
    if (deleted && mounted) {
      ref.read(_modelFormProvider.notifier).removeExistingPhoto(index);
    }
  }

  Future<void> _pickPhotos() async {
    final formState = ref.read(_modelFormProvider);
    final remaining = HouseModelDraft.maxPhotoCount - formState.photoCount;
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
      if (mounted) ref.read(_modelFormProvider.notifier).addPhotos(uploads);
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
    final formState = ref.watch(_modelFormProvider);
    final editing = widget.model != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TextFieldBlock(
            label: 'Model Name',
            required: true,
            controller: _nameController,
            hint: 'Sarah Martinez',
            invalid: formState.submitted && !formState.nameValid,
            error: 'Enter a model name.',
          ),
          _SelectBlock<_ModelGender>(
            label: 'Gender',
            required: true,
            value: formState.gender,
            values: _ModelGender.values,
            labelFor: (value) => value.label,
            onChanged: ref.read(_modelFormProvider.notifier).setGender,
          ),
          _HeightBlock(
            controller: _heightController,
            estimated: formState.heightEstimated,
            invalid: formState.submitted && !formState.heightValid,
            onEstimatedChanged: (value) => ref
                .read(_modelFormProvider.notifier)
                .setHeightEstimated(value: value),
          ),
          _PhotoUploadBlock(
            existingPhotos: formState.existingPhotos,
            newPhotos: formState.newPhotos,
            editing: editing,
            invalid: formState.submitted && !formState.photosValid,
            onAdd: () => unawaited(_pickPhotos()),
            onRemoveExisting: (index) => unawaited(_deleteExistingPhoto(index)),
            onRemoveNew: ref.read(_modelFormProvider.notifier).removeNewPhoto,
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
  }
}
