part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFeatureScaffold(
      title: 'Products',
      maxContentWidth: 440,
      contentBackgroundColor: AppColors.white,
      floatingActionButton: AppFloatingActionButton(
        label: 'Add Product',
        onPressed: () => _showProductFormDialog(
          context,
          ref,
          (text) => _toastDashboard(context, text),
        ),
      ),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Manage your product catalog for AI-generated photoshoots',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 14),
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
