part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

const _houseModelShimmerBase = Color(0xFFEAEAEA);

class _HouseModelLibraryLoadingGrid extends StatelessWidget {
  const _HouseModelLibraryLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return _HouseModelShimmer(
      builder: (animation) => LayoutBuilder(
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
              animation: animation,
            ),
          );
        },
      ),
    );
  }
}

class _HouseModelUserLoadingList extends StatelessWidget {
  const _HouseModelUserLoadingList();

  @override
  Widget build(BuildContext context) {
    return _HouseModelShimmer(
      builder: (animation) => LayoutBuilder(
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
              animation: animation,
            ),
          );
        },
      ),
    );
  }
}

class _LibraryModelShimmerCard extends StatelessWidget {
  const _LibraryModelShimmerCard({required this.animation, super.key});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: _HouseModelShimmerBox(animation: animation),
            ),
            const SizedBox(height: 8),
            FractionallySizedBox(
              widthFactor: 0.75,
              child: SizedBox(
                height: 12,
                child: _HouseModelShimmerBox(animation: animation),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserModelShimmerCard extends StatelessWidget {
  const _UserModelShimmerCard({required this.animation, super.key});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FractionallySizedBox(
              widthFactor: 0.75,
              child: SizedBox(
                height: 16,
                child: _HouseModelShimmerBox(animation: animation),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 20,
                  child: _HouseModelShimmerBox(animation: animation),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  height: 12,
                  child: _HouseModelShimmerBox(animation: animation),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 9 / 16,
              child: _HouseModelShimmerBox(animation: animation),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 64,
                  height: 12,
                  child: _HouseModelShimmerBox(animation: animation),
                ),
                SizedBox(
                  width: 80,
                  height: 12,
                  child: _HouseModelShimmerBox(animation: animation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseModelShimmer extends StatefulWidget {
  const _HouseModelShimmer({required this.builder});

  final Widget Function(Animation<double> animation) builder;

  @override
  State<_HouseModelShimmer> createState() => _HouseModelShimmerState();
}

class _HouseModelShimmerState extends State<_HouseModelShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: widget.builder(_controller));
  }
}

class _HouseModelShimmerBox extends StatelessWidget {
  const _HouseModelShimmerBox({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final travel = animation.value * 4 - 3;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(travel, 0),
              end: Alignment(travel + 2, 0),
              colors: const [
                _houseModelShimmerBase,
                AppColors.neutral150,
                _houseModelShimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }
}
