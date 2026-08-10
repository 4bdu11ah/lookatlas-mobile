part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _showProductFormDialog(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String> onToast, {
  _Product? product,
}) {
  return showAppDialog<void>(
    context: context,
    title: product == null ? 'Add New Product' : 'Edit Product',
    subtitle: product == null
        ? 'Add a new product to your catalog'
        : 'Edit product details',
    icon: product == null ? Icons.add : Icons.edit_outlined,
    iconBackgroundColor: product == null
        ? AppColors.black
        : AppColors.neutral800,
    builder: (context) => _ProductFormDialog(
      product: product,
      onDeletePhoto: (photoIndex) => _showProductDeletePhotoDialog(
        context,
        ref,
        product!,
        photoIndex,
        onToast,
      ),
      onReplacePhoto: (photo) async {
        final replacement = await _pickProductPhoto(
          context,
          ref,
          title: 'Replace product photo',
        );
        if (replacement == null || !context.mounted) return false;
        final result = await ref
            .read(_productsControllerProvider.notifier)
            .replacePhoto(product!, photo, replacement);
        if (!context.mounted) return false;
        final failure = result.failureOrNull;
        if (failure != null) {
          AppSnackBar.showError(context, failure.message);
          return false;
        }
        onToast('Photo replaced');
        return true;
      },
    ),
    footer: Consumer(
      builder: (context, ref, _) {
        final form = ref.watch(_productFormProvider(product));
        return AppDialogActionFooter(
          primaryButtonKey: const ValueKey('submit-product-form'),
          primaryLabel: product == null ? 'Add Product' : 'Update Product',
          primaryIcon: Icons.check,
          primaryDisabled: !form.isValid,
          isLoading: form.isSubmitting,
          onCancel: () => Navigator.pop(context),
          onPrimary: () async {
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
          },
        );
      },
    ),
  );
}

Future<void> _showProductDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  _Product product,
  ValueChanged<String> onToast,
) {
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
  int photoIndex,
  ValueChanged<String> onToast,
) async {
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

    footer: AppDialogActionFooter(
      primaryLabel: 'Delete Photo',
      primaryIcon: Icons.photo_camera_outlined,
      danger: true,
      onCancel: () => Navigator.pop(context, false),
      onPrimary: () async {
        final result = await ref
            .read(_productsControllerProvider.notifier)
            .deletePhoto(product, photoIndex);
        if (!context.mounted) return;
        final failure = result.failureOrNull;
        if (failure != null) {
          AppSnackBar.showError(context, failure.message);
          return;
        }
        Navigator.pop(context, true);
        onToast('Photo deleted');
      },
    ),
  );
  return deleted ?? false;
}
