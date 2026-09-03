part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

bool _requestProductsManageAccess(BuildContext context, WidgetRef ref) {
  final hasAccess =
      ref.read(isPremiumProvider) ||
      (ref
              .read(subscriptionControllerProvider)
              .value
              ?.activeEntitlements
              .contains('products_manage') ??
          false);
  if (hasAccess) return true;
  unawaited(context.push(AppRoutes.paywall));
  return false;
}

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({
    this.openCreate = false,
    this.productId,
    this.calibrateProductId,
    this.returnTo,
    this.calibrationStage,
    this.directCalibrationRoute = false,
    super.key,
  });

  final bool openCreate;
  final String? productId;
  final String? calibrateProductId;
  final String? returnTo;
  final String? calibrationStage;
  final bool directCalibrationRoute;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenViewState();
}

class _ProductsScreenViewState extends ConsumerState<ProductsScreen> {
  var _handledDeepLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());
  }

  Future<void> _handleDeepLink() async {
    if (!mounted || _handledDeepLink) return;
    if (widget.openCreate) {
      _handledDeepLink = true;
      _consumeCommand('create');
      if (!_requestProductsManageAccess(context, ref)) return;
      await _showProductFormDialog(
        context,
        ref,
        (text) => _toastDashboard(context, text),
      );
      return;
    }
    final targetId = widget.calibrateProductId ?? widget.productId;
    if (targetId == null) {
      _handledDeepLink = true;
      return;
    }
    if (ref.read(_productsControllerProvider).isLoading) return;
    _handledDeepLink = true;
    final product = await ref
        .read(_productsControllerProvider.notifier)
        .resolveProduct(targetId);
    if (!mounted) return;
    _consumeCommand(
      widget.calibrateProductId != null ? 'calibrate' : 'product',
    );
    if (product == null) {
      AppSnackBar.showError(
        context,
        widget.calibrateProductId != null
            ? 'Calibration did not load. That product is unavailable.'
            : 'That product is unavailable.',
      );
      return;
    }
    void onToast(String text) => _toastDashboard(context, text);
    if (widget.calibrateProductId != null) {
      if (!_requestProductsManageAccess(context, ref)) return;
      await _openDeepLinkedCalibration(product, onToast);
    } else {
      await _showProductDetailSheet(context, ref, product, onToast);
    }
  }

  void _consumeCommand(String key) {
    final uri = GoRouterState.of(context).uri;
    if (!uri.queryParameters.containsKey(key) &&
        !(key == 'product' && uri.queryParameters.containsKey('productId'))) {
      return;
    }
    final query = Map<String, String>.from(uri.queryParameters)..remove(key);
    if (key == 'product') query.remove('productId');
    context.replace(uri.replace(queryParameters: query).toString());
  }

  Future<void> _openDeepLinkedCalibration(
    _Product product,
    ValueChanged<String> onToast,
  ) async {
    await _openCalibration(
      context,
      ref,
      product,
      onToast,
      initialStage: widget.calibrationStage,
    );
    if (!mounted) return;
    if (widget.returnTo != null) {
      context.go(widget.returnTo!);
    } else if (widget.directCalibrationRoute) {
      context.go(AppRoutes.dashboardProducts);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      _productsControllerProvider.select((state) => state.products),
      (_, _) => unawaited(_handleDeepLink()),
    );
    return AppFeatureScaffold(
      title: 'Products',
      maxContentWidth: 440,
      contentBackgroundColor: AppColors.neutral50,
      child: _ProductsPage(onToast: (text) => _toastDashboard(context, text)),
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
    return RefreshIndicator(
      onRefresh: controller.reload,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductsLibraryHeader(
                    onAdd: () {
                      if (_requestProductsManageAccess(context, ref)) {
                        unawaited(
                          _showProductFormDialog(context, ref, onToast),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                  _ProductsCatalogStats(
                    total: state.totalCount,
                    loaded: state.products.length,
                    calibrated: state.calibrationStatusesAvailable
                        ? state.calibratedCount
                        : null,
                  ),
                  if (state.calibrationFailure != null) ...[
                    const SizedBox(height: 12),
                    _CalibrationCatalogFailure(
                      onRetry: controller.reload,
                    ),
                  ],
                  const SizedBox(height: 42),
                  if (uncategorized.isNotEmpty &&
                      !state.categoryBannerDismissed)
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
                  _ProductsSectionHeading(
                    loaded: state.products.length,
                    total: state.totalCount,
                  ),
                  const SizedBox(height: 22),
                  _ProductFilterBar(
                    query: state.searchQuery,
                    categoryFilter: state.categoryFilter,
                    statusFilter: state.statusFilter,
                    sortOrder: state.sortOrder,
                    totalCount: state.totalCount,
                    calibratedCount: state.calibratedCount,
                    calibrationStatusesAvailable:
                        state.calibrationStatusesAvailable,
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
                    _ProductEmptyResults(
                      query: state.searchQuery,
                      hasActiveFilters:
                          state.categoryFilter != _ProductCategoryFilter.all ||
                          state.statusFilter != _ProductStatusFilter.all ||
                          state.sortOrder != _ProductSortOrder.newest,
                      onClear: controller.clearFilters,
                      onAdd: () => _showProductFormDialog(
                        context,
                        ref,
                        onToast,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (state.products.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _ProductCatalogGrid(
                products: state.products,
                onAdd: () {
                  if (_requestProductsManageAccess(context, ref)) {
                    unawaited(_showProductFormDialog(context, ref, onToast));
                  }
                },
                onOpen: (product) => unawaited(
                  _showProductDetailSheet(context, ref, product, onToast),
                ),
                onCalibrate: (product) {
                  if (_requestProductsManageAccess(context, ref)) {
                    unawaited(
                      _openCalibration(context, ref, product, onToast),
                    );
                  }
                },
              ),
            ),
          if (state.currentPage < state.totalPages)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: AppOutlinedButton(
                  label: state.isLoadingMore ? 'Loading...' : 'Load more',
                  onPressed: state.isLoadingMore
                      ? null
                      : controller.loadNextPage,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

class _ProductCatalogGrid extends StatelessWidget {
  const _ProductCatalogGrid({
    required this.products,
    required this.onAdd,
    required this.onOpen,
    required this.onCalibrate,
  });

  final List<_Product> products;
  final VoidCallback onAdd;
  final ValueChanged<_Product> onOpen;
  final ValueChanged<_Product> onCalibrate;

  @override
  Widget build(BuildContext context) {
    final itemCount = products.length + 1;
    final rowCount = (itemCount / 2).ceil();
    return SliverList.builder(
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        final firstIndex = rowIndex * 2;
        final secondIndex = firstIndex + 1;
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex == rowCount - 1 ? 0 : 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildItem(firstIndex)),
                const SizedBox(width: 8),
                Expanded(
                  child: secondIndex < itemCount
                      ? _buildItem(secondIndex)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(int index) {
    if (index == products.length) return _ProductAddCard(onTap: onAdd);
    final product = products[index];
    return _ProductCard(
      key: ValueKey('product-card-${product.sku}'),
      index: index,
      product: product,
      onOpen: () => onOpen(product),
      onCalibrate: () => onCalibrate(product),
    );
  }
}

class _ProductsSectionHeading extends StatelessWidget {
  const _ProductsSectionHeading({required this.loaded, required this.total});

  final int loaded;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 12),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.neutral200)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '01',
          style: TextStyle(
            color: AppColors.neutral500,
            fontFamily: _productDisplayFontFamily,
            fontStyle: FontStyle.italic,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CatalogEyebrow('Your catalog'),
              const SizedBox(height: 3),
              const Text(
                'The pieces in your studio.',
                style: TextStyle(
                  fontFamily: _productDisplayFontFamily,
                  fontSize: 31,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              _CatalogEyebrow('$loaded of $total'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CatalogEyebrow extends StatelessWidget {
  const _CatalogEyebrow(this.text, {this.color = AppColors.neutral500});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    ),
  );
}

class _ProductAddCard extends StatelessWidget {
  const _ProductAddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha68,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 25),
          SizedBox(height: 16),
          Text(
            'Add another product',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _productDisplayFontFamily,
              fontSize: 24,
              height: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bring a new piece into your studio catalog.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProductsLoadingShimmer extends StatelessWidget {
  const _ProductsLoadingShimmer();

  @override
  Widget build(BuildContext context) => const CustomScrollView(
    key: ValueKey('products-loading-shimmer'),
    slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 30, 16, 0),
        sliver: SliverToBoxAdapter(child: _ProductsLoadingChrome()),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 96),
        sliver: SliverToBoxAdapter(child: _ProductsLoadingShimmerGrid()),
      ),
    ],
  );
}

class _ProductsLoadingShimmerGrid extends StatelessWidget {
  const _ProductsLoadingShimmerGrid();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.58,
              child: _ProductLoadingShimmerCard(
                key: ValueKey('product-loading-shimmer-card-0'),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.58,
              child: _ProductLoadingShimmerCard(
                key: ValueKey('product-loading-shimmer-card-1'),
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.58,
              child: _ProductLoadingShimmerCard(
                key: ValueKey('product-loading-shimmer-card-2'),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.58,
              child: _ProductLoadingShimmerCard(
                key: ValueKey('product-loading-shimmer-card-3'),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Mirrors the catalog's editorial header, metrics, section label, and
/// filters so the loaded screen arrives without a disruptive layout shift.
class _ProductsLoadingChrome extends StatelessWidget {
  const _ProductsLoadingChrome();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FractionallySizedBox(
        widthFactor: 0.24,
        child: SizedBox(height: 10, child: ShimmerBox()),
      ),
      SizedBox(height: 10),
      FractionallySizedBox(
        widthFactor: 0.48,
        child: SizedBox(height: 48, child: ShimmerBox()),
      ),
      SizedBox(height: 16),
      SizedBox(height: 12, child: ShimmerBox()),
      SizedBox(height: 7),
      FractionallySizedBox(
        widthFactor: 0.76,
        child: SizedBox(height: 12, child: ShimmerBox()),
      ),
      SizedBox(height: 28),
      FractionallySizedBox(
        widthFactor: 0.38,
        alignment: Alignment.centerLeft,
        child: SizedBox(height: 44, child: ShimmerBox()),
      ),
      SizedBox(height: 40),
      _ProductsStatsLoadingShimmer(),
      SizedBox(height: 42),
      _ProductsSectionLoadingShimmer(),
      SizedBox(height: 22),
      _ProductsFiltersLoadingShimmer(),
    ],
  );
}

class _ProductsStatsLoadingShimmer extends StatelessWidget {
  const _ProductsStatsLoadingShimmer();

  @override
  Widget build(BuildContext context) => Container(
    height: 149,
    color: AppColors.black,
    padding: const EdgeInsets.all(14),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: ShimmerBox(dark: true)),
              SizedBox(width: 12),
              Expanded(child: ShimmerBox(dark: true)),
              SizedBox(width: 12),
              Expanded(child: ShimmerBox(dark: true)),
            ],
          ),
        ),
        SizedBox(height: 14),
        FractionallySizedBox(
          widthFactor: 0.8,
          child: SizedBox(height: 10, child: ShimmerBox(dark: true)),
        ),
      ],
    ),
  );
}

class _ProductsSectionLoadingShimmer extends StatelessWidget {
  const _ProductsSectionLoadingShimmer();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.neutral200)),
    ),
    child: Padding(
      padding: EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, height: 18, child: ShimmerBox()),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.34,
                  child: SizedBox(height: 10, child: ShimmerBox()),
                ),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.82,
                  child: SizedBox(height: 31, child: ShimmerBox()),
                ),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.2,
                  child: SizedBox(height: 10, child: ShimmerBox()),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProductsFiltersLoadingShimmer extends StatelessWidget {
  const _ProductsFiltersLoadingShimmer();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: 40, child: ShimmerBox()),
      SizedBox(height: 1),
      SizedBox(height: 46, child: ShimmerBox()),
      SizedBox(height: 1),
      SizedBox(height: 46, child: ShimmerBox()),
      SizedBox(height: 1),
      SizedBox(height: 46, child: ShimmerBox()),
      SizedBox(height: 10),
      FractionallySizedBox(
        widthFactor: 0.34,
        child: SizedBox(height: 10, child: ShimmerBox()),
      ),
    ],
  );
}

class _ProductLoadingShimmerCard extends StatelessWidget {
  const _ProductLoadingShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: ShimmerBox(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.76,
                  child: SizedBox(height: 14, child: ShimmerBox()),
                ),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.48,
                  child: SizedBox(height: 10, child: ShimmerBox()),
                ),
                SizedBox(height: 18),
                FractionallySizedBox(
                  widthFactor: 0.42,
                  child: SizedBox(height: 18, child: ShimmerBox()),
                ),
              ],
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.38,
            ),
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
