part of '../screens/house_model_page.dart';

class _HouseModelLibraryLoadingGrid extends StatelessWidget {
  const _HouseModelLibraryLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        final portraitHeight = (cardWidth - 24) * 16 / 9;
        return GridView.builder(
          key: const ValueKey('house-model-library-shimmer-grid'),
          padding: const EdgeInsets.only(top: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: portraitHeight + 44,
          ),
          itemCount: 6,
          itemBuilder: (_, index) => _LibraryModelShimmerCard(
            key: ValueKey('house-model-library-shimmer-card-$index'),
          ),
        );
      },
    );
  }
}

class _HouseModelUserLoadingList extends StatelessWidget {
  const _HouseModelUserLoadingList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final portraitHeight = (constraints.maxWidth - 32) * 16 / 9;
        return GridView.builder(
          key: const ValueKey('house-model-user-shimmer-list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 16,
            mainAxisExtent: portraitHeight + 112,
          ),
          itemCount: 4,
          itemBuilder: (_, index) => _UserModelShimmerCard(
            key: ValueKey('house-model-user-shimmer-card-$index'),
          ),
        );
      },
    );
  }
}

class _LibraryModelShimmerCard extends StatelessWidget {
  const _LibraryModelShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.inkAlpha05,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: ShimmerBox(),
            ),
            SizedBox(height: 8),
            FractionallySizedBox(
              widthFactor: 0.75,
              child: SizedBox(
                height: 12,
                child: ShimmerBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserModelShimmerCard extends StatelessWidget {
  const _UserModelShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.inkAlpha05,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FractionallySizedBox(
              widthFactor: 0.75,
              child: SizedBox(
                height: 16,
                child: ShimmerBox(),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 20,
                  child: ShimmerBox(),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  height: 12,
                  child: ShimmerBox(),
                ),
              ],
            ),
            SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 9 / 16,
              child: ShimmerBox(),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 64,
                  height: 12,
                  child: ShimmerBox(),
                ),
                SizedBox(
                  width: 80,
                  height: 12,
                  child: ShimmerBox(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
