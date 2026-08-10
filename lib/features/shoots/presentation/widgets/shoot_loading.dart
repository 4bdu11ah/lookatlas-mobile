part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootsLoading extends StatelessWidget {
  const _ShootsLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FractionallySizedBox(
          widthFactor: 0.52,
          alignment: Alignment.centerLeft,
          child: SizedBox(height: 18, child: ShimmerBox()),
        ),
        const SizedBox(height: 14),
        const SizedBox(height: 40, child: ShimmerBox()),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: FractionallySizedBox(
                widthFactor: 0.22,
                alignment: Alignment.centerLeft,
                child: SizedBox(height: 12, child: ShimmerBox()),
              ),
            ),
            SizedBox(width: 92, height: 40, child: ShimmerBox()),
          ],
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < 4; index++) ...[
          const _ShootLoadingCard(),
          if (index != 3) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ShootLoadingCard extends StatelessWidget {
  const _ShootLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 254,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.blackAlpha07,
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: SizedBox(width: 100, height: 100, child: ShimmerBox())),
          SizedBox(height: 10),
          FractionallySizedBox(
            widthFactor: 0.56,
            child: SizedBox(height: 16, child: ShimmerBox()),
          ),
          SizedBox(height: 10),
          FractionallySizedBox(
            widthFactor: 0.28,
            child: SizedBox(height: 20, child: ShimmerBox()),
          ),
          SizedBox(height: 10),
          FractionallySizedBox(
            widthFactor: 0.72,
            child: SizedBox(height: 12, child: ShimmerBox()),
          ),
          SizedBox(height: 12),
          SizedBox(height: 36, child: ShimmerBox()),
        ],
      ),
    );
  }
}
