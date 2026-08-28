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
    super.key,
  });

  final bool openCreate;
  final String? productId;
  final String? calibrateProductId;
  final String? returnTo;

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

  void _handleDeepLink() {
    if (!mounted || _handledDeepLink) return;
    if (widget.openCreate) {
      _handledDeepLink = true;
      if (!_requestProductsManageAccess(context, ref)) return;
      unawaited(
        _showProductFormDialog(
          context,
          ref,
          (text) => _toastDashboard(context, text),
        ),
      );
      return;
    }
    final targetId = widget.calibrateProductId ?? widget.productId;
    if (targetId == null) {
      _handledDeepLink = true;
      return;
    }
    final product = ref
        .read(_productsControllerProvider)
        .products
        .where((item) => item.id == targetId)
        .firstOrNull;
    if (product == null) return;
    _handledDeepLink = true;
    void onToast(String text) => _toastDashboard(context, text);
    if (widget.calibrateProductId != null) {
      if (!_requestProductsManageAccess(context, ref)) return;
      unawaited(_openDeepLinkedCalibration(product, onToast));
    } else {
      unawaited(_showProductDetailSheet(context, ref, product, onToast));
    }
  }

  Future<void> _openDeepLinkedCalibration(
    _Product product,
    ValueChanged<String> onToast,
  ) async {
    await _openCalibration(context, ref, product, onToast);
    if (mounted && widget.returnTo != null) context.go(widget.returnTo!);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      _productsControllerProvider.select((state) => state.products),
      (_, _) => _handleDeepLink(),
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
                    calibrated: state.calibratedCount,
                  ),
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
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: state.products.length + 1,
                itemBuilder: (context, index) {
                  if (index == state.products.length) {
                    return _ProductAddCard(
                      onTap: () {
                        if (_requestProductsManageAccess(context, ref)) {
                          unawaited(
                            _showProductFormDialog(context, ref, onToast),
                          );
                        }
                      },
                    );
                  }
                  final product = state.products[index];
                  return _ProductCard(
                    key: ValueKey('product-card-${product.sku}'),
                    index: index,
                    product: product,
                    onOpen: () => unawaited(
                      _showProductDetailSheet(context, ref, product, onToast),
                    ),
                    onCalibrate: () {
                      if (_requestProductsManageAccess(context, ref)) {
                        unawaited(
                          _openCalibration(context, ref, product, onToast),
                        );
                      }
                    },
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
            fontFamily: 'Instrument Serif',
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
                  fontFamily: 'Instrument Serif',
                  fontFamilyFallback: ['serif'],
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
              fontFamily: 'Instrument Serif',
              fontFamilyFallback: ['serif'],
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
