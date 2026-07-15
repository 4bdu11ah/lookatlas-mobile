part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductsFeatureScaffold extends ConsumerWidget {
  const _ProductsFeatureScaffold({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Products', showBackButton: true),
      floatingActionButton: _ProductFab(
        onTap: () => _showProductFormDialog(context, onToast),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ColoredBox(
              color: AppColors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 96),
                child: _ProductsPage(onToast: onToast),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsPage extends ConsumerWidget {
  const _ProductsPage({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_productsControllerProvider);
    final filteredProducts = state.filteredProducts;
    final visibleProducts = filteredProducts.take(2).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ProductPageIntro(),
        _ProductCategoryBanner(
          onSetCategories: () => _openCalibration(context, state.products[1]),
          onDismiss: () => _showProductPaywallDialog(context),
        ),
        _ProductFilterBar(
          query: state.searchQuery,
          categoryFilter: state.categoryFilter,
          statusFilter: state.statusFilter,
          sortOrder: state.sortOrder,
          visibleCount: visibleProducts.length,
          totalCount: state.products.length,
          calibratedCount: state.filteredCalibratedCount,
        ),
        const SizedBox(height: 14),
        if (visibleProducts.isEmpty)
          _ProductEmptyResults(query: state.searchQuery)
        else
          for (final product in visibleProducts) ...[
            _ProductCard(
              key: ValueKey('product-card-${product.sku}'),
              product: product,
              onEdit: () => _showProductFormDialog(
                context,
                onToast,
                product: product,
              ),
              onDelete: () =>
                  _showProductDeleteDialog(context, product, onToast),
              onCrop: () => _openCropScreen(context, product),
              onCalibrate: () => _openCalibration(context, product),
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _ProductPageIntro extends StatelessWidget {
  const _ProductPageIntro();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Products',
            style: TextStyle(
              fontSize: 28,
              height: 1.04,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Manage your product catalog for AI-generated photoshoots',
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCategoryBanner extends StatelessWidget {
  const _ProductCategoryBanner({
    required this.onSetCategories,
    required this.onDismiss,
  });

  final VoidCallback onSetCategories;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha68,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Tag your products by category',
                  style: TextStyle(fontWeight: AppTypography.bold),
                ),
                TextSpan(text: ' to unlock proportion calibration. '),
                TextSpan(
                  text: '3 products without a category.',
                  style: TextStyle(color: AppColors.neutral500),
                ),
              ],
            ),
            style: TextStyle(fontSize: 13, height: 1.38),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              PrimaryButton(
                label: 'Set categories',
                onPressed: onSetCategories,
                fitToContent: true,
                height: 34,
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(width: 8),
              AppOutlinedButton(
                label: 'Dismiss',
                onPressed: onDismiss,
                fitToContent: true,
                height: 34,
                borderColor: AppColors.transparent,
                backgroundColor: AppColors.transparent,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductFilterBar extends ConsumerWidget {
  const _ProductFilterBar({
    required this.query,
    required this.categoryFilter,
    required this.statusFilter,
    required this.sortOrder,
    required this.visibleCount,
    required this.totalCount,
    required this.calibratedCount,
  });

  final String query;
  final _ProductCategoryFilter categoryFilter;
  final _ProductStatusFilter statusFilter;
  final _ProductSortOrder sortOrder;
  final int visibleCount;
  final int totalCount;
  final int calibratedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductSearchField(query: query),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ProductFilterDropdown<_ProductCategoryFilter>(
                key: const ValueKey('product-category-filter'),
                value: categoryFilter,
                values: _ProductCategoryFilter.values,
                labelFor: (value) => value.label,
                onChanged: ref
                    .read(_productsControllerProvider.notifier)
                    .updateCategoryFilter,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ProductFilterDropdown<_ProductStatusFilter>(
                key: const ValueKey('product-status-filter'),
                value: statusFilter,
                values: _ProductStatusFilter.values,
                labelFor: (value) => value.label,
                onChanged: ref
                    .read(_productsControllerProvider.notifier)
                    .updateStatusFilter,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ProductFilterDropdown<_ProductSortOrder>(
                key: const ValueKey('product-sort-filter'),
                value: sortOrder,
                values: _ProductSortOrder.values,
                labelFor: (value) => value.label,
                onChanged: ref
                    .read(_productsControllerProvider.notifier)
                    .updateSortOrder,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppOutlinedButton(
                label: 'Clear filters',
                onPressed: () => ref
                    .read(_productsControllerProvider.notifier)
                    .clearFilters(),
                height: 46,
                borderColor: AppColors.transparent,
                backgroundColor: AppColors.transparent,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$totalCount products - '),
              TextSpan(
                text: '$calibratedCount',
                style: const TextStyle(
                  color: AppColors.successDarker,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const TextSpan(text: ' calibrated'),
            ],
          ),
          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
      ],
    );
  }
}

class _ProductFilterDropdown<T> extends StatelessWidget {
  const _ProductFilterDropdown({
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    super.key,
  });

  static const _config = AppDropdownConfig(
    height: 40,
    horizontalPadding: 10,
  );

  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<T>(
      value: value,
      values: values,
      labelFor: labelFor,
      onChanged: onChanged,
      config: _config,
    );
  }
}

class _ProductSearchField extends ConsumerStatefulWidget {
  const _ProductSearchField({required this.query});

  final String query;

  @override
  ConsumerState<_ProductSearchField> createState() =>
      _ProductSearchFieldState();
}

class _ProductSearchFieldState extends ConsumerState<_ProductSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _ProductSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: const ValueKey('product-search-field'),
      controller: _controller,
      height: 40,
      hintText: 'Search by name, sku, or description',
      textInputAction: TextInputAction.search,
      onChanged: ref
          .read(_productsControllerProvider.notifier)
          .updateSearchQuery,
      leading: const Icon(Icons.search, size: 16, color: AppColors.neutral500),
      trailing: widget.query.isEmpty
          ? const SizedBox(width: 11)
          : InkWell(
              key: const ValueKey('clear-product-search'),
              onTap: ref.read(_productsControllerProvider.notifier).clearSearch,
              child: const SizedBox(
                width: 38,
                height: 40,
                child: Icon(Icons.close, size: 16, color: AppColors.black),
              ),
            ),
    );
  }
}

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

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onCrop,
    required this.onCalibrate,
    super.key,
  });

  final _Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCrop;
  final VoidCallback onCalibrate;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  late final PageController _pageController;
  var _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.sku == widget.product.sku) return;
    _photoIndex = 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final photoAssets = product.photoAssets;
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
                        fontSize: 15,
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
                          onTap: widget.onCalibrate,
                          child: _ProductPill.status(product.status),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _ProductMiniIcon(
                key: ValueKey('edit-product-${product.sku}'),
                icon: Icons.edit_outlined,
                onTap: widget.onEdit,
              ),
              _ProductMiniIcon(
                key: ValueKey('delete-product-${product.sku}'),
                icon: Icons.delete_outline,
                onTap: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: ValueKey('crop-product-${product.sku}'),
            onTap: widget.onCrop,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: PageView.builder(
                  key: ValueKey('product-${product.sku}-photo-pager'),
                  controller: _pageController,
                  itemCount: photoAssets.length,
                  onPageChanged: (index) {
                    setState(() => _photoIndex = index);
                  },
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
                      '${_photoIndex == index ? '-active' : ''}',
                    ),
                    active: _photoIndex == index,
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
  });

  const _ProductPill.status(String status)
    : this._(
        label: status,
        color: status == 'Calibrated'
            ? AppColors.successLight
            : AppColors.warningLight,
        borderColor: status == 'Calibrated'
            ? AppColors.successBorder
            : AppColors.warningBorder,
        textColor: status == 'Calibrated'
            ? AppColors.successDarker
            : AppColors.warningDark,
      );

  const _ProductPill.dark(String label)
    : this._(
        label: label,
        color: AppColors.black,
        borderColor: AppColors.black,
        textColor: AppColors.white,
      );

  const _ProductPill.neutral(String label)
    : this._(
        label: label,
        color: AppColors.neutral100,
        borderColor: AppColors.neutral200,
        textColor: AppColors.neutral800,
      );

  final String label;
  final Color color;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          height: 1,
          fontWeight: AppTypography.bold,
          color: textColor,
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

class _ProductFab extends StatelessWidget {
  const _ProductFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black,
      elevation: 10,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: AppColors.white),
              SizedBox(width: 8),
              Text(
                'Add Product',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: AppTypography.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showProductFormDialog(
  BuildContext context,
  ValueChanged<String> onToast, {
  _Product? product,
}) {
  return showAppDialog<void>(
    context: context,
    builder: (context) => _ProductFormDialog(
      product: product,
      onSubmit: () {
        Navigator.pop(context);
        onToast(product == null ? 'Product added' : 'Product updated');
      },
      onDeletePhoto: () => _showProductDeletePhotoDialog(context, onToast),
    ),
  );
}

Future<void> _showProductDeleteDialog(
  BuildContext context,
  _Product product,
  ValueChanged<String> onToast,
) {
  return showAppDialog<void>(
    context: context,
    config: AppDialogConfig.standard.copyWith(maxHeightOffset: 80),
    builder: (context) => _ProductConfirmDialog(
      icon: Icons.delete_outline,
      title: 'Delete Product',
      subtitle: 'This action cannot be undone',
      body:
          'Are you sure you want to permanently delete this product? All associated photos and data will be removed from the system.',
      actionLabel: 'Delete Product',
      onConfirm: () {
        Navigator.pop(context);
        onToast('${product.name} deleted');
      },
    ),
  );
}

Future<void> _showProductDeletePhotoDialog(
  BuildContext context,
  ValueChanged<String> onToast,
) {
  return showAppDialog<void>(
    context: context,
    config: AppDialogConfig.standard.copyWith(maxHeightOffset: 80),
    builder: (context) => _ProductConfirmDialog(
      icon: Icons.photo_camera_outlined,
      title: 'Delete Photo',
      subtitle: 'This action cannot be undone',
      body:
          'Are you sure you want to permanently delete this photo from the product? This action cannot be undone.',
      actionLabel: 'Delete Photo',
      onConfirm: () {
        Navigator.pop(context);
        onToast('Photo deleted');
      },
    ),
  );
}

Future<void> _showProductPaywallDialog(BuildContext context) {
  return showAppDialog<void>(
    context: context,
    config: AppDialogConfig.standard.copyWith(maxHeightOffset: 80),
    builder: (context) => const _ProductPaywallDialog(),
  );
}

class _ProductDialogHeader extends StatelessWidget {
  const _ProductDialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            color: danger ? AppColors.dangerDark : AppColors.black,
            child: Icon(icon, size: 26, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: danger ? 16 : 22,
                    height: 1.06,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          _ProductMiniIcon(
            icon: Icons.close,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({
    required this.onSubmit,
    required this.onDeletePhoto,
    this.product,
  });

  final _Product? product;
  final VoidCallback onSubmit;
  final VoidCallback onDeletePhoto;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _descriptionController;
  String _category = 'Tops';
  String _subtype = 'Crossbody';
  int _photoCount = 0;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(
      text: product?.name ?? 'Classic Cotton T-Shirt',
    );
    _skuController = TextEditingController(text: product?.sku ?? 'TSH-001');
    _descriptionController = TextEditingController(
      text: product == null
          ? 'Heavyweight cotton tee with ribbed crew neck and relaxed fit.'
          : '',
    );
    _category = product?.category ?? 'Tops';
    _subtype = product?.subtype ?? 'Crossbody';
    _photoCount = product == null ? 0 : product.photos.clamp(0, 5);
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
    final categoryNeedsSubtype = _category == 'Bags';
    return Column(
      children: [
        _ProductDialogHeader(
          icon: _editing ? Icons.edit_outlined : Icons.inventory_2_outlined,
          title: _editing ? 'Edit Product' : 'Add New Product',
          subtitle: _editing
              ? 'Update photos and details for ${widget.product!.name}'
              : 'Upload photos and details for your product',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductField(
                  label: 'Product Name',
                  required: true,
                  child: AppTextField(controller: _nameController),
                ),
                _ProductField(
                  label: 'SKU',
                  required: !_editing,
                  note: _editing ? 'cannot be changed' : null,
                  child: AppTextField(controller: _skuController),
                ),
                _ProductField(
                  label: 'Category',
                  required: true,
                  helper:
                      'Proportions matter for this category. Calibrate after saving for sharper results.',
                  child: AppDropdown<String>(
                    value: _category,
                    values: const ['Tops', 'Bags', 'Jewelry', 'Dresses'],
                    labelFor: (value) => value,
                    onChanged: (value) => setState(() => _category = value),
                  ),
                ),
                if (categoryNeedsSubtype)
                  _ProductField(
                    label: 'Sub-type',
                    note: 'helps the AI place the product correctly',
                    child: _SubtypeRow(
                      value: _subtype,
                      onChanged: (value) => setState(() => _subtype = value),
                    ),
                  ),
                if (_editing)
                  const _ProductIdCard()
                else
                  _ProductField(
                    label: 'Description',
                    note: 'optional',
                    child: AppTextField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 5,
                    ),
                  ),
                if (_photoCount == 0)
                  _ProductField(
                    label: 'Product Photos',
                    required: true,
                    trailing: '0/5',
                    child: _ProductUploadBox(
                      label: 'Click to upload photos',
                      copy: 'or drag and drop\nPNG, JPG up to 10MB each',
                      onTap: () => setState(() {
                        _category = 'Bags';
                        _photoCount = 3;
                      }),
                    ),
                  )
                else ...[
                  _PhotoStrip(
                    title: _editing ? 'Current Photos' : '3 photos selected',
                    countLabel: _editing ? '3 existing' : null,
                    clearLabel: _editing ? null : 'Clear all',
                    product: widget.product ?? _products[1],
                    onDeletePhoto: widget.onDeletePhoto,
                  ),
                  if (_editing)
                    _ProductField(
                      label: 'Add New Photos',
                      trailing: '4/5 total',
                      child: _ProductUploadBox(
                        label: 'Click to add more photos',
                        copy: 'PNG, JPG up to 10MB each',
                        compact: true,
                        onTap: () {},
                      ),
                    ),
                ],
                if (!_editing && _photoCount == 0)
                  const _ProductTip(
                    title: 'Pro Tip',
                    copy:
                        'Upload 3-5 photos showing different angles for best AI results.',
                  ),
              ],
            ),
          ),
        ),
        _ProductDialogFooter(
          primaryLabel: _editing ? 'Update Product' : 'Add Product',
          primaryIcon: Icons.check,
          primaryDisabled: !_editing && _photoCount == 0,
          onCancel: () => Navigator.pop(context),
          onPrimary: widget.onSubmit,
        ),
      ],
    );
  }
}

class _ProductField extends StatelessWidget {
  const _ProductField({
    required this.label,
    required this.child,
    this.required = false,
    this.note,
    this.helper,
    this.trailing,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? note;
  final String? helper;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: label),
                      if (required)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      if (note != null)
                        TextSpan(
                          text: ' ($note)',
                          style: const TextStyle(
                            color: AppColors.neutral500,
                            fontWeight: AppTypography.medium,
                            textBaseline: TextBaseline.alphabetic,
                          ),
                        ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (helper != null) ...[
            const SizedBox(height: 5),
            Text(
              helper!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubtypeRow extends StatelessWidget {
  const _SubtypeRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = ['Tote', 'Crossbody', 'Clutch', 'Backpack'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in values)
          InkWell(
            onTap: () => onChanged(item),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item == value ? AppColors.black : AppColors.white,
                border: Border.all(
                  color: item == value ? AppColors.black : AppColors.neutral200,
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.semiBold,
                  color: item == value ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductUploadBox extends StatelessWidget {
  const _ProductUploadBox({
    required this.label,
    required this.copy,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final String copy;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AppDottedBorder(
        color: AppColors.neutral200,
        strokeWidth: 2,
        dotWidth: 8,
        gap: 6,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 118 : 148),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 48 : 54,
                  height: compact ? 48 : 54,
                  color: AppColors.black,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.upload,
                    size: 24,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.title,
    required this.product,
    required this.onDeletePhoto,
    this.countLabel,
    this.clearLabel,
  });

  final String title;
  final String? countLabel;
  final String? clearLabel;
  final _Product product;
  final VoidCallback onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha68,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (countLabel != null)
                Text(
                  countLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
              if (clearLabel != null)
                Text(
                  clearLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.neutral500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 182,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _ProductThumb(
                  product: product,
                  index: index + 1,
                  onDelete: index == 0 ? onDeletePhoto : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({
    required this.product,
    required this.index,
    this.onDelete,
  });

  final _Product product;
  final int index;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final label = switch (index) {
      1 => 'Front',
      2 => 'Side',
      _ => 'Custom...',
    };
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: _AssetImage(
                    index == 2 ? '$_img/showcase-bag-after.jpg' : product.asset,
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: _ThumbAction(icon: Icons.edit_outlined, onTap: () {}),
                ),
                if (onDelete != null)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: _ThumbAction(icon: Icons.close, onTap: onDelete!),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 25,
                    color: index == 3
                        ? AppColors.successDarker
                        : AppColors.blackAlpha90,
                    alignment: Alignment.center,
                    child: Text(
                      index == 3 ? 'New' : '$index',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: AppTypography.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _MiniSelect(label),
        ],
      ),
    );
  }
}

class _ThumbAction extends StatelessWidget {
  const _ThumbAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        color: AppColors.blackAlpha90,
        child: Icon(icon, size: 14, color: AppColors.white),
      ),
    );
  }
}

class _MiniSelect extends StatelessWidget {
  const _MiniSelect(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 13,
            color: AppColors.neutral500,
          ),
        ],
      ),
    );
  }
}

class _ProductIdCard extends StatelessWidget {
  const _ProductIdCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(left: BorderSide(color: AppColors.black, width: 4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product ID',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 4),
          Text(
            'prod_82BAG391',
            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}

class _ProductTip extends StatelessWidget {
  const _ProductTip({required this.title, required this.copy});

  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(left: BorderSide(color: AppColors.black, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            copy,
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

class _ProductDialogFooter extends StatelessWidget {
  const _ProductDialogFooter({
    required this.primaryLabel,
    required this.onCancel,
    required this.onPrimary,
    this.primaryIcon,
    this.primaryDisabled = false,
    this.danger = false,
  });

  final String primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback onCancel;
  final VoidCallback onPrimary;
  final bool primaryDisabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Column(
        children: [
          AppOutlinedButton(
            label: 'Cancel',
            onPressed: onCancel,
            borderColor: AppColors.black,
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: primaryDisabled ? 0.48 : 1,
            child: PrimaryButton(
              label: primaryLabel,
              icon: primaryIcon,
              onPressed: primaryDisabled ? () {} : onPrimary,
              backgroundColor: danger ? AppColors.dangerDark : AppColors.black,
              foregroundColor: AppColors.white,
              iconSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductConfirmDialog extends StatelessWidget {
  const _ProductConfirmDialog({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.actionLabel,
    required this.onConfirm,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final String actionLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProductDialogHeader(
          icon: icon,
          title: title,
          subtitle: subtitle,
          danger: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.55),
          ),
        ),
        _ProductDialogFooter(
          primaryLabel: actionLabel,
          primaryIcon: Icons.delete_outline,
          danger: true,
          onCancel: () => Navigator.pop(context),
          onPrimary: onConfirm,
        ),
      ],
    );
  }
}

class _ProductPaywallDialog extends StatelessWidget {
  const _ProductPaywallDialog();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  color: AppColors.black,
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppColors.white,
                    size: 26,
                  ),
                ),
                const Spacer(),
                _ProductMiniIcon(
                  icon: Icons.close,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Add products. Keep shooting.',
              style: TextStyle(
                fontSize: 24,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              r'Upload your catalog and run a shoot whenever you are ready. Starter is $49/mo for 80 photos, Pro is $99/mo for 200 photos plus AI video.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: 14),
            const _ProductBullet('Up to 200 photos a month on Pro'),
            const _ProductBullet('AI video on Pro and Business'),
            const _ProductBullet('Cancel anytime, one tap'),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'View plans',
              onPressed: () => Navigator.pop(context),
              height: 46,
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductBullet extends StatelessWidget {
  const _ProductBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.black),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

void _openCropScreen(BuildContext context, _Product product) {
  unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ProductCropScreen(product: product),
      ),
    ),
  );
}

void _openCalibration(BuildContext context, _Product product) {
  unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ProductCalibrationScreen(product: product),
      ),
    ),
  );
}

class _ProductCropScreen extends StatelessWidget {
  const _ProductCropScreen({required this.product});

  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ProductFlowHeader(
              title: 'Crop photo',
              subtitle:
                  'Drag the corners or edges to crop. Click inside the crop area and drag to move it.',
              action: AppOutlinedButton(
                label: 'Reset',
                icon: Icons.refresh,
                onPressed: () {},
                fitToContent: true,
                height: 34,
                borderColor: AppColors.transparent,
                backgroundColor: AppColors.transparent,
                iconSize: 16,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.black,
                padding: const EdgeInsets.all(18),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 284,
                      height: 420,
                      child: Opacity(
                        opacity: 0.84,
                        child: _AssetImage(product.asset),
                      ),
                    ),
                    Container(
                      width: 216,
                      height: 318,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: CustomPaint(painter: _CropGridPainter()),
                    ),
                  ],
                ),
              ),
            ),
            _ProductFlowFooter(
              primaryLabel: 'Save crop',
              onBack: () => Navigator.pop(context),
              onPrimary: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCalibrationScreen extends StatefulWidget {
  const _ProductCalibrationScreen({required this.product});

  final _Product product;

  @override
  State<_ProductCalibrationScreen> createState() =>
      _ProductCalibrationScreenState();
}

class _ProductCalibrationScreenState extends State<_ProductCalibrationScreen> {
  _CalibrationStep _step = _CalibrationStep.method;
  final TextEditingController _notesController = TextEditingController(
    text: 'Medium crossbody, 28 cm wide, canvas strap worn across chest.',
  );
  final TextEditingController _searchController = TextEditingController(
    text: 'bag',
  );

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _go(_CalibrationStep step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    final content = switch (_step) {
      _CalibrationStep.method => _CalibrationMethodStep(
        onBody: () => _go(_CalibrationStep.bodyView),
        onWorn: () => _go(_CalibrationStep.wornPhoto),
        onCopy: () => _go(_CalibrationStep.copyFrom),
      ),
      _CalibrationStep.bodyView => _CalibrationBodyStep(
        onBack: () => _go(_CalibrationStep.method),
        onNext: () => _go(_CalibrationStep.pickPhoto),
      ),
      _CalibrationStep.pickPhoto => _CalibrationPickPhotoStep(
        product: widget.product,
        onBack: () => _go(_CalibrationStep.bodyView),
        onNext: () => _go(_CalibrationStep.removingBackground),
      ),
      _CalibrationStep.removingBackground => _CalibrationProgressStep(
        onBack: () => _go(_CalibrationStep.pickPhoto),
        onNext: () => _go(_CalibrationStep.confirmCutout),
      ),
      _CalibrationStep.confirmCutout => _CalibrationConfirmCutoutStep(
        product: widget.product,
        onBack: () => _go(_CalibrationStep.pickPhoto),
        onNext: () => _go(_CalibrationStep.placeProduct),
      ),
      _CalibrationStep.placeProduct => _CalibrationPlaceStep(
        product: widget.product,
        onBack: () => _go(_CalibrationStep.confirmCutout),
        onNext: () => _go(_CalibrationStep.review),
      ),
      _CalibrationStep.review => _CalibrationReviewStep(
        product: widget.product,
        notesController: _notesController,
        onBack: () => _go(_CalibrationStep.placeProduct),
      ),
      _CalibrationStep.wornPhoto => _CalibrationWornStep(
        onBack: () => _go(_CalibrationStep.method),
      ),
      _CalibrationStep.copyFrom => _CalibrationCopyStep(
        searchController: _searchController,
        onBack: () => _go(_CalibrationStep.method),
      ),
    };
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ProductFlowHeader(
              title: 'Set real-world size',
              subtitle: widget.product.name,
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

enum _CalibrationStep {
  method,
  bodyView,
  pickPhoto,
  removingBackground,
  confirmCutout,
  placeProduct,
  review,
  wornPhoto,
  copyFrom,
}

class _ProductFlowHeader extends StatelessWidget {
  const _ProductFlowHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
          _ProductMiniIcon(
            icon: Icons.close,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.label});

  final String current;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: current,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: AppTypography.bold,
              ),
            ),
            TextSpan(text: ' of $label'),
          ],
        ),
        style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
      ),
    );
  }
}

class _CalibrationMethodStep extends StatelessWidget {
  const _CalibrationMethodStep({
    required this.onBody,
    required this.onWorn,
    required this.onCopy,
  });

  final VoidCallback onBody;
  final VoidCallback onWorn;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'How should we learn the real-world size?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Any of these work. Pick whichever is easiest for this product.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.38,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MethodCard(
                    icon: Icons.open_with,
                    title: 'Place the product on a body outline',
                    subtitle:
                        'Remove the background, then drag the product onto a body outline.',
                    recommended: true,
                    onTap: onBody,
                  ),
                  _MethodCard(
                    icon: Icons.photo_camera_outlined,
                    title: 'Upload a photo of it being worn',
                    subtitle:
                        'Fastest if you already have a rough phone photo.',
                    onTap: onWorn,
                  ),
                  _MethodCard(
                    icon: Icons.copy_outlined,
                    title: 'Copy from another calibrated product',
                    subtitle: 'Reuse a setup from a similar product.',
                    onTap: onCopy,
                  ),
                ],
              ),
            ),
          ),
        ),
        _ProductFlowFooter(
          onBack: () => Navigator.pop(context),
          onPrimary: onBody,
          backLabel: 'Cancel',
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.recommended = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Icon(icon, size: 16),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (recommended) const _ProductPill.dark('Recommended'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalibrationBodyStep extends StatelessWidget {
  const _CalibrationBodyStep({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 1', label: '3: View'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Pick a body view',
                  copy:
                      'We have pre-selected the view that usually fits this category. Tap any other one to change it.',
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.58,
                  children: const [
                    _BodyTile(
                      'Full Body Front',
                      'Clothing, bags, dresses',
                      active: true,
                    ),
                    _BodyTile(
                      'Hand Side',
                      'Rings, bracelets, gloves',
                      active: false,
                    ),
                    _BodyTile(
                      'Full Body Side',
                      'Crossbody, shoulder bags',
                      active: false,
                    ),
                    _BodyTile(
                      'Waist Front',
                      'Belts, waist bags',
                      active: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'None of these fit your product? Pick the closest view, or go back and upload a real worn photo instead.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(onBack: onBack, onPrimary: onNext),
      ],
    );
  }
}

class _BodyTile extends StatelessWidget {
  const _BodyTile(this.title, this.subtitle, {required this.active});

  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: active ? AppColors.neutral100 : AppColors.white,
        border: Border.all(
          color: active ? AppColors.black : AppColors.neutral200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          if (active)
            const Align(
              alignment: Alignment.centerLeft,
              child: _ProductPill.dark('Recommended'),
            ),
          Expanded(child: CustomPaint(painter: _BodyOutlinePainter())),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}

class _CalibrationPickPhotoStep extends StatelessWidget {
  const _CalibrationPickPhotoStep({
    required this.product,
    required this.onBack,
    required this.onNext,
  });

  final _Product product;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 2', label: '3: Place'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Pick a product photo',
                  copy:
                      'We will remove its background in your browser, then you place the cutout on the body outline.',
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 116,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Kicker('Placing on'),
                          const SizedBox(height: 7),
                          AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.neutral200),
                              ),
                              child: CustomPaint(
                                painter: _BodyOutlinePainter(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Full Body Front',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pick a photo that shows the product from roughly this angle.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Kicker('Your product photos'),
                          const SizedBox(height: 8),
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _PhotoTile(asset: product.asset, label: 'Front'),
                              const _PhotoTile(
                                asset: '$_img/showcase-bag-after.jpg',
                                label: 'Side',
                              ),
                              const _UploadTile(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(onBack: onBack, onPrimary: onNext),
      ],
    );
  }
}

class _CalibrationProgressStep extends StatelessWidget {
  const _CalibrationProgressStep({
    required this.onBack,
    required this.onNext,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 2', label: '3: Place'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Removing background',
                  copy:
                      'One-time model download on first use, then it is near-instant.',
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: onNext,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 30,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100Alpha68,
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.black,
                            backgroundColor: AppColors.neutral200,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 240,
                          height: 7,
                          alignment: Alignment.centerLeft,
                          color: AppColors.neutral100,
                          child: const FractionallySizedBox(
                            widthFactor: 0.68,
                            child: ColoredBox(color: AppColors.black),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '68%',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(onBack: onBack, showPrimary: false),
      ],
    );
  }
}

class _CalibrationConfirmCutoutStep extends StatelessWidget {
  const _CalibrationConfirmCutoutStep({
    required this.product,
    required this.onBack,
    required this.onNext,
  });

  final _Product product;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 2', label: '3: Place'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Does this look right?',
                  copy:
                      'Edges do not need to be perfect. This is used as a size reference only.',
                ),
                const SizedBox(height: 14),
                _CheckerBox(asset: product.asset),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PrimaryButton(
                      label: 'Looks good',
                      icon: Icons.check,
                      onPressed: onNext,
                      fitToContent: true,
                      height: 34,
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      iconSize: 16,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    AppOutlinedButton(
                      label: 'Use a different photo',
                      icon: Icons.refresh,
                      onPressed: onBack,
                      fitToContent: true,
                      height: 34,
                      iconSize: 16,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(onBack: onBack, showPrimary: false),
      ],
    );
  }
}

class _CalibrationPlaceStep extends StatelessWidget {
  const _CalibrationPlaceStep({
    required this.product,
    required this.onBack,
    required this.onNext,
  });

  final _Product product;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 2', label: '3: Place'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Set the size on the body',
                  copy:
                      'Drag to reposition, pull a corner to resize. Match the real-world size of the product compared to the body.',
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: _ZoomControl(),
                ),
                const SizedBox(height: 8),
                _PlacementCanvas(product: product),
                const SizedBox(height: 10),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'This sets the '),
                      TextSpan(
                        text: 'size',
                        style: TextStyle(
                          color: AppColors.black,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' of your product compared to the body. Final photo framing is up to the photographer.',
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 8),
                AppOutlinedButton(
                  label: 'Use a different photo',
                  icon: Icons.arrow_back,
                  onPressed: onBack,
                  fitToContent: true,
                  height: 34,
                  borderColor: AppColors.transparent,
                  backgroundColor: AppColors.transparent,
                  iconSize: 16,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(onBack: onBack, onPrimary: onNext),
      ],
    );
  }
}

class _CalibrationReviewStep extends StatelessWidget {
  const _CalibrationReviewStep({
    required this.product,
    required this.notesController,
    required this.onBack,
  });

  final _Product product;
  final TextEditingController notesController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 3', label: '3: Review'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Review and save',
                  copy:
                      'The AI will use this size-on-body setup as the scale reference.',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 300,
                  child: _PlacementCanvas(product: product),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Notes for the AI (optional)',
                  style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: notesController,
                  minLines: 3,
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                AppOutlinedButton(
                  label: 'Adjust placement',
                  onPressed: onBack,
                  fitToContent: true,
                  height: 34,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(
          onBack: onBack,
          primaryLabel: 'Save calibration',
          onPrimary: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _CalibrationWornStep extends StatelessWidget {
  const _CalibrationWornStep({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepIndicator(current: 'Step 1', label: '2: Photo'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Upload a photo of the product being worn',
                  copy:
                      'Any photo of the product on a person will do, even rough phone shots. We only use it to measure size.',
                ),
                const SizedBox(height: 18),
                AppDottedBorder(
                  color: AppColors.neutral200,
                  strokeWidth: 2,
                  dotWidth: 8,
                  gap: 6,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 220),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 26,
                            color: AppColors.neutral500,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Click or drop a photo here',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'JPG, PNG, or WebP up to 10 MB',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Do not have a worn photo? Go back and place the product on a body outline instead.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(onBack: onBack, showPrimary: false),
      ],
    );
  }
}

class _CalibrationCopyStep extends StatelessWidget {
  const _CalibrationCopyStep({
    required this.searchController,
    required this.onBack,
  });

  final TextEditingController searchController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionCopy(
                  title: 'Copy from a calibrated product',
                  copy:
                      'Reuse the size setup from another product. The two calibrations stay independent afterwards.',
                ),
                const SizedBox(height: 14),
                AppTextField(controller: searchController),
                const SizedBox(height: 14),
                const _CopyCard(
                  name: 'Leather Shoulder Bag',
                  meta: 'BAG-004 - bags - crossbody',
                  asset: '$_img/showcase-bag-after.jpg',
                ),
                const _CopyCard(
                  name: 'Studio Tote',
                  meta: 'BAG-009 - bags - tote',
                  asset: '$_img/showcase-dress-after.jpg',
                ),
              ],
            ),
          ),
        ),
        _ProductFlowFooter(onBack: onBack, showPrimary: false),
      ],
    );
  }
}

class _SectionCopy extends StatelessWidget {
  const _SectionCopy({required this.title, required this.copy});

  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          copy,
          style: const TextStyle(
            fontSize: 13,
            height: 1.38,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: AppColors.neutral500,
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.neutral200, width: 2),
          ),
          child: _AssetImage(asset),
        ),
        Positioned(
          left: 5,
          right: 5,
          bottom: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 3),
            color: AppColors.black,
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile();

  @override
  Widget build(BuildContext context) {
    return AppDottedBorder(
      color: AppColors.neutral200,
      strokeWidth: 2,
      dotWidth: 8,
      gap: 6,
      child: Container(
        color: AppColors.neutral100Alpha68,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload, size: 20),
            SizedBox(height: 7),
            Text(
              'Upload another',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: AppTypography.bold),
            ),
            SizedBox(height: 2),
            Text(
              'JPG or PNG',
              style: TextStyle(fontSize: 10, color: AppColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckerBox extends StatelessWidget {
  const _CheckerBox({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 284),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          color: AppColors.neutral50,
        ),
        child: SizedBox(width: 176, height: 210, child: _AssetImage(asset)),
      ),
    );
  }
}

class _ZoomControl extends StatelessWidget {
  const _ZoomControl();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton('-'),
          _ZoomButton('Reset', wide: true),
          _ZoomButton('+'),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton(this.label, {this.wide = false});

  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 58 : 38,
      height: 34,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: AppTypography.bold,
          ),
        ),
      ),
    );
  }
}

class _PlacementCanvas extends StatelessWidget {
  const _PlacementCanvas({required this.product});

  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 410,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            left: 78,
            right: 78,
            top: 8,
            bottom: 8,
            child: Opacity(
              opacity: 0.54,
              child: CustomPaint(painter: _BodyOutlinePainter()),
            ),
          ),
          Positioned(
            left: 122,
            top: 174,
            child: SizedBox(
              width: 118,
              height: 138,
              child: _AssetImage(product.asset),
            ),
          ),
          Positioned(
            left: 116,
            top: 168,
            child: Container(
              width: 130,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.black, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyCard extends StatelessWidget {
  const _CopyCard({
    required this.name,
    required this.meta,
    required this.asset,
  });

  final String name;
  final String meta;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          SizedBox(width: 56, height: 56, child: _AssetImage(asset)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 6),
                const Wrap(
                  spacing: 5,
                  children: [
                    _ProductPill.neutral('Placed on body'),
                    _ProductPill.dark('Same category'),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.copy_outlined, size: 16),
        ],
      ),
    );
  }
}

class _ProductFlowFooter extends StatelessWidget {
  const _ProductFlowFooter({
    required this.onBack,
    this.onPrimary,
    this.backLabel = 'Back',
    this.primaryLabel = 'Next',
    this.showPrimary = true,
  });

  final VoidCallback onBack;
  final VoidCallback? onPrimary;
  final String backLabel;
  final String primaryLabel;
  final bool showPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          AppOutlinedButton(
            label: backLabel,
            onPressed: onBack,
            fitToContent: true,
            height: 34,
            borderColor: AppColors.transparent,
            backgroundColor: AppColors.transparent,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: AppTypography.bold,
            ),
          ),
          const Spacer(),
          if (showPrimary)
            PrimaryButton(
              label: primaryLabel,
              onPressed: onPrimary,
              fitToContent: true,
              height: 34,
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: AppTypography.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _BodyOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neutral400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.width / 2, size.height * 0.18);
    canvas.drawCircle(center, size.shortestSide * 0.11, paint);
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.66)
      ..moveTo(size.width * 0.24, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.32,
        size.width * 0.76,
        size.height * 0.42,
      )
      ..moveTo(size.width * 0.5, size.height * 0.66)
      ..lineTo(size.width * 0.32, size.height * 0.94)
      ..moveTo(size.width * 0.5, size.height * 0.66)
      ..lineTo(size.width * 0.68, size.height * 0.94);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.whiteAlpha65
      ..strokeWidth = 1;
    canvas
      ..drawLine(
        Offset(0, size.height / 3),
        Offset(size.width, size.height / 3),
        paint,
      )
      ..drawLine(
        Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3),
        paint,
      )
      ..drawLine(
        Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height),
        paint,
      )
      ..drawLine(
        Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
