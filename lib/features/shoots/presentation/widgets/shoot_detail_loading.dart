part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootDetailLoading extends StatelessWidget {
  const _ShootDetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShootDetailLoadingHeader(),
        SizedBox(height: 14),
        _ShootDetailLoadingSummary(),
        SizedBox(height: 14),
        _ShootDetailLoadingVideo(),
        SizedBox(height: 14),
        _ShootDetailLoadingImages(),
      ],
    );
  }
}

class _ShootDetailLoadingHeader extends StatelessWidget {
  const _ShootDetailLoadingHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FractionallySizedBox(
          widthFactor: 0.6,
          child: SizedBox(height: 24, child: ShimmerBox()),
        ),
        SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: 0.4,
          child: SizedBox(height: 14, child: ShimmerBox()),
        ),
        SizedBox(height: 14),
        FractionallySizedBox(
          widthFactor: 0.25,
          child: SizedBox(height: 22, child: ShimmerBox()),
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: SizedBox(height: 36, child: ShimmerBox())),
            SizedBox(width: 8),
            Expanded(child: SizedBox(height: 36, child: ShimmerBox())),
          ],
        ),
      ],
    );
  }
}

class _ShootDetailLoadingSummary extends StatelessWidget {
  const _ShootDetailLoadingSummary();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ShootDetailLoadingStat(hasImage: true),
        SizedBox(height: 8),
        _ShootDetailLoadingStat(hasImage: true),
        SizedBox(height: 8),
        _ShootDetailLoadingStat(),
      ],
    );
  }
}

class _ShootDetailLoadingStat extends StatelessWidget {
  const _ShootDetailLoadingStat({this.hasImage = false});

  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          if (hasImage) ...[
            const SizedBox(width: 45, height: 45, child: ShimmerBox()),
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.24,
                  child: SizedBox(height: 11, child: ShimmerBox()),
                ),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.58,
                  child: SizedBox(height: 15, child: ShimmerBox()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShootDetailLoadingVideo extends StatelessWidget {
  const _ShootDetailLoadingVideo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 184,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FractionallySizedBox(
            widthFactor: 0.42,
            child: SizedBox(height: 16, child: ShimmerBox()),
          ),
          Spacer(),
          Center(child: SizedBox(width: 44, height: 44, child: ShimmerBox())),
          SizedBox(height: 12),
          FractionallySizedBox(
            widthFactor: 0.72,
            child: SizedBox(height: 12, child: ShimmerBox()),
          ),
          SizedBox(height: 12),
          Center(child: SizedBox(width: 138, height: 36, child: ShimmerBox())),
        ],
      ),
    );
  }
}

class _ShootDetailLoadingImages extends StatelessWidget {
  const _ShootDetailLoadingImages();

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
          FractionallySizedBox(
            widthFactor: 0.42,
            child: SizedBox(height: 18, child: ShimmerBox()),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1, child: ShimmerBox())),
              SizedBox(width: 10),
              Expanded(child: AspectRatio(aspectRatio: 1, child: ShimmerBox())),
            ],
          ),
        ],
      ),
    );
  }
}
