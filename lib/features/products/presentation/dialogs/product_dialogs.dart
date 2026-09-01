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
    onEdit: () {
      Navigator.pop(context);
      unawaited(
        _showProductFormDialog(
          context,
          ref,
          onToast,
          product: product,
        ),
      );
    },
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

class _ProductDetailSheet extends StatefulWidget {
  const _ProductDetailSheet({
    required this.product,
    required this.onEdit,
    required this.onCalibrate,
    required this.onDelete,
  });

  final _Product product;
  final VoidCallback onEdit;
  final VoidCallback onCalibrate;
  final Future<void> Function() onDelete;

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  var _photoIndex = 0;
  var _confirmingDelete = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
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
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  color: AppColors.neutral100,
                  child: _AssetImage(photos[_photoIndex]),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) => Semantics(
                    button: true,
                    selected: index == _photoIndex,
                    label:
                        product.productPhotos
                            .elementAtOrNull(index)
                            ?.viewAngle ??
                        'View ${index + 1}',
                    child: InkWell(
                      onTap: () => setState(() => _photoIndex = index),
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
                      fontFamily: 'Instrument Serif',
                      fontFamilyFallback: ['serif'],
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
                    onPressed: widget.onEdit,
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
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * 0.94,
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
                onUploadStart();
                final result = await ref
                    .read(_productsControllerProvider.notifier)
                    .replacePhoto(product!, photo, replacement);
                if (!sheetContext.mounted) return null;
                final failure = result.failureOrNull;
                if (failure != null) {
                  AppSnackBar.showError(sheetContext, failure.message);
                  return null;
                }
                onToast('Photo replaced');
                return replacement;
              },
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final form = ref.watch(_productFormProvider(product));
              return AppDialogActionFooter(
                primaryButtonKey: const ValueKey('submit-product-form'),
                primaryLabel: product == null
                    ? 'Add to library'
                    : 'Save changes',
                primaryIcon: Icons.arrow_forward,
                primaryDisabled: !form.isValid,
                isLoading: form.isSubmitting,
                onCancel: () => Navigator.pop(sheetContext),
                onPrimary: () async {
                  if (!_requestProductsManageAccess(sheetContext, ref)) {
                    return;
                  }
                  final result = await ref
                      .read(_productFormProvider(product).notifier)
                      .submit(product);
                  if (!sheetContext.mounted || result == null) return;
                  final failure = result.failureOrNull;
                  if (failure != null) {
                    AppSnackBar.showError(sheetContext, failure.message);
                    return;
                  }
                  Navigator.pop(sheetContext);
                  onToast(
                    product == null ? 'Product added' : 'Product updated',
                  );
                  if (product == null && context.mounted) {
                    final created = ref
                        .read(_productsControllerProvider)
                        .products
                        .where((item) => item.sku == form.sku.trim())
                        .firstOrNull;
                    if (created != null) {
                      await _showProductDetailSheet(
                        context,
                        ref,
                        created,
                        onToast,
                      );
                    }
                  }
                },
              );
            },
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
    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
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
              const SizedBox(height: 4),
              Text(
                editing ? 'Edit product' : 'Add a product',
                style: const TextStyle(
                  fontFamily: 'Instrument Serif',
                  fontFamilyFallback: ['serif'],
                  fontSize: 30,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        AppIconButton(
          icon: Icons.close,
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
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
