part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _AddProductPhotos extends Notifier<List<OnboardingUpload>> {
  @override
  List<OnboardingUpload> build() => const [];

  void _set({required List<OnboardingUpload> value}) {
    if (identical(state, value)) return;
    state = value;
  }
}

class _AddProductSubmitting extends Notifier<bool> {
  @override
  bool build() => false;

  void _set({required bool value}) {
    if (state == value) return;
    state = value;
  }
}

class _AddModelPhotos extends Notifier<List<HouseModelUpload>> {
  @override
  List<HouseModelUpload> build() => const [];

  void _set({required List<HouseModelUpload> value}) {
    if (identical(state, value)) return;
    state = value;
  }
}

class _AddModelSubmitting extends Notifier<bool> {
  @override
  bool build() => false;

  void _set({required bool value}) {
    if (state == value) return;
    state = value;
  }
}

final NotifierProvider<_AddProductPhotos, List<OnboardingUpload>>
_addProductPhotosProvider =
    NotifierProvider.autoDispose<_AddProductPhotos, List<OnboardingUpload>>(
      _AddProductPhotos.new,
    );
final NotifierProvider<_AddProductSubmitting, bool>
_addProductSubmittingProvider =
    NotifierProvider.autoDispose<_AddProductSubmitting, bool>(
      _AddProductSubmitting.new,
    );
final NotifierProvider<_AddModelPhotos, List<HouseModelUpload>>
_addModelPhotosProvider =
    NotifierProvider.autoDispose<_AddModelPhotos, List<HouseModelUpload>>(
      _AddModelPhotos.new,
    );
final NotifierProvider<_AddModelSubmitting, bool> _addModelSubmittingProvider =
    NotifierProvider.autoDispose<_AddModelSubmitting, bool>(
      _AddModelSubmitting.new,
    );

class _AddProductDialog extends ConsumerStatefulWidget {
  const _AddProductDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  ConsumerState<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<_AddProductDialog> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final files = await _pickShootPhotos(
      context,
      ref,
      remaining: 5 - ref.read(_addProductPhotosProvider).length,
      title: 'Add product photos',
    );
    if (!mounted) return;
    ref
        .read(_addProductPhotosProvider.notifier)
        ._set(
          value: [
            ...ref.read(_addProductPhotosProvider),
            for (final file in files)
              OnboardingUpload(bytes: file.$1, fileName: file.$2),
          ],
        );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _skuController.text.trim().isEmpty ||
        ref.read(_addProductPhotosProvider).isEmpty) {
      AppSnackBar.showError(context, 'Complete all required product fields.');
      return;
    }
    ref.read(_addProductSubmittingProvider.notifier)._set(value: true);
    final result = await ref
        .read(onboardingRepositoryProvider)
        .createProduct(
          ProductDraft(
            name: _nameController.text.trim(),
            sku: _skuController.text.trim(),
            category: _categoryController.text.trim(),
            description: _descriptionController.text.trim(),
            photos: ref.read(_addProductPhotosProvider),
          ),
        );
    if (!mounted) return;
    ref.read(_addProductSubmittingProvider.notifier)._set(value: false);
    if (result case Err(:final failure)) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    await ref
        .read(_createShootControllerProvider.notifier)
        .load(preferredProductId: result.valueOrNull);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onToast('Product added');
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(_addProductPhotosProvider);
    final isSubmitting = ref.watch(_addProductSubmittingProvider);
    return _ModalFrame(
      title: 'Add New Product',
      subtitle: 'It will also be saved to Products',
      leading: Icons.inventory_2_outlined,
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Add Product',
          icon: Icons.check,
          isLoading: isSubmitting,
          onPressed: _submit,
        ),
      ],
      children: [
        AppTextField(
          controller: _nameController,
          labelText: 'Product name *',
          hintText: 'e.g., Classic Cotton T-Shirt',
        ),
        AppTextField(
          controller: _skuController,
          labelText: 'SKU *',
          hintText: 'e.g., TSH-001',
        ),
        AppTextField(
          controller: _categoryController,
          labelText: 'Category (optional)',
          hintText: 'e.g., Bags',
        ),
        AppTextField(
          controller: _descriptionController,
          labelText: 'Description (optional)',
          hintText: 'Describe your product',
          minLines: 3,
          maxLines: 3,
        ),
        _DialogUpload(
          label: 'Photos · ${photos.length}/5',
          onTap: _pickPhotos,
        ),
      ],
    );
  }
}

class _AddModelDialog extends ConsumerStatefulWidget {
  const _AddModelDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  ConsumerState<_AddModelDialog> createState() => _AddModelDialogState();
}

class _AddModelDialogState extends ConsumerState<_AddModelDialog> {
  final _nameController = TextEditingController();
  final _genderController = TextEditingController(text: 'female');
  final _heightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final files = await _pickShootPhotos(
      context,
      ref,
      remaining: 5 - ref.read(_addModelPhotosProvider).length,
      title: 'Add model photos',
    );
    if (!mounted) return;
    ref
        .read(_addModelPhotosProvider.notifier)
        ._set(
          value: [
            ...ref.read(_addModelPhotosProvider),
            for (final file in files)
              HouseModelUpload(bytes: file.$1, fileName: file.$2),
          ],
        );
  }

  Future<void> _submit() async {
    final height = int.tryParse(_heightController.text.trim());
    if (_nameController.text.trim().isEmpty ||
        _genderController.text.trim().isEmpty ||
        height == null ||
        height < HouseModelDraft.minHeightCm ||
        height > HouseModelDraft.maxHeightCm ||
        ref.read(_addModelPhotosProvider).isEmpty) {
      AppSnackBar.showError(
        context,
        'Complete all fields. Height must be between 100 and 250 cm.',
      );
      return;
    }
    ref.read(_addModelSubmittingProvider.notifier)._set(value: true);
    final result = await ref
        .read(houseModelsRepositoryProvider)
        .createModel(
          HouseModelDraft(
            name: _nameController.text.trim(),
            gender: _genderController.text.trim().toLowerCase(),
            heightCm: height,
            heightEstimated: false,
            photos: ref.read(_addModelPhotosProvider),
          ),
        );
    if (!mounted) return;
    ref.read(_addModelSubmittingProvider.notifier)._set(value: false);
    if (result case Err(:final failure)) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    await ref
        .read(_createShootControllerProvider.notifier)
        .load(preferredModelName: _nameController.text.trim());
    if (!mounted) return;
    Navigator.pop(context);
    widget.onToast('Model added');
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(_addModelPhotosProvider);
    final isSubmitting = ref.watch(_addModelSubmittingProvider);
    return _ModalFrame(
      title: 'Add New Model',
      subtitle: 'Upload photos and details',
      leading: Icons.person_outline,
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Add Model',
          icon: Icons.check,
          isLoading: isSubmitting,
          onPressed: _submit,
        ),
      ],
      children: [
        AppTextField(
          controller: _nameController,
          labelText: 'Model name *',
          hintText: 'e.g., Sarah Martinez',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: _genderController,
                labelText: 'Gender *',
                hintText: 'Female',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextField(
                controller: _heightController,
                labelText: 'Height (cm) *',
                hintText: '170',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        _DialogUpload(
          label: 'Photos · ${photos.length}/5',
          onTap: _pickPhotos,
        ),
      ],
    );
  }
}

Future<List<(Uint8List, String)>> _pickShootPhotos(
  BuildContext context,
  WidgetRef ref, {
  required int remaining,
  required String title,
}) async {
  if (remaining <= 0) {
    AppSnackBar.show(context, 'You can upload up to 5 photos.');
    return const [];
  }
  final source = await showImageSourceSheet(context, title: title);
  if (source == null || !context.mounted) return const [];
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
    final uploads = <(Uint8List, String)>[];
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes <= 10 * 1024 * 1024) {
        uploads.add((bytes, file.name));
      }
    }
    return uploads;
  } on Exception {
    if (context.mounted) {
      AppSnackBar.showError(context, 'Could not open your photo library.');
    }
    return const [];
  }
}
