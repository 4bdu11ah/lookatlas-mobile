part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({
    required this.onDeletePhoto,
    required this.onReplacePhoto,
    this.product,
  });

  final _Product? product;
  final Future<bool> Function(ProductPhoto photo) onDeletePhoto;
  final Future<ProductUpload?> Function(
    ProductPhoto photo,
    VoidCallback onUploadStart,
  )
  onReplacePhoto;

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _descriptionController;

  NotifierProvider<_ProductFormController, _ProductFormState>
  get _formProvider => _productFormProvider(widget.product);

  @override
  void initState() {
    super.initState();
    final form = ref.read(_formProvider);
    _nameController = TextEditingController(text: form.name)
      ..addListener(
        () => ref.read(_formProvider.notifier).setName(_nameController.text),
      );
    _skuController = TextEditingController(text: form.sku)
      ..addListener(
        () => ref.read(_formProvider.notifier).setSku(_skuController.text),
      );
    _descriptionController = TextEditingController(text: form.description)
      ..addListener(
        () => ref
            .read(_formProvider.notifier)
            .setDescription(_descriptionController.text),
      );
  }

  Future<void> _pickPhotos() async {
    final uploads = await _pickProductPhotos(
      context,
      ref,
      remaining: 10 - ref.read(_formProvider).photoCount,
      title: 'Add product photos',
    );
    if (mounted && uploads.isNotEmpty) {
      ref.read(_formProvider.notifier).addPhotos(uploads);
    }
  }

  Future<void> _deletePhoto(int originalIndex, ProductPhoto photo) async {
    final deleted = await widget.onDeletePhoto(photo);
    if (mounted && deleted) {
      ref.read(_formProvider.notifier).removeExistingPhoto(originalIndex);
    }
  }

  Future<void> _replacePhoto(ProductPhoto photo) async {
    final notifier = ref.read(_formProvider.notifier);
    var uploadStarted = false;
    try {
      final replacement = await widget.onReplacePhoto(photo, () {
        if (!mounted) return;
        uploadStarted = true;
        notifier.setReplacingPhoto(photo.id);
      });
      if (mounted && replacement != null) {
        notifier.replaceExistingPhoto(photo, replacement);
      }
    } finally {
      if (mounted && uploadStarted) notifier.clearReplacingPhoto();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(_formProvider);
    final editing = widget.product != null;
    final categoryNeedsSubtype = form.category == 'Bags';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProductField(
            label: 'Product Name',
            required: true,
            child: AppTextField(
              controller: _nameController,
            ),
          ),
          _ProductField(
            label: 'SKU',
            required: !editing,
            note: editing ? 'cannot be changed' : null,
            child: IgnorePointer(
              ignoring: editing,
              child: AppTextField(
                controller: _skuController,
              ),
            ),
          ),
          _ProductField(
            label: 'Category',
            required: true,
            helper:
                'Proportions matter for this category. Calibrate after saving for sharper results.',
            child: AppDropdown<String>(
              value: form.category,
              values: const [
                'Tops',
                'Dresses',
                'Outerwear',
                'Bottoms',
                'Bags',
                'Shoes',
                'Jewelry',
                'Eyewear',
                'Watches',
                'Accessories',
                'Other',
              ],
              labelFor: (value) => value,
              onChanged: ref.read(_formProvider.notifier).setCategory,
            ),
          ),
          if (categoryNeedsSubtype)
            _ProductField(
              label: 'Sub-type',
              note: 'helps the AI place the product correctly',
              child: _SubtypeRow(
                value: form.subtype,
                onChanged: ref.read(_formProvider.notifier).setSubtype,
              ),
            ),
          if (editing) _ProductIdCard(widget.product!.id),
          _ProductField(
            label: 'Description',
            note: 'optional',
            child: AppTextField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 5,
            ),
          ),
          if (form.photoCount == 0)
            _ProductField(
              label: 'Product Photos',
              required: true,
              trailing: '${form.photoCount}/10',
              child: _ProductUploadBox(
                label: 'Click to upload photos',
                copy:
                    'or drag and drop\nPNG, JPG, WebP or HEIC up to 30MB each',
                onTap: _pickPhotos,
              ),
            )
          else ...[
            _PhotoStrip(
              title: editing
                  ? 'Current Photos'
                  : '${form.photoCount} photos selected',
              countLabel: editing
                  ? '${form.visibleExistingPhotos.length} existing'
                  : null,
              clearLabel: editing ? null : 'Clear all',
              existingPhotos: form.visibleExistingPhotos,
              replacementPhotos: form.replacementPhotos,
              replacingPhotoId: form.replacingPhotoId,
              newPhotos: form.newPhotos,
              angles: form.angles,
              newAngles: form.newAngles,
              onAngleChanged: (index, angle) =>
                  ref.read(_formProvider.notifier).setAngle(index, angle),
              onNewAngleChanged: (index, angle) =>
                  ref.read(_formProvider.notifier).setNewAngle(index, angle),
              onDeletePhoto: _deletePhoto,
              onReplacePhoto: _replacePhoto,
              onClear: editing
                  ? null
                  : ref.read(_formProvider.notifier).clearNewPhotos,
            ),
            if (editing)
              _ProductField(
                label: 'Add New Photos',
                trailing: '${form.photoCount}/10 total',
                child: _ProductUploadBox(
                  label: 'Click to add more photos',
                  copy: 'PNG, JPG, WebP or HEIC up to 30MB each',
                  compact: true,
                  onTap: _pickPhotos,
                ),
              ),
          ],
          if (!editing && form.photoCount == 0)
            const _ProductTip(
              title: 'Pro Tip',
              copy:
                  'Upload photos showing different angles for best AI results.',
            ),
        ],
      ),
    );
  }
}
