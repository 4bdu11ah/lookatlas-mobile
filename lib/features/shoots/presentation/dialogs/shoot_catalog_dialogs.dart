part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

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
  final List<OnboardingUpload> _photos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final files = await _pickShootPhotos(
      context,
      ref,
      remaining: 5 - _photos.length,
      title: 'Add product photos',
    );
    if (!mounted) return;
    setState(() {
      _photos.addAll([
        for (final file in files)
          OnboardingUpload(bytes: file.$1, fileName: file.$2),
      ]);
    });
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _skuController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty ||
        _photos.isEmpty) {
      AppSnackBar.showError(context, 'Complete all required product fields.');
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await ref
        .read(onboardingRepositoryProvider)
        .createProduct(
          ProductDraft(
            name: _nameController.text.trim(),
            sku: _skuController.text.trim(),
            category: _categoryController.text.trim(),
            photos: _photos,
          ),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result case Err(:final failure)) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    await ref.read(_createShootControllerProvider.notifier).load();
    if (!mounted) return;
    Navigator.pop(context);
    widget.onToast('Product added');
  }

  @override
  Widget build(BuildContext context) {
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
          isLoading: _isSubmitting,
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
          labelText: 'Category *',
          hintText: 'e.g., Bags',
        ),
        _DialogUpload(
          label: 'Photos · ${_photos.length}/5',
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
  final List<HouseModelUpload> _photos = [];
  bool _isSubmitting = false;

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
      remaining: 5 - _photos.length,
      title: 'Add model photos',
    );
    if (!mounted) return;
    setState(() {
      _photos.addAll([
        for (final file in files)
          HouseModelUpload(bytes: file.$1, fileName: file.$2),
      ]);
    });
  }

  Future<void> _submit() async {
    final height = int.tryParse(_heightController.text.trim());
    if (_nameController.text.trim().isEmpty ||
        _genderController.text.trim().isEmpty ||
        height == null ||
        _photos.isEmpty) {
      AppSnackBar.showError(context, 'Complete all required model fields.');
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await ref
        .read(houseModelsRepositoryProvider)
        .createModel(
          HouseModelDraft(
            name: _nameController.text.trim(),
            gender: _genderController.text.trim().toLowerCase(),
            heightCm: height,
            heightEstimated: false,
            photos: _photos,
          ),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result case Err(:final failure)) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    await ref.read(_createShootControllerProvider.notifier).load();
    if (!mounted) return;
    Navigator.pop(context);
    widget.onToast('Model added');
  }

  @override
  Widget build(BuildContext context) {
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
          isLoading: _isSubmitting,
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
          label: 'Photos · ${_photos.length}/5',
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
