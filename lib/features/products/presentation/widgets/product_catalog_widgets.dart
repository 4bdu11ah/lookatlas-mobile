part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductEmptyResults extends StatelessWidget {
  const _ProductEmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha68,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 28, color: AppColors.neutral500),
          const SizedBox(height: 10),
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            query.trim().isEmpty
                ? 'Try a different filter combination.'
                : 'No product matches "$query".',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductLoadFailure extends StatelessWidget {
  const _ProductLoadFailure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Try again',
            onPressed: onRetry,
            fitToContent: true,
            backgroundColor: AppColors.black,
            foregroundColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}

class _ProductPhotoIndexController extends Notifier<int> {
  _ProductPhotoIndexController(this.productSku);

  final String productSku;

  @override
  int build() => 0;

  int get _value => state;
  set _value(int value) {
    if (_value == value) return;
    state = value;
  }
}

// Riverpod does not expose a stable public family type for this provider.
// ignore: specify_nonobvious_property_types
final _productPhotoIndexProvider = NotifierProvider.autoDispose
    .family<_ProductPhotoIndexController, int, String>(
      _ProductPhotoIndexController.new,
    );

// Riverpod does not expose a stable public family type for this provider.
// ignore: specify_nonobvious_property_types
final _productPhotoPageControllerProvider = Provider.autoDispose
    .family<PageController, String>((ref, _) {
      final controller = PageController();
      ref.onDispose(controller.dispose);
      return controller;
    });

class _ProductCard extends ConsumerWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onReplacePhoto,
    required this.onCalibrate,
    super.key,
  });

  final _Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int> onReplacePhoto;
  final VoidCallback onCalibrate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = this.product;
    final photoIndex = ref.watch(_productPhotoIndexProvider(product.sku));
    final pageController = ref.watch(
      _productPhotoPageControllerProvider(product.sku),
    );
    final photoAssets = product.photoAssets.isEmpty
        ? const ['']
        : product.photoAssets;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${product.photos} photos',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          key: ValueKey('calibrate-product-${product.sku}'),
                          onTap: onCalibrate,
                          child: _ProductPill.neutral(
                            product.status,
                            icon: Icons.straighten,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _ProductMiniIcon(
                key: ValueKey('edit-product-${product.sku}'),
                icon: Icons.edit_outlined,
                onTap: onEdit,
              ),
              _ProductMiniIcon(
                key: ValueKey('delete-product-${product.sku}'),
                icon: Icons.delete_outline,
                onTap: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: ValueKey('replace-product-photo-${product.sku}'),
            onTap: () => onReplacePhoto(photoIndex),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: PageView.builder(
                  key: ValueKey('product-${product.sku}-photo-pager'),
                  controller: pageController,
                  itemCount: photoAssets.length,
                  onPageChanged: (index) =>
                      ref
                              .read(
                                _productPhotoIndexProvider(
                                  product.sku,
                                ).notifier,
                              )
                              ._value =
                          index,
                  itemBuilder: (context, index) {
                    return _AssetImage(photoAssets[index]);
                  },
                ),
              ),
            ),
          ),
          if (photoAssets.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < photoAssets.length; index++)
                  _ProductDot(
                    key: ValueKey(
                      'product-${product.sku}-photo-dot-$index'
                      '${photoIndex == index ? '-active' : ''}',
                    ),
                    active: photoIndex == index,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                size: 12,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 4),
              Text(
                product.addedLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductPill extends StatelessWidget {
  const _ProductPill._({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.textColor,
    this.icon,
  });

  // const _ProductPill.status(String status)
  //   : this._(
  //       label: status,
  //       color: status == 'Calibrated'
  //           ? AppColors.successLight
  //           : AppColors.warningLight,
  //       borderColor: status == 'Calibrated'
  //           ? AppColors.successBorder
  //           : AppColors.warningBorder,
  //       textColor: status == 'Calibrated'
  //           ? AppColors.successDarker
  //           : AppColors.warningDark,
  //     );

  const _ProductPill.dark(String label, {IconData? icon})
    : this._(
        label: label,
        color: AppColors.black,
        borderColor: AppColors.black,
        textColor: AppColors.white,
        icon: icon,
      );

  const _ProductPill.neutral(String label, {IconData? icon})
    : this._(
        label: label,
        color: AppColors.white,
        borderColor: AppColors.neutral200,
        textColor: AppColors.neutral800,
        icon: icon,
      );

  final String label;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      widthFactor: 1,
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Transform.rotate(
                angle: -0.785398,
                child: Icon(
                  icon,
                  size: 10,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                height: 1,
                fontWeight: AppTypography.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductMiniIcon extends StatelessWidget {
  const _ProductMiniIcon({required this.icon, required this.onTap, super.key});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox.square(
        dimension: 32,
        child: Icon(icon, size: 16, color: AppColors.neutral500),
      ),
    );
  }
}

class _ProductDot extends StatelessWidget {
  const _ProductDot({this.active = false, super.key});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 20 : 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: active ? AppColors.black : AppColors.neutral200,
    );
  }
}

Future<ProductUpload?> _pickProductPhoto(
  BuildContext context,
  WidgetRef ref, {
  required String title,
}) async {
  final photos = await _pickProductPhotos(
    context,
    ref,
    remaining: 1,
    title: title,
  );
  return photos.firstOrNull;
}

Future<List<ProductUpload>> _pickProductPhotos(
  BuildContext context,
  WidgetRef ref, {
  required int remaining,
  required String title,
}) async {
  if (remaining <= 0) {
    AppSnackBar.show(context, 'You can upload up to 10 photos.');
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
    final uploads = <ProductUpload>[];
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 30 * 1024 * 1024) {
        if (context.mounted) {
          AppSnackBar.showError(context, '${file.name} is larger than 30MB.');
        }
        continue;
      }
      uploads.add(
        ProductUpload(bytes: bytes, fileName: file.name, path: file.path),
      );
    }
    return uploads;
  } on Exception {
    if (context.mounted) {
      AppSnackBar.showError(
        context,
        'Could not open your camera or photo library.',
      );
    }
    return const [];
  }
}
