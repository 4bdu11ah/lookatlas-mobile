part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _showProductDetailSheet(
  BuildContext context,
  WidgetRef ref,
  _Product product,
  ValueChanged<String> onToast,
) => showAppBottomSheet<void>(
  context,
  isScrollControlled: true,
  builder: (_) => _ProductDetailSheet(
    product: product,
    onToast: onToast,
    onCalibrate: () {
      Navigator.pop(context);
      unawaited(_openCalibration(context, ref, product, onToast));
    },
    onDelete: () async {
      Navigator.pop(context);
      await _showProductDeleteDialog(context, ref, product, onToast);
    },
  ),
);

class _ProductDetailSheet extends ConsumerStatefulWidget {
  const _ProductDetailSheet({
    required this.product,
    required this.onToast,
    required this.onCalibrate,
    required this.onDelete,
  });

  final _Product product;
  final ValueChanged<String> onToast;
  final VoidCallback onCalibrate;
  final Future<void> Function() onDelete;

  @override
  ConsumerState<_ProductDetailSheet> createState() =>
      _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<_ProductDetailSheet> {
  var _photoIndex = 0;
  var _confirmingDelete = false;
  var _editing = false;

  Future<ProductUpload?> _replacePhoto(
    ProductPhoto photo,
    VoidCallback onUploadStart,
  ) async {
    if (!_requestProductsManageAccess(context, ref)) return null;
    final replacement = await _pickProductPhoto(
      context,
      ref,
      title: 'Replace product photo',
    );
    if (replacement == null || !mounted) return null;
    ProductUpload? savedReplacement;
    await _showProductReferenceCrop(
      context,
      source: replacement,
      isReplacement: true,
      onSave: (cropped) async {
        onUploadStart();
        final result = await ref
            .read(_productsControllerProvider.notifier)
            .replacePhoto(widget.product, photo, cropped);
        if (!mounted) return false;
        final failure = result.failureOrNull;
        if (failure != null) {
          AppSnackBar.showError(context, failure.message);
          return false;
        }
        savedReplacement = cropped;
        widget.onToast('Photo replaced');
        return true;
      },
    );
    return savedReplacement;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    if (_editing) {
      return SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.94,
          child: Column(
            children: [
              Expanded(
                child: _ProductFormDialog(
                  product: product,
                  showGallery: true,
                  onClose: () => Navigator.pop(context),
                  onDeletePhoto: (photo) => _showProductDeletePhotoDialog(
                    context,
                    ref,
                    product,
                    photo,
                    widget.onToast,
                  ),
                  onReplacePhoto: _replacePhoto,
                ),
              ),
              _ProductFormFooter(
                product: product,
                launchContext: context,
                onToast: widget.onToast,
              ),
            ],
          ),
        ),
      );
    }
    final photos = product.photoAssets.isEmpty
        ? const ['']
        : product.photoAssets;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.94,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: AppColors.neutral100,
                  child: _AssetImage(
                    photos[_photoIndex],
                    key: const ValueKey('product-detail-main-image'),
                    fit: BoxFit.contain,
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
                      tooltip: 'Close product details',
                      icon: const Icon(Icons.close, color: AppColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            if (photos.length > 1)
              ColoredBox(
                color: AppColors.neutral100,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: photos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: .78,
                        ),
                    itemBuilder: (context, index) => Semantics(
                      button: true,
                      selected: index == _photoIndex,
                      label: 'View ${index + 1}',
                      child: InkWell(
                        onTap: () => setState(() => _photoIndex = index),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: index == _photoIndex
                                        ? AppColors.black
                                        : AppColors.neutral200,
                                    width: index == _photoIndex ? 2 : 1,
                                  ),
                                ),
                                child: _AssetImage(photos[index]),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View ${index + 1}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _CatalogEyebrow('Product record'),
                  const SizedBox(height: 5),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontFamily: _productDisplayFontFamily,
                      fontSize: 36,
                      height: 1,
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    Text(
                      product.description,
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _ProductDetailRow('SKU', product.sku),
                  _ProductDetailRow('Category', product.category),
                  if (product.subtype != null)
                    _ProductDetailRow('Sub-type', product.subtype!),
                  _ProductDetailRow('Reference views', '${product.photos}'),
                  _ProductDetailRow('Added', product.addedLabel),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: widget.onCalibrate,
                      child: _ProductPill.neutral(
                        product.status,
                        icon: Icons.straighten,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Start a shoot',
                    icon: Icons.photo_camera_outlined,
                    onPressed: () => context.go(
                      '${AppRoutes.createShoot}?productId=${Uri.encodeQueryComponent(product.id)}',
                    ),
                    height: 44,
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                  ),
                  const SizedBox(height: 8),
                  AppOutlinedButton(
                    label: 'Edit product',
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      if (_requestProductsManageAccess(context, ref)) {
                        setState(() => _editing = true);
                      }
                    },
                    height: 44,
                  ),
                  const SizedBox(height: 8),
                  if (_confirmingDelete)
                    Row(
                      children: [
                        Expanded(
                          child: AppOutlinedButton(
                            label: 'Cancel',
                            onPressed: () => setState(
                              () => _confirmingDelete = false,
                            ),
                            height: 44,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Confirm remove',
                            onPressed: widget.onDelete,
                            height: 44,
                            backgroundColor: AppColors.dangerDark,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ],
                    )
                  else
                    AppOutlinedButton(
                      label: 'Remove',
                      icon: Icons.delete_outline,
                      onPressed: () => setState(() => _confirmingDelete = true),
                      height: 44,
                      foregroundColor: AppColors.dangerDark,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailRow extends StatelessWidget {
  const _ProductDetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.neutral200)),
    ),
    child: Row(
      children: [
        Expanded(child: _CatalogEyebrow(label)),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

Future<void> _showProductFormDialog(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String> onToast, {
  _Product? product,
}) {
  if (!_requestProductsManageAccess(context, ref)) return Future.value();
  return showAppBottomSheet<void>(
    context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFBFBF9),
    barrierColor: const Color(0x9E000000),
    builder: (sheetContext) => Container(
      height: MediaQuery.sizeOf(sheetContext).height * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBF9),
        border: Border(top: BorderSide(color: Color(0xFF121211))),
      ),
      child: Column(
        children: [
          _ProductFormSheetHeader(editing: product != null),
          Expanded(
            child: _ProductFormDialog(
              product: product,
              onDeletePhoto: (photo) => _showProductDeletePhotoDialog(
                sheetContext,
                ref,
                product!,
                photo,
                onToast,
              ),
              onReplacePhoto: (photo, onUploadStart) async {
                if (!_requestProductsManageAccess(sheetContext, ref)) {
                  return null;
                }
                final replacement = await _pickProductPhoto(
                  sheetContext,
                  ref,
                  title: 'Replace product photo',
                );
                if (replacement == null || !sheetContext.mounted) return null;
                ProductUpload? savedReplacement;
                await _showProductReferenceCrop(
                  sheetContext,
                  source: replacement,
                  isReplacement: true,
                  onSave: (cropped) async {
                    onUploadStart();
                    final result = await ref
                        .read(_productsControllerProvider.notifier)
                        .replacePhoto(product!, photo, cropped);
                    if (!sheetContext.mounted) return false;
                    final failure = result.failureOrNull;
                    if (failure != null) {
                      AppSnackBar.showError(sheetContext, failure.message);
                      return false;
                    }
                    savedReplacement = cropped;
                    onToast('Photo replaced');
                    return true;
                  },
                );
                return savedReplacement;
              },
            ),
          ),
          _ProductFormFooter(
            product: product,
            launchContext: context,
            onToast: onToast,
          ),
        ],
      ),
    ),
  );
}

class _ProductFormSheetHeader extends StatelessWidget {
  const _ProductFormSheetHeader({required this.editing});

  final bool editing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 28, 12, 24),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.neutral200)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CatalogEyebrow(
                editing ? 'Product record' : 'New catalog object',
              ),
              const SizedBox(height: 9),
              Text(
                editing ? 'Edit product' : 'Add a product',
                style: TextStyle(
                  fontFamily: _productDisplayFontFamily,
                  fontSize: editing ? 30 : 38,
                  height: 0.98,
                  letterSpacing: -1.3,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Close',
          child: Semantics(
            button: true,
            label: 'Close',
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFD),
                border: Border.all(color: const Color(0xFFDEDED8)),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProductFormFooter extends ConsumerWidget {
  const _ProductFormFooter({
    required this.product,
    required this.launchContext,
    required this.onToast,
  });

  final _Product? product;
  final BuildContext launchContext;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(_productFormProvider(product));

    Future<void> submit() async {
      if (!_requestProductsManageAccess(context, ref)) return;
      final result = await ref
          .read(_productFormProvider(product).notifier)
          .submit(product);
      if (!context.mounted || result == null) return;
      final failure = result.failureOrNull;
      if (failure != null) {
        AppSnackBar.showError(context, failure.message);
        return;
      }
      Navigator.pop(context);
      onToast(product == null ? 'Product added' : 'Product updated');
      if (product == null && launchContext.mounted) {
        final created = ref
            .read(_productsControllerProvider)
            .products
            .where((item) => item.sku == form.sku.trim())
            .firstOrNull;
        if (created != null) {
          await _showProductDetailSheet(
            launchContext,
            ref,
            created,
            onToast,
          );
        }
      }
    }

    if (product != null) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.neutral200)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  key: const ValueKey('submit-product-form'),
                  label: 'Save changes',
                  icon: Icons.check,
                  onPressed: form.isValid ? submit : null,
                  isLoading: form.isSubmitting,
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppOutlinedButton(
                  label: 'Cancel',
                  onPressed: form.isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  borderColor: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final enabled = form.isValid && !form.isSubmitting;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 17, 22, 0),
        decoration: const BoxDecoration(
          color: Color(0xFFFBFBF9),
          border: Border(top: BorderSide(color: Color(0xFFDEDED8))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '▧  Order, angles, and crop choices are saved with the product.',
              style: TextStyle(color: Color(0xFF696964), fontSize: 9),
            ),
            const SizedBox(height: 18),
            Opacity(
              opacity: enabled ? 1 : 0.48,
              child: PrimaryButton(
                key: const ValueKey('submit-product-form'),
                label: 'Add to library →',
                onPressed: enabled ? submit : null,
                isLoading: form.isSubmitting,
                height: 44,
                backgroundColor: const Color(0xFF121211),
                foregroundColor: const Color(0xFFFBFBF9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showProductDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  _Product product,
  ValueChanged<String> onToast,
) {
  if (!_requestProductsManageAccess(context, ref)) return Future.value();
  return showAppDialog<void>(
    context: context,
    config: AppDialogConfig.standard.copyWith(maxHeightOffset: 80),
    title: 'Delete Product',
    subtitle: 'This action cannot be undone',
    icon: Icons.delete_outline,
    iconBackgroundColor: AppColors.dangerDark,
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Text(
        'Are you sure you want to permanently delete this product? All associated photos and data will be removed from the system.',
        style: TextStyle(fontSize: 14, height: 1.55),
      ),
    ),

    footer: AppDialogActionFooter(
      primaryLabel: 'Delete Product',
      primaryIcon: Icons.delete_outline,
      danger: true,
      onCancel: () => Navigator.pop(context),
      onPrimary: () async {
        final result = await ref
            .read(_productsControllerProvider.notifier)
            .deleteProduct(product);
        if (!context.mounted) return;
        final failure = result.failureOrNull;
        if (failure != null) {
          AppSnackBar.showError(context, failure.message);
          return;
        }
        Navigator.pop(context);
        onToast('${product.name} deleted');
      },
    ),
  );
}

Future<bool> _showProductDeletePhotoDialog(
  BuildContext context,
  WidgetRef ref,
  _Product product,
  ProductPhoto photo,
  ValueChanged<String> onToast,
) async {
  if (!_requestProductsManageAccess(context, ref)) return false;
  final deleted = await showAppDialog<bool>(
    context: context,
    config: AppDialogConfig.standard.copyWith(maxHeightOffset: 80),
    title: 'Delete Photo',
    subtitle: 'This action cannot be undone',
    icon: Icons.photo_camera_outlined,
    iconBackgroundColor: AppColors.dangerDark,
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Text(
        'Are you sure you want to permanently delete this photo from the product? This action cannot be undone.',
        style: TextStyle(fontSize: 14, height: 1.55),
      ),
    ),

    footer: Consumer(
      builder: (context, ref, _) {
        final isMutating = ref.watch(
          _productsControllerProvider.select((state) => state.isMutating),
        );
        return AppDialogActionFooter(
          primaryLabel: 'Delete Photo',
          primaryIcon: Icons.photo_camera_outlined,
          danger: true,
          isLoading: isMutating,
          onCancel: () => Navigator.pop(context, false),
          onPrimary: () async {
            final result = await ref
                .read(_productsControllerProvider.notifier)
                .deletePhoto(product, photo.id);
            if (!context.mounted) return;
            final failure = result.failureOrNull;
            if (failure != null) {
              AppSnackBar.showError(context, failure.message);
              return;
            }
            Navigator.pop(context, true);
            onToast('Photo deleted');
          },
        );
      },
    ),
  );
  return deleted ?? false;
}
