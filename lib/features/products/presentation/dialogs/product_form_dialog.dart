part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({
    required this.onDeletePhoto,
    required this.onReplacePhoto,
    this.product,
    this.showGallery = false,
    this.onClose,
  });

  final _Product? product;
  final Future<bool> Function(ProductPhoto photo) onDeletePhoto;
  final Future<ProductUpload?> Function(
    ProductPhoto photo,
    VoidCallback onUploadStart,
  )
  onReplacePhoto;
  final bool showGallery;
  final VoidCallback? onClose;

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _descriptionController;
  var _galleryPhotoIndex = 0;

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
      remaining:
          PRODUCT_PHOTO_UPLOAD_MAX_COUNT - ref.read(_formProvider).photoCount,
      title: 'Add product photos',
    );
    if (mounted && uploads.isNotEmpty) {
      ref.read(_formProvider.notifier).addPhotos(uploads);
    }
  }

  Future<void> _deletePhoto(int originalIndex, ProductPhoto photo) async {
    if (ref.read(_formProvider).photoCount <= 1) {
      AppSnackBar.showError(
        context,
        'Keep at least one reference image for this product.',
      );
      return;
    }
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

  Future<void> _cropNewPhoto(int index) async {
    final form = ref.read(_formProvider);
    if (index < 0 || index >= form.newPhotos.length) return;
    final source = form.newPhotos[index];
    await _showProductReferenceCrop(
      context,
      source: source,
      isReplacement: false,
      onSave: (cropped) async {
        if (!mounted) return false;
        ref.read(_formProvider.notifier).replaceNewPhoto(index, cropped);
        return true;
      },
    );
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
    final categoryNeedsSubtype = const {
      'Bags',
      'Jewelry',
    }.contains(form.category);
    if (!editing) {
      final notifier = ref.read(_formProvider.notifier);
      return SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddProductUploadStack(
              form: form,
              onPickPhotos: _pickPhotos,
              onAngleChanged: notifier.setNewAngle,
              onMovePhoto: notifier.movePhoto,
              onCropPhoto: (index) => unawaited(_cropNewPhoto(index)),
              onRemovePhoto: notifier.removeNewPhoto,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductField(
                    label: 'Product name',
                    galleryStyle: true,
                    child: AppTextField(
                      controller: _nameController,
                      hintText: 'Structured leather tote',
                    ),
                  ),
                  _ProductField(
                    label: 'SKU',
                    galleryStyle: true,
                    child: AppTextField(
                      controller: _skuController,
                      hintText: 'BAG-021',
                    ),
                  ),
                  _ProductField(
                    label: 'Category',
                    galleryStyle: true,
                    child: AppDropdown<String>(
                      value: form.category,
                      values: const [
                        'Other',
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
                      ],
                      labelFor: (value) => value,
                      onChanged: notifier.setCategory,
                    ),
                  ),
                  if (categoryNeedsSubtype)
                    _ProductField(
                      label: 'Sub-type',
                      galleryStyle: true,
                      helper: 'Choose a product sub-type so shoots place it correctly.',
                      child: _SubtypeRow(
                        category: form.category,
                        value: form.subtype,
                        onChanged: notifier.setSubtype,
                      ),
                    ),
                  _ProductField(
                    label: 'Description',
                    galleryStyle: true,
                    child: AppTextField(
                      controller: _descriptionController,
                      hintText: 'A short internal description for your team.',
                      minLines: 4,
                      maxLines: 5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showGallery)
            _EditableProductGallery(
              form: form,
              selectedIndex: _galleryPhotoIndex,
              onSelected: (index) => setState(() => _galleryPhotoIndex = index),
              onClose: widget.onClose ?? () => Navigator.pop(context),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showGallery) ...[
                  const _CatalogEyebrow('Product record'),
                  const SizedBox(height: 18),
                ],
                _ProductField(
                  label: 'Product Name',
                  required: !widget.showGallery,
                  galleryStyle: widget.showGallery,
                  child: AppTextField(controller: _nameController),
                ),
                _ProductField(
                  label: 'SKU',
                  required: !widget.showGallery,
                  galleryStyle: widget.showGallery,
                  child: AppTextField(controller: _skuController),
                ),
                _ProductField(
                  label: 'Category',
                  required: !widget.showGallery,
                  galleryStyle: widget.showGallery,
                  helper: widget.showGallery ? null : 'Proportions matter for this category. Calibrate after saving for sharper results.',
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
                    galleryStyle: widget.showGallery,
                    note: widget.showGallery
                        ? null
                        : 'helps the AI place the product correctly',
                    child: _SubtypeRow(
                      category: form.category,
                      value: form.subtype,
                      onChanged: ref.read(_formProvider.notifier).setSubtype,
                    ),
                  ),
                if (editing && !widget.showGallery)
                  _ProductIdCard(widget.product!.id),
                _ProductField(
                  label: 'Description',
                  galleryStyle: widget.showGallery,
                  note: widget.showGallery ? null : 'optional',
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
                    trailing:
                        '${form.photoCount}/$PRODUCT_PHOTO_UPLOAD_MAX_COUNT',
                    child: _ProductUploadBox(
                      label: 'Click to upload photos',
                      copy: 'PNG, JPG, or WebP, up to 20MB each',
                      onTap: _pickPhotos,
                    ),
                  )
                else ...[
                  _PhotoStrip(
                    title: editing
                        ? 'Reference Views'
                        : '${form.photoCount} photos selected',
                    countLabel: editing
                        ? '${form.photoCount} / $PRODUCT_PHOTO_UPLOAD_MAX_COUNT'
                        : null,
                    clearLabel: editing ? null : 'Clear all',
                    existingPhotos: form.visibleExistingPhotos,
                    replacementPhotos: form.replacementPhotos,
                    replacingPhotoId: form.replacingPhotoId,
                    newPhotos: form.newPhotos,
                    angles: form.angles,
                    newAngles: form.newAngles,
                    photoOrder: form.orderedPhotoTokens,
                    onAngleChanged: (index, angle) =>
                        ref.read(_formProvider.notifier).setAngle(index, angle),
                    onNewAngleChanged: (index, angle) => ref
                        .read(_formProvider.notifier)
                        .setNewAngle(index, angle),
                    onMovePhoto: ref.read(_formProvider.notifier).movePhoto,
                    onCropNew: (index) => unawaited(_cropNewPhoto(index)),
                    onRemoveNew: ref
                        .read(_formProvider.notifier)
                        .removeNewPhoto,
                    onDeletePhoto: _deletePhoto,
                    onReplacePhoto: _replacePhoto,
                    onClear: editing
                        ? null
                        : ref.read(_formProvider.notifier).clearNewPhotos,
                  ),
                  if (editing &&
                      form.photoCount < PRODUCT_PHOTO_UPLOAD_MAX_COUNT)
                    _ProductField(
                      label: 'Add New Photos',
                      trailing:
                          '${form.photoCount}/$PRODUCT_PHOTO_UPLOAD_MAX_COUNT total',
                      child: widget.showGallery
                          ? _EditProductUploadBox(onTap: _pickPhotos)
                          : _ProductUploadBox(
                              label: 'Add reference views',
                              copy: 'PNG, JPG, or WebP, up to 20MB each',
                              compact: true,
                              onTap: _pickPhotos,
                            ),
                    ),
                ],
                if (!editing && form.photoCount == 0)
                  const _ProductTip(
                    title: 'Pro Tip',
                    copy: 'Upload photos showing different angles for best AI results.',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableProductGallery extends StatelessWidget {
  const _EditableProductGallery({
    required this.form,
    required this.selectedIndex,
    required this.onSelected,
    required this.onClose,
  });

  final _ProductFormState form;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onClose;

  Widget _image(String token, BoxFit fit) {
    if (token.startsWith('new:')) {
      final upload = form.newPhotos.firstWhere(
        (photo) => photo.orderKey == token.substring(4),
      );
      return AppImage.memory(upload.bytes, fit: fit);
    }
    final photo = form.existingPhotos.firstWhere(
      (photo) => photo.id == token.substring(9),
    );
    final replacement = form.replacementPhotos[photo.id];
    return replacement == null
        ? _AssetImage(photo.url, fit: fit)
        : AppImage.memory(replacement.bytes, fit: fit);
  }

  @override
  Widget build(BuildContext context) {
    final photos = form.orderedPhotoTokens;
    if (photos.isEmpty) return const SizedBox.shrink();
    final currentIndex = min(selectedIndex, photos.length - 1);
    return ColoredBox(
      color: AppColors.neutral100,
      child: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: KeyedSubtree(
                    key: const ValueKey('product-edit-main-image'),
                    child: _image(photos[currentIndex], BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 44,
                  height: 44,
                  color: AppColors.black,
                  child: IconButton(
                    tooltip: 'Close product editor',
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: onClose,
                  ),
                ),
              ),
            ],
          ),
          if (photos.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: .78,
                ),
                itemBuilder: (context, index) => InkWell(
                  onTap: () => onSelected(index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: index == currentIndex
                                  ? AppColors.black
                                  : AppColors.neutral200,
                              width: index == currentIndex ? 2 : 1,
                            ),
                          ),
                          child: _image(photos[index], BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View ${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 9,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
