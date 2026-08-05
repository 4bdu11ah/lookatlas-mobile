part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductsFeatureScaffold extends ConsumerWidget {
  const _ProductsFeatureScaffold({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Products', showBackButton: true),
      floatingActionButton: AppFloatingActionButton(
        label: 'Add Product',
        onPressed: () => _showProductFormDialog(context, ref, onToast),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ColoredBox(
              color: AppColors.white,
              child: _ProductsPage(onToast: onToast),
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
    final controller = ref.read(_productsControllerProvider.notifier);
    final uncategorized = state.productsWithoutCategory;
    if (state.isLoading && state.products.isEmpty) {
      return const _ProductsLoadingShimmer();
    }
    if (state.failure != null && state.products.isEmpty) {
      return _ProductLoadFailure(
        message: state.failure!.message,
        onRetry: controller.reload,
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ProductPageIntro(),
                if (uncategorized.isNotEmpty && !state.categoryBannerDismissed)
                  _ProductCategoryBanner(
                    count: uncategorized.length,
                    onSetCategories: () => _showProductFormDialog(
                      context,
                      ref,
                      onToast,
                      product: uncategorized.first,
                    ),
                    onDismiss: controller.dismissCategoryBanner,
                  ),
                _ProductFilterBar(
                  query: state.searchQuery,
                  categoryFilter: state.categoryFilter,
                  statusFilter: state.statusFilter,
                  sortOrder: state.sortOrder,
                  totalCount: state.totalCount,
                  calibratedCount: state.calibratedCount,
                ),
                if (state.isLoading) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.black,
                    backgroundColor: AppColors.neutral200,
                  ),
                ],
                const SizedBox(height: 14),
                if (state.products.isEmpty)
                  _ProductEmptyResults(query: state.searchQuery),
              ],
            ),
          ),
        ),
        if (state.products.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ProductCard(
                    key: ValueKey('product-card-${product.sku}'),
                    product: product,
                    onEdit: () => _showProductFormDialog(
                      context,
                      ref,
                      onToast,
                      product: product,
                    ),
                    onDelete: () => _showProductDeleteDialog(
                      context,
                      ref,
                      product,
                      onToast,
                    ),
                    onReplacePhoto: (photoIndex) => _openReplacePhotoScreen(
                      context,
                      ref,
                      product,
                      photoIndex,
                      onToast,
                    ),
                    onCalibrate: () =>
                        _openCalibration(context, ref, product, onToast),
                  ),
                );
              },
            ),
          ),
        if (state.currentPage < state.totalPages)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: AppOutlinedButton(
                label: state.isLoadingMore ? 'Loading...' : 'Load more',
                onPressed: state.isLoadingMore ? null : controller.loadNextPage,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

class _ProductsLoadingShimmer extends StatelessWidget {
  const _ProductsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey('products-loading-shimmer'),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 96),
      itemCount: 3,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _ProductLoadingShimmerCard(
          key: ValueKey('product-loading-shimmer-card-$index'),
        ),
      ),
    );
  }
}

class _ProductLoadingShimmerCard extends StatelessWidget {
  const _ProductLoadingShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SizedBox(height: 16, child: ShimmerBox())),
              SizedBox(width: 32),
              SizedBox(width: 32),
            ],
          ),
          SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: 0.34,
            child: SizedBox(height: 12, child: ShimmerBox()),
          ),
          SizedBox(height: 12),
          AspectRatio(aspectRatio: 1, child: ShimmerBox()),
          SizedBox(height: 11),
          FractionallySizedBox(
            widthFactor: 0.25,
            child: SizedBox(height: 12, child: ShimmerBox()),
          ),
        ],
      ),
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
    required this.count,
    required this.onSetCategories,
    required this.onDismiss,
  });

  final int count;
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
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Tag your products by category',
                  style: TextStyle(fontWeight: AppTypography.bold),
                ),
                const TextSpan(
                  text: ' to unlock proportion calibration. ',
                ),
                TextSpan(
                  text:
                      '$count ${count == 1 ? 'product' : 'products'} '
                      'without a category.',
                  style: const TextStyle(color: AppColors.neutral500),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 13, height: 1.38),
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
    required this.totalCount,
    required this.calibratedCount,
  });

  final String query;
  final _ProductCategoryFilter categoryFilter;
  final _ProductStatusFilter statusFilter;
  final _ProductSortOrder sortOrder;
  final int totalCount;
  final int calibratedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilterCount = [
      categoryFilter != _ProductCategoryFilter.all,
      statusFilter != _ProductStatusFilter.all,
      sortOrder != _ProductSortOrder.newest,
    ].where((active) => active).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductSearchField(query: query),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text.rich(
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ),
            AppOutlinedButton(
              key: const ValueKey('open-product-filter-sheet'),
              label: activeFilterCount == 0
                  ? 'Filters'
                  : 'Filters ($activeFilterCount)',
              icon: Icons.tune,
              fitToContent: true,
              height: 40,
              onPressed: () => _showProductFilterSheet(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductFilterSheetInitial {
  const _ProductFilterSheetInitial({
    required this.category,
    required this.status,
    required this.sort,
  });

  final _ProductCategoryFilter category;
  final _ProductStatusFilter status;
  final _ProductSortOrder sort;
}

class _ProductFilterSheetState {
  const _ProductFilterSheetState({
    required this.category,
    required this.status,
    required this.sort,
  });

  final _ProductCategoryFilter category;
  final _ProductStatusFilter status;
  final _ProductSortOrder sort;

  _ProductFilterSheetState copyWith({
    _ProductCategoryFilter? category,
    _ProductStatusFilter? status,
    _ProductSortOrder? sort,
  }) => _ProductFilterSheetState(
    category: category ?? this.category,
    status: status ?? this.status,
    sort: sort ?? this.sort,
  );
}

class _ProductFilterSheetController extends Notifier<_ProductFilterSheetState> {
  _ProductFilterSheetController(this.initial);

  final _ProductFilterSheetInitial initial;

  @override
  _ProductFilterSheetState build() => _ProductFilterSheetState(
    category: initial.category,
    status: initial.status,
    sort: initial.sort,
  );

  void setCategory(_ProductCategoryFilter value) =>
      state = state.copyWith(category: value);
  void setStatus(_ProductStatusFilter value) =>
      state = state.copyWith(status: value);
  void setSort(_ProductSortOrder value) => state = state.copyWith(sort: value);
}

// Riverpod's family provider type is inferred from the factory.
// ignore: specify_nonobvious_property_types
final _productFilterSheetProvider = NotifierProvider.autoDispose
    .family<
      _ProductFilterSheetController,
      _ProductFilterSheetState,
      _ProductFilterSheetInitial
    >(_ProductFilterSheetController.new);

Future<void> _showProductFilterSheet(BuildContext context, WidgetRef ref) {
  final state = ref.read(_productsControllerProvider);
  final initial = _ProductFilterSheetInitial(
    category: state.categoryFilter,
    status: state.statusFilter,
    sort: state.sortOrder,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _ProductFilterSheet(initial: initial),
  );
}

class _ProductFilterSheet extends ConsumerWidget {
  const _ProductFilterSheet({required this.initial});

  final _ProductFilterSheetInitial initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_productFilterSheetProvider(initial));
    final controller = ref.read(_productFilterSheetProvider(initial).notifier);
    return _SheetFrame(
      title: 'Filter products',
      actions: [
        AppOutlinedButton(
          label: 'Clear',

          onPressed: () {
            ref.read(_productsControllerProvider.notifier).clearFilters();
            Navigator.pop(context);
          },
        ),
        PrimaryButton(
          label: 'Show products',
          onPressed: () {
            ref
                .read(_productsControllerProvider.notifier)
                .applyFilters(
                  category: state.category,
                  status: state.status,
                  sort: state.sort,
                );
            Navigator.pop(context);
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductFilterDropdown<_ProductCategoryFilter>(
            key: const ValueKey('product-category-filter'),
            label: 'Category',
            value: state.category,
            values: _ProductCategoryFilter.values,
            labelFor: (value) => value.label,
            onChanged: controller.setCategory,
          ),
          const SizedBox(height: 20),
          _ProductFilterDropdown<_ProductStatusFilter>(
            key: const ValueKey('product-status-filter'),
            label: 'Calibration',
            value: state.status,
            values: _ProductStatusFilter.values,
            labelFor: (value) => value.label,
            onChanged: controller.setStatus,
          ),
          const SizedBox(height: 20),
          _ProductFilterDropdown<_ProductSortOrder>(
            key: const ValueKey('product-sort-filter'),
            label: 'Sort by',
            value: state.sort,
            values: _ProductSortOrder.values,
            labelFor: (value) => value.label,
            onChanged: controller.setSort,
          ),
        ],
      ),
    );
  }
}

class _ProductFilterDropdown<T> extends StatelessWidget {
  const _ProductFilterDropdown({
    required this.label,
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

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: AppTypography.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        AppDropdown<T>(
          value: value,
          values: values,
          labelFor: labelFor,
          onChanged: onChanged,
          config: _config,
        ),
      ],
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

class _ProductCard extends StatefulWidget {
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
            key: ValueKey('replace-product-photo-${product.sku}'),
            onTap: () => widget.onReplacePhoto(_photoIndex),
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
    final uploads = <ProductUpload>[];
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        if (context.mounted) {
          AppSnackBar.showError(context, '${file.name} is larger than 10MB.');
        }
        continue;
      }
      uploads.add(ProductUpload(bytes: bytes, fileName: file.name));
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

class _ProductFormState {
  const _ProductFormState({
    this.productId,
    this.name = '',
    this.sku = '',
    this.description = '',
    this.category = 'Tops',
    this.subtype = 'Crossbody',
    this.existingPhotos = const [],
    this.newPhotos = const [],
    this.removedPhotoIndexes = const {},
    this.angles = const {},
    this.newAngles = const {},
    this.isSubmitting = false,
  });

  final String? productId;
  final String name;
  final String sku;
  final String description;
  final String category;
  final String subtype;
  final List<ProductPhoto> existingPhotos;
  final List<ProductUpload> newPhotos;
  final Set<int> removedPhotoIndexes;
  final Map<int, String?> angles;
  final Map<int, String?> newAngles;
  final bool isSubmitting;

  List<(int, ProductPhoto)> get visibleExistingPhotos => [
    for (final (index, photo) in existingPhotos.indexed)
      if (!removedPhotoIndexes.contains(index)) (index, photo),
  ];
  int get photoCount => visibleExistingPhotos.length + newPhotos.length;
  bool get isValid =>
      name.trim().isNotEmpty && sku.trim().isNotEmpty && photoCount > 0;

  _ProductFormState copyWith({
    String? name,
    String? sku,
    String? description,
    String? category,
    String? subtype,
    List<ProductPhoto>? existingPhotos,
    List<ProductUpload>? newPhotos,
    Set<int>? removedPhotoIndexes,
    Map<int, String?>? angles,
    Map<int, String?>? newAngles,
    bool? isSubmitting,
  }) => _ProductFormState(
    productId: productId,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    description: description ?? this.description,
    category: category ?? this.category,
    subtype: subtype ?? this.subtype,
    existingPhotos: existingPhotos ?? this.existingPhotos,
    newPhotos: newPhotos ?? this.newPhotos,
    removedPhotoIndexes: removedPhotoIndexes ?? this.removedPhotoIndexes,
    angles: angles ?? this.angles,
    newAngles: newAngles ?? this.newAngles,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );
}

class _ProductFormController extends Notifier<_ProductFormState> {
  _ProductFormController(this.product);

  final _Product? product;

  @override
  _ProductFormState build() => _ProductFormState(
    productId: product?.id,
    name: product?.name ?? '',
    sku: product?.sku ?? '',
    description: product?.description ?? '',
    category: product?.category ?? 'Tops',
    subtype: product?.subtype ?? 'Crossbody',
    existingPhotos: product?.productPhotos ?? const [],
    angles: {
      for (final (index, photo) in (product?.productPhotos ?? const []).indexed)
        index: photo.viewAngle,
    },
  );

  void setName(String value) => state = state.copyWith(name: value);
  void setSku(String value) => state = state.copyWith(sku: value);
  void setDescription(String value) =>
      state = state.copyWith(description: value);
  void setCategory(String value) => state = state.copyWith(category: value);
  void setSubtype(String value) => state = state.copyWith(subtype: value);
  void addPhotos(List<ProductUpload> photos) =>
      state = state.copyWith(newPhotos: [...state.newPhotos, ...photos]);
  void clearNewPhotos() => state = state.copyWith(newPhotos: const []);
  void removeExistingPhoto(int index) => state = state.copyWith(
    removedPhotoIndexes: {...state.removedPhotoIndexes, index},
  );
  void setAngle(int index, String? value) =>
      state = state.copyWith(angles: {...state.angles, index: value});
  void setNewAngle(int index, String? value) =>
      state = state.copyWith(newAngles: {...state.newAngles, index: value});

  Future<Result<void>?> submit(_Product? product) async {
    if (state.isSubmitting || !state.isValid) return null;
    state = state.copyWith(isSubmitting: true);
    final existing = state.visibleExistingPhotos;
    final draft = CatalogProductDraft(
      name: state.name.trim(),
      sku: state.sku.trim(),
      description: state.description.trim(),
      category: state.category,
      subCategory: state.category == 'Bags' ? state.subtype : '',
      photos: state.newPhotos,
      viewAngles: {
        for (final (displayIndex, photo) in existing.indexed)
          displayIndex: state.angles[photo.$1],
        for (final (index, _) in state.newPhotos.indexed)
          existing.length + index: state.newAngles[index],
      },
    );
    final products = ref.read(_productsControllerProvider.notifier);
    final result = product == null
        ? await products.createProduct(draft)
        : await products.updateProduct(product, draft);
    if (!result.isOk) state = state.copyWith(isSubmitting: false);
    return result;
  }
}

// Riverpod's family provider type is inferred from the factory.
// ignore: specify_nonobvious_property_types
final _productFormProvider = NotifierProvider.autoDispose
    .family<_ProductFormController, _ProductFormState, _Product?>(
      _ProductFormController.new,
    );

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({
    required this.onDeletePhoto,
    required this.onReplacePhoto,
    this.product,
  });

  final _Product? product;
  final Future<bool> Function(int photoIndex) onDeletePhoto;
  final Future<bool> Function(ProductPhoto photo) onReplacePhoto;

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
      remaining: 5 - ref.read(_formProvider).photoCount,
      title: 'Add product photos',
    );
    if (mounted && uploads.isNotEmpty) {
      ref.read(_formProvider.notifier).addPhotos(uploads);
    }
  }

  Future<void> _deletePhoto(int originalIndex) async {
    final deleted = await widget.onDeletePhoto(originalIndex);
    if (mounted && deleted) {
      ref.read(_formProvider.notifier).removeExistingPhoto(originalIndex);
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
              trailing: '${form.photoCount}/5',
              child: _ProductUploadBox(
                label: 'Click to upload photos',
                copy: 'or drag and drop\nPNG, JPG up to 10MB each',
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
              newPhotos: form.newPhotos,
              angles: form.angles,
              newAngles: form.newAngles,
              onAngleChanged: (index, angle) =>
                  ref.read(_formProvider.notifier).setAngle(index, angle),
              onNewAngleChanged: (index, angle) =>
                  ref.read(_formProvider.notifier).setNewAngle(index, angle),
              onDeletePhoto: _deletePhoto,
              onReplacePhoto: widget.onReplacePhoto,
              onClear: editing
                  ? null
                  : ref.read(_formProvider.notifier).clearNewPhotos,
            ),
            if (editing)
              _ProductField(
                label: 'Add New Photos',
                trailing: '${form.photoCount}/5 total',
                child: _ProductUploadBox(
                  label: 'Click to add more photos',
                  copy: 'PNG, JPG up to 10MB each',
                  compact: true,
                  onTap: _pickPhotos,
                ),
              ),
          ],
          if (!editing && form.photoCount == 0)
            const _ProductTip(
              title: 'Pro Tip',
              copy:
                  'Upload 3-5 photos showing different angles for best AI results.',
            ),
        ],
      ),
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
    required this.existingPhotos,
    required this.newPhotos,
    required this.angles,
    required this.newAngles,
    required this.onDeletePhoto,
    required this.onReplacePhoto,
    required this.onAngleChanged,
    required this.onNewAngleChanged,
    this.onClear,
    this.countLabel,
    this.clearLabel,
  });

  final String title;
  final String? countLabel;
  final String? clearLabel;
  final List<(int, ProductPhoto)> existingPhotos;
  final List<ProductUpload> newPhotos;
  final Map<int, String?> angles;
  final Map<int, String?> newAngles;
  final ValueChanged<int> onDeletePhoto;
  final Future<bool> Function(ProductPhoto photo) onReplacePhoto;
  final void Function(int index, String? angle) onAngleChanged;
  final void Function(int index, String? angle) onNewAngleChanged;
  final VoidCallback? onClear;

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
                InkWell(
                  onTap: onClear,
                  child: Text(
                    clearLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 182,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: existingPhotos.length + newPhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index >= existingPhotos.length) {
                  final upload = newPhotos[index - existingPhotos.length];
                  return _ProductThumb(
                    displayIndex: index,
                    upload: upload,
                    isNew: true,
                    angle: newAngles[index - existingPhotos.length],
                    onAngleChanged: (angle) =>
                        onNewAngleChanged(index - existingPhotos.length, angle),
                  );
                }
                final existing = existingPhotos[index];
                return _ProductThumb(
                  displayIndex: index,
                  url: existing.$2.url,
                  angle: angles[existing.$1],
                  onAngleChanged: (angle) => onAngleChanged(existing.$1, angle),
                  onReplace: () => onReplacePhoto(existing.$2),
                  onDelete: () => onDeletePhoto(existing.$1),
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
    required this.displayIndex,
    required this.angle,
    required this.onAngleChanged,
    this.url,
    this.upload,
    this.isNew = false,
    this.onReplace,
    this.onDelete,
  });

  final int displayIndex;
  final String? url;
  final ProductUpload? upload;
  final bool isNew;
  final String? angle;
  final ValueChanged<String?> onAngleChanged;
  final VoidCallback? onReplace;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
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
                  child: upload == null
                      ? _AssetImage(url ?? '')
                      : AppImage.memory(upload!.bytes, fit: BoxFit.cover),
                ),
                if (onReplace != null)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: _ThumbAction(
                      icon: Icons.edit_outlined,
                      onTap: onReplace!,
                    ),
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
                    color: isNew
                        ? AppColors.successDarker
                        : AppColors.blackAlpha90,
                    alignment: Alignment.center,
                    child: Text(
                      isNew ? 'New' : '${displayIndex + 1}',
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
          _MiniSelect(
            angle ?? '',
            onChanged: onAngleChanged,
          ),
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
  const _MiniSelect(this.value, {required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = ['', 'front', 'back', 'side', 'detail', 'top'];
    return SizedBox(
      height: 32,
      child: AppDropdown<String>(
        value: values.contains(value) ? value : '',
        values: values,
        labelFor: (angle) => angle.isEmpty
            ? 'Choose angle'
            : '${angle[0].toUpperCase()}${angle.substring(1)}',
        onChanged: (angle) => onChanged(angle.isEmpty ? null : angle),
        config: const AppDropdownConfig(
          height: 32,
          horizontalPadding: 7,
        ),
      ),
    );
  }
}

class _ProductIdCard extends StatelessWidget {
  const _ProductIdCard(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(left: BorderSide(color: AppColors.black, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product ID',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            id,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
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

void _openReplacePhotoScreen(
  BuildContext context,
  WidgetRef ref,
  _Product product,
  int photoIndex,
  ValueChanged<String> onToast,
) {
  unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ProductPhotoReplaceScreen(
          product: product,
          photoIndex: photoIndex,
          onReplace: (replacement) async {
            if (product.productPhotos.isEmpty) {
              return const Err(
                ValidationFailure('This product has no photo to replace.'),
              );
            }
            final index = photoIndex.clamp(0, product.productPhotos.length - 1);
            final result = await ref
                .read(_productsControllerProvider.notifier)
                .replacePhoto(
                  product,
                  product.productPhotos[index],
                  replacement,
                );
            if (result.isOk) onToast('Photo replaced');
            return result;
          },
        ),
      ),
    ),
  );
}

void _openCalibration(
  BuildContext context,
  WidgetRef ref,
  _Product product,
  ValueChanged<String> onToast,
) {
  unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ProductCalibrationScreen(
          product: product,
          repository: ref.read(productsRepositoryProvider),
          onSaved: () {
            unawaited(
              ref.read(_productsControllerProvider.notifier).reload(),
            );
            onToast('Calibration saved');
          },
        ),
      ),
    ),
  );
}

class _ProductPhotoReplaceScreen extends ConsumerStatefulWidget {
  const _ProductPhotoReplaceScreen({
    required this.product,
    required this.photoIndex,
    required this.onReplace,
  });

  final _Product product;
  final int photoIndex;
  final Future<Result<void>> Function(ProductUpload replacement) onReplace;

  @override
  ConsumerState<_ProductPhotoReplaceScreen> createState() =>
      _ProductPhotoReplaceScreenState();
}

class _ProductPhotoReplaceScreenState
    extends ConsumerState<_ProductPhotoReplaceScreen> {
  ProductUpload? _replacement;
  var _isSaving = false;

  Future<void> _chooseReplacement() async {
    final replacement = await _pickProductPhoto(
      context,
      ref,
      title: 'Choose replacement photo',
    );
    if (mounted && replacement != null) {
      setState(() => _replacement = replacement);
    }
  }

  Future<void> _save() async {
    final replacement = _replacement;
    if (replacement == null || _isSaving) return;
    setState(() => _isSaving = true);
    final result = await widget.onReplace(replacement);
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      setState(() => _isSaving = false);
      AppSnackBar.showError(context, failure.message);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final assets = widget.product.photoAssets;
    final currentAsset = assets.isEmpty
        ? ''
        : assets[widget.photoIndex.clamp(0, assets.length - 1)];
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ProductFlowHeader(
              title: 'Replace photo',
              subtitle:
                  'Choose a replacement photo, then save it to this product.',
              action: AppOutlinedButton(
                label: 'Choose photo',
                icon: Icons.photo_library_outlined,
                onPressed: _chooseReplacement,
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
                child: SizedBox(
                  width: 284,
                  height: 420,
                  child: _replacement == null
                      ? _AssetImage(currentAsset)
                      : AppImage.memory(
                          _replacement!.bytes,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            _ProductFlowFooter(
              primaryLabel: 'Save replacement',
              onBack: () => Navigator.pop(context),
              onPrimary: _replacement == null || _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCalibrationScreen extends ConsumerStatefulWidget {
  const _ProductCalibrationScreen({
    required this.product,
    required this.repository,
    required this.onSaved,
  });

  final _Product product;
  final ProductsRepository repository;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ProductCalibrationScreen> createState() =>
      _ProductCalibrationScreenState();
}

class _ProductCalibrationScreenState
    extends ConsumerState<_ProductCalibrationScreen> {
  _CalibrationStep _step = _CalibrationStep.method;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  ProductCalibrationWorkspace? _workspace;
  Failure? _failure;
  var _bodyArea = 'full_body_front';
  var _isLoading = true;
  var _isMutating = false;
  ProductUpload? _cutout;
  var _placementX = 0.5;
  var _placementY = 0.56;
  var _placementScale = 1.0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _go(_CalibrationStep step) => setState(() => _step = step);

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });
    final result = await widget.repository.loadCalibration(widget.product.id);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _workspace = value;
        _bodyArea = value.calibration.bodyArea ?? _bodyArea;
        _notesController.text = value.calibration.userNotes ?? '';
        final placement = value.calibration.cutoutPlacement;
        _placementX = _placementValue(placement['x'], _placementX);
        _placementY = _placementValue(placement['y'], _placementY);
        _placementScale = _placementValue(
          placement['scale'],
          _placementScale,
        );
        setState(() => _isLoading = false);
      case Err(:final failure):
        setState(() {
          _isLoading = false;
          _failure = failure;
        });
    }
  }

  Future<ProductUpload?> _pickUpload(String title) =>
      _pickProductPhoto(context, ref, title: title);

  static double _placementValue(Object? value, double fallback) =>
      value is num ? value.toDouble() : fallback;

  void _updatePlacement(double x, double y, double scale) {
    setState(() {
      _placementX = x.clamp(0.1, 0.9);
      _placementY = y.clamp(0.1, 0.9);
      _placementScale = scale.clamp(0.5, 2);
    });
  }

  Future<void> _uploadCutout() async {
    final upload = await _pickUpload('Choose transparent product cutout');
    if (upload == null || !mounted) return;
    setState(() {
      _cutout = upload;
      _isMutating = true;
      _step = _CalibrationStep.removingBackground;
    });
    final result = await widget.repository.uploadCutout(
      widget.product.id,
      upload,
    );
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      setState(() {
        _isMutating = false;
        _failure = failure;
        _step = _CalibrationStep.pickPhoto;
      });
      AppSnackBar.showError(context, failure.message);
      return;
    }
    setState(() {
      _isMutating = false;
      _step = _CalibrationStep.confirmCutout;
    });
  }

  Future<void> _uploadWornPhoto() async {
    final upload = await _pickUpload('Upload worn product photo');
    if (upload == null || !mounted) return;
    setState(() => _isMutating = true);
    final result = await widget.repository.uploadWornPhoto(
      widget.product.id,
      upload,
    );
    if (!mounted) return;
    setState(() => _isMutating = false);
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    widget.onSaved();
    Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    final result = await widget.repository.saveCalibration(
      widget.product.id,
      ProductCalibrationDraft(
        bodyArea: _bodyArea,
        shapes: const [],
        userNotes: _notesController.text.trim(),
        cutoutPlacement: {
          'x': _placementX,
          'y': _placementY,
          'scale': _placementScale,
        },
      ),
    );
    if (!mounted) return;
    setState(() => _isMutating = false);
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    widget.onSaved();
    Navigator.pop(context);
  }

  Future<void> _copyFrom(ProductCatalogItem source) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    final result = await widget.repository.copyCalibration(
      widget.product.id,
      source.id,
    );
    if (!mounted) return;
    setState(() => _isMutating = false);
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(context, failure.message);
      return;
    }
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: BarSpinner(size: 32, color: AppColors.black),
          ),
        ),
      );
    }
    if (_workspace == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Set real-world size',
          showBackButton: true,
        ),
        body: _ProductLoadFailure(
          message: _failure?.message ?? 'Could not load calibration.',
          onRetry: _load,
        ),
      );
    }
    final content = switch (_step) {
      _CalibrationStep.method => _CalibrationMethodStep(
        onBody: () => _go(_CalibrationStep.bodyView),
        onWorn: () => _go(_CalibrationStep.wornPhoto),
        onCopy: () => _go(_CalibrationStep.copyFrom),
      ),
      _CalibrationStep.bodyView => _CalibrationBodyStep(
        outlines: _workspace!.outlines,
        selectedBodyArea: _bodyArea,
        onSelected: (value) => setState(() => _bodyArea = value),
        onBack: () => _go(_CalibrationStep.method),
        onNext: () => _go(_CalibrationStep.pickPhoto),
      ),
      _CalibrationStep.pickPhoto => _CalibrationPickPhotoStep(
        product: widget.product,
        onBack: () => _go(_CalibrationStep.bodyView),
        onNext: _uploadCutout,
      ),
      _CalibrationStep.removingBackground => _CalibrationProgressStep(
        onBack: () => _go(_CalibrationStep.pickPhoto),
      ),
      _CalibrationStep.confirmCutout => _CalibrationConfirmCutoutStep(
        product: widget.product,
        cutout: _cutout,
        onBack: () => _go(_CalibrationStep.pickPhoto),
        onNext: () => _go(_CalibrationStep.placeProduct),
      ),
      _CalibrationStep.placeProduct => _CalibrationPlaceStep(
        product: widget.product,
        cutout: _cutout,
        placementX: _placementX,
        placementY: _placementY,
        placementScale: _placementScale,
        onPlacementChanged: _updatePlacement,
        onBack: () => _go(_CalibrationStep.confirmCutout),
        onNext: () => _go(_CalibrationStep.review),
      ),
      _CalibrationStep.review => _CalibrationReviewStep(
        product: widget.product,
        cutout: _cutout,
        placementX: _placementX,
        placementY: _placementY,
        placementScale: _placementScale,
        notesController: _notesController,
        onBack: () => _go(_CalibrationStep.placeProduct),
        onSave: _save,
        isSaving: _isMutating,
      ),
      _CalibrationStep.wornPhoto => _CalibrationWornStep(
        onBack: () => _go(_CalibrationStep.method),
        onUpload: _uploadWornPhoto,
        isUploading: _isMutating,
      ),
      _CalibrationStep.copyFrom => _CalibrationCopyStep(
        searchController: _searchController,
        onBack: () => _go(_CalibrationStep.method),
        products: _workspace!.calibratedProducts
            .where((product) => product.id != widget.product.id)
            .toList(growable: false),
        onCopy: _copyFrom,
        isCopying: _isMutating,
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
  const _CalibrationBodyStep({
    required this.outlines,
    required this.selectedBodyArea,
    required this.onSelected,
    required this.onBack,
    required this.onNext,
  });

  final List<CalibrationOutline> outlines;
  final String selectedBodyArea;
  final ValueChanged<String> onSelected;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final views = outlines.isEmpty
        ? const [
            CalibrationOutline(
              id: 'full_body_front',
              name: 'Full Body Front',
            ),
            CalibrationOutline(id: 'hand_side', name: 'Hand Side'),
            CalibrationOutline(
              id: 'full_body_side',
              name: 'Full Body Side',
            ),
            CalibrationOutline(id: 'waist_front', name: 'Waist Front'),
          ]
        : outlines;
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
                GridView.builder(
                  itemCount: views.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.58,
                  ),
                  itemBuilder: (context, index) {
                    final view = views[index];
                    return _BodyTile(
                      view.name,
                      'Tap to use this body view',
                      active: selectedBodyArea == view.id,
                      imageUrl: view.imageUrl,
                      onTap: () => onSelected(view.id),
                    );
                  },
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
  const _BodyTile(
    this.title,
    this.subtitle, {
    required this.active,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
                child: _ProductPill.dark('Selected'),
              ),
            Expanded(
              child: imageUrl == null
                  ? CustomPaint(painter: _BodyOutlinePainter())
                  : AppImage(imageUrl!),
            ),
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
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
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
                  title: 'Upload a transparent product cutout',
                  copy:
                      'Choose a PNG cutout with the background already removed, then place it on the body outline.',
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
                              _UploadTile(onTap: onNext),
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
  const _CalibrationProgressStep({required this.onBack});

  final VoidCallback onBack;

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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100Alpha68,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: const Column(
                    children: [
                      BarSpinner(size: 28, color: AppColors.black),
                      SizedBox(height: 12),
                      Text(
                        'Uploading cutout',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
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
    required this.cutout,
    required this.onBack,
    required this.onNext,
  });

  final _Product product;
  final ProductUpload? cutout;
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
                _CheckerBox(asset: product.asset, upload: cutout),
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
    required this.cutout,
    required this.placementX,
    required this.placementY,
    required this.placementScale,
    required this.onPlacementChanged,
    required this.onBack,
    required this.onNext,
  });

  final _Product product;
  final ProductUpload? cutout;
  final double placementX;
  final double placementY;
  final double placementScale;
  final void Function(double x, double y, double scale) onPlacementChanged;
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
                      'Drag to reposition, then use the zoom controls to resize. Match the real-world size of the product compared to the body.',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _ZoomControl(
                    onZoomOut: () => onPlacementChanged(
                      placementX,
                      placementY,
                      placementScale - 0.1,
                    ),
                    onReset: () => onPlacementChanged(0.5, 0.56, 1),
                    onZoomIn: () => onPlacementChanged(
                      placementX,
                      placementY,
                      placementScale + 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _PlacementCanvas(
                  product: product,
                  cutout: cutout,
                  placementX: placementX,
                  placementY: placementY,
                  placementScale: placementScale,
                  onPlacementChanged: onPlacementChanged,
                ),
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
    required this.cutout,
    required this.placementX,
    required this.placementY,
    required this.placementScale,
    required this.notesController,
    required this.onBack,
    required this.onSave,
    required this.isSaving,
  });

  final _Product product;
  final ProductUpload? cutout;
  final double placementX;
  final double placementY;
  final double placementScale;
  final TextEditingController notesController;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final bool isSaving;

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
                  child: _PlacementCanvas(
                    product: product,
                    cutout: cutout,
                    placementX: placementX,
                    placementY: placementY,
                    placementScale: placementScale,
                  ),
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
          primaryLabel: isSaving ? 'Saving...' : 'Save calibration',
          onPrimary: isSaving ? null : onSave,
        ),
      ],
    );
  }
}

class _CalibrationWornStep extends StatelessWidget {
  const _CalibrationWornStep({
    required this.onBack,
    required this.onUpload,
    required this.isUploading,
  });

  final VoidCallback onBack;
  final VoidCallback onUpload;
  final bool isUploading;

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
                InkWell(
                  onTap: isUploading ? null : onUpload,
                  child: AppDottedBorder(
                    color: AppColors.neutral200,
                    strokeWidth: 2,
                    dotWidth: 8,
                    gap: 6,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 220),
                      child: Container(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isUploading)
                              const BarSpinner(
                                size: 28,
                                color: AppColors.black,
                              )
                            else
                              const Icon(
                                Icons.photo_camera_outlined,
                                size: 26,
                                color: AppColors.neutral500,
                              ),
                            const SizedBox(height: 10),
                            Text(
                              isUploading
                                  ? 'Uploading photo'
                                  : 'Tap to choose a photo',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
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
    required this.products,
    required this.onCopy,
    required this.isCopying,
  });

  final TextEditingController searchController;
  final VoidCallback onBack;
  final List<ProductCatalogItem> products;
  final ValueChanged<ProductCatalogItem> onCopy;
  final bool isCopying;

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
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, _) {
                    final query = value.text.trim().toLowerCase();
                    final matches = products
                        .where(
                          (product) =>
                              query.isEmpty ||
                              '${product.name} ${product.sku} '
                                      '${product.category} '
                                      '${product.subCategory ?? ''}'
                                  .toLowerCase()
                                  .contains(query),
                        )
                        .toList(growable: false);
                    if (matches.isEmpty) {
                      return const Text(
                        'No calibrated products found.',
                        style: TextStyle(color: AppColors.neutral500),
                      );
                    }
                    return ListView.builder(
                      itemCount: matches.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final product = matches[index];
                        return _CopyCard(
                          product: product,
                          onTap: isCopying ? null : () => onCopy(product),
                        );
                      },
                    );
                  },
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
  const _UploadTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AppDottedBorder(
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
                'Upload cutout',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'PNG preferred',
                style: TextStyle(fontSize: 10, color: AppColors.neutral500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckerBox extends StatelessWidget {
  const _CheckerBox({required this.asset, this.upload});

  final String asset;
  final ProductUpload? upload;

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
        child: SizedBox(
          width: 176,
          height: 210,
          child: upload == null
              ? _AssetImage(asset)
              : AppImage.memory(upload!.bytes),
        ),
      ),
    );
  }
}

class _ZoomControl extends StatelessWidget {
  const _ZoomControl({
    required this.onZoomOut,
    required this.onReset,
    required this.onZoomIn,
  });

  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton('-', onTap: onZoomOut),
          _ZoomButton('Reset', onTap: onReset, wide: true),
          _ZoomButton('+', onTap: onZoomIn),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton(
    this.label, {
    required this.onTap,
    this.wide = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
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
      ),
    );
  }
}

class _PlacementCanvas extends StatelessWidget {
  const _PlacementCanvas({
    required this.product,
    required this.placementX,
    required this.placementY,
    required this.placementScale,
    this.cutout,
    this.onPlacementChanged,
  });

  final _Product product;
  final ProductUpload? cutout;
  final double placementX;
  final double placementY;
  final double placementScale;
  final void Function(double x, double y, double scale)? onPlacementChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 410.0;
        final productWidth = 118 * placementScale;
        final productHeight = 138 * placementScale;
        return Container(
          height: 410,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Stack(
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
                left: placementX * width - productWidth / 2,
                top: placementY * height - productHeight / 2,
                child: GestureDetector(
                  onPanUpdate: onPlacementChanged == null
                      ? null
                      : (details) => onPlacementChanged!(
                          placementX + details.delta.dx / width,
                          placementY + details.delta.dy / height,
                          placementScale,
                        ),
                  child: Container(
                    width: productWidth,
                    height: productHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: cutout == null
                        ? _AssetImage(product.asset)
                        : AppImage.memory(cutout!.bytes),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CopyCard extends StatelessWidget {
  const _CopyCard({
    required this.product,
    required this.onTap,
  });

  final ProductCatalogItem product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: _AssetImage(product.imageUrl),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      product.sku,
                      product.category,
                      ?product.subCategory,
                    ].where((value) => value.isNotEmpty).join(' - '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _ProductPill.neutral('Calibrated'),
                ],
              ),
            ),
            const Icon(Icons.copy_outlined, size: 16),
          ],
        ),
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
