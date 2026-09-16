part of '../screens/shoot_detail_screen.dart';

class _ShootMetadataStrip extends StatelessWidget {
  const _ShootMetadataStrip({required this.job});

  final ShootJob job;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      _MetadataPill(
        icon: Icons.inventory_2_outlined,
        label: job.productSku == null ? 'Product' : 'SKU ${job.productSku}',
      ),
      _MetadataPill(
        icon: Icons.person_outline,
        label: job.modelName ?? 'Product only',
      ),
      _MetadataPill(
        icon: Icons.camera_alt_outlined,
        label: job.directorName ?? job.preset ?? 'AI directed',
      ),
      _MetadataPill(
        icon: Icons.high_quality_outlined,
        label: job.imageSize ?? '2K',
      ),
    ],
  );
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.neutral500),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ReviewDensityPicker extends StatelessWidget {
  const _ReviewDensityPicker({
    required this.selected,
    required this.onSelected,
  });

  final ShootReviewDensity selected;
  final ValueChanged<ShootReviewDensity> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final value in ShootReviewDensity.values)
        Expanded(
          child: InkWell(
            key: ValueKey('shoot-density-${value.name}'),
            onTap: () => onSelected(value),
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value == selected ? AppColors.black : AppColors.white,
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Text(
                switch (value) {
                  ShootReviewDensity.editorial => 'Editorial',
                  ShootReviewDensity.dense => 'Dense',
                  ShootReviewDensity.grid => 'Grid',
                },
                style: TextStyle(
                  color: value == selected ? AppColors.white : AppColors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _ShootProgress extends StatelessWidget {
  const _ShootProgress({
    required this.progress,
    this.currentStep,
    this.estimatedCompletion,
  });

  final double progress;
  final String? currentStep;
  final DateTime? estimatedCompletion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentStep ?? 'Generating images...',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppProgressBar(value: progress),
          if (estimatedCompletion != null) ...[
            const SizedBox(height: 8),
            AppCaption(
              'Estimated completion ${DateFormat.jm().format(estimatedCompletion!.toLocal())}',
            ),
          ],
        ],
      ),
    );
  }
}

class _ShootSummary extends StatelessWidget {
  const _ShootSummary({required this.shoot, this.modelName});

  final ShootViewModel shoot;
  final String? modelName;

  @override
  Widget build(BuildContext context) {
    return AppSpacedColumn(
      gap: 8,
      children: [
        _ShootStat(
          label: 'Product',
          title: shoot.name,
          caption: shoot.productSku == null
              ? 'Selected product'
              : 'SKU: ${shoot.productSku}',
          asset: shoot.productAsset,
        ),
        _ShootStat(
          label: 'Model',
          title: modelName ?? 'Model',
          caption: '',
          asset: shoot.modelAsset,
        ),
        _ShootStat(
          label: 'Created',
          title: shoot.date,
          caption:
              '${shoot.renders} ${shoot.renders == 1 ? 'variation' : 'variations'} · Standard resolution',
        ),
      ],
    );
  }
}

class _ShootStat extends StatelessWidget {
  const _ShootStat({
    required this.label,
    required this.title,
    required this.caption,
    this.asset,
  });

  final String label;
  final String title;
  final String caption;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppEyebrow(label),
          const SizedBox(height: 9),
          Row(
            children: [
              if (asset != null) ...[
                AppAssetBox(asset!, width: 45, height: 45),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCardTitle(title),
                    if (caption.isNotEmpty) AppCaption(caption),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportActions extends StatelessWidget {
  const _ExportActions({required this.approvedCount, required this.onExport});

  final int approvedCount;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final publishLabel = approvedCount >= 3
        ? 'Publish approved images'
        : 'Approve at least 3 images ($approvedCount/3)';
    return AppSpacedColumn(
      gap: 8,
      children: [
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                label: 'Export (ZIP + CSV)',
                icon: Icons.download_outlined,
                height: 44,
                onPressed: onExport,
              ),
            ),
            const SizedBox(width: 8),
            AppOutlinedButton(
              label: 'CSV Only',
              fitToContent: true,
              height: 44,
              onPressed: onExport,
            ),
          ],
        ),
        AppOutlinedButton(
          label: publishLabel,
          icon: Icons.public_outlined,
          height: 44,
          foregroundColor: approvedCount >= 3 ? null : AppColors.neutral500,
          borderColor: approvedCount >= 3 ? null : AppColors.neutral400,
          onPressed: approvedCount >= 3 ? () {} : null,
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                AppSquareIcon(Icons.video_camera_back_outlined),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCardTitle('Model Video'),
                    AppCaption('AI-generated motion'),
                  ],
                ),
              ],
            ),
          ),
          const AppHairline(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const AppSquareIcon(Icons.movie_creation_outlined),
                const SizedBox(height: 10),
                const AppBodyText(
                  'Create an 8-second cinematic video from your best variation.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Generate Video',
                  icon: Icons.auto_awesome,
                  foregroundColor: AppColors.white,
                  fitToContent: true,
                  onPressed: enabled ? onTap : () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedImages extends StatelessWidget {
  const _GeneratedImages({
    required this.isProcessing,
    required this.density,
    required this.shots,
    required this.onApprove,
    required this.onPreview,
    required this.onEdit,
    required this.onVersions,
    required this.onVariation,
    required this.onDownload,
    required this.onReport,
  });

  final bool isProcessing;
  final ShootReviewDensity density;
  final List<ShootShot> shots;
  final ValueChanged<ShootImage> onApprove;
  final ValueChanged<ShootImage> onPreview;
  final ValueChanged<ShootImage> onEdit;
  final ValueChanged<ShootImage> onVersions;
  final ValueChanged<int> onVariation;
  final ValueChanged<ShootImage> onDownload;
  final ValueChanged<ShootImage> onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: AppSectionTitle('Generated Images'),
          ),
          const AppHairline(),
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              child: Column(
                children: [
                  AppSquareIcon(Icons.schedule),
                  SizedBox(height: 14),
                  AppSectionTitle('Generating images...'),
                  SizedBox(height: 6),
                  AppCaption('This may take a few minutes'),
                ],
              ),
            )
          else if (shots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: AppCaption('No generated images are available yet.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shots.length,
              separatorBuilder: (_, _) => const AppHairline(),
              itemBuilder: (context, index) {
                final shot = shots[index];
                return _ShotGroup(
                  number: shot.index + 1,
                  title: shot.title,
                  density: density,
                  images: shot.images,
                  onApprove: onApprove,
                  onPreview: onPreview,
                  onEdit: onEdit,
                  onVersions: onVersions,
                  onVariation: () => onVariation(shot.index),
                  onDownload: onDownload,
                  onReport: onReport,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ShotGroup extends StatelessWidget {
  const _ShotGroup({
    required this.number,
    required this.title,
    required this.density,
    required this.images,
    required this.onApprove,
    required this.onPreview,
    required this.onEdit,
    required this.onVersions,
    required this.onVariation,
    required this.onDownload,
    required this.onReport,
  });

  final int number;
  final String title;
  final ShootReviewDensity density;
  final List<ShootImage> images;
  final ValueChanged<ShootImage> onApprove;
  final ValueChanged<ShootImage> onPreview;
  final ValueChanged<ShootImage> onEdit;
  final ValueChanged<ShootImage> onVersions;
  final VoidCallback onVariation;
  final ValueChanged<ShootImage> onDownload;
  final ValueChanged<ShootImage> onReport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                color: AppColors.black,
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: AppCardTitle('Shot $number: $title')),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            children: [
              AppOutlinedButton(
                label: 'Add Variation',
                icon: Icons.add,
                fitToContent: true,
                height: 30,
                onPressed: onVariation,
                iconSize: 16,
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppOutlinedButton(
                label: 'Approve all',
                fitToContent: true,
                height: 30,
                onPressed: () =>
                    images.where((image) => !image.approved).forEach(onApprove),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppOutlinedButton(
                label: 'Clear',
                fitToContent: true,
                height: 30,
                onPressed: () =>
                    images.where((image) => image.approved).forEach(onApprove),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: switch (density) {
                ShootReviewDensity.editorial => 500,
                ShootReviewDensity.dense => 205,
                ShootReviewDensity.grid => 125,
              },
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: density == ShootReviewDensity.grid ? .68 : .75,
            ),
            itemBuilder: (context, index) {
              final image = images[index];
              return _ResultTile(
                asset: image.url,
                label: 'V${image.variationIndex + 1}',
                approved: image.approved,
                compact: density == ShootReviewDensity.grid,
                onApprove: () => onApprove(image),
                onPreview: () => onPreview(image),
                onEdit: () => onEdit(image),
                onVersions: () => onVersions(image),
                onDownload: () => onDownload(image),
                onReport: () => onReport(image),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.asset,
    required this.label,
    required this.approved,
    required this.compact,
    required this.onApprove,
    required this.onPreview,
    required this.onEdit,
    required this.onVersions,
    required this.onDownload,
    required this.onReport,
  });

  final String asset;
  final String label;
  final bool approved;
  final bool compact;
  final VoidCallback onApprove;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onVersions;
  final VoidCallback onDownload;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: approved ? AppColors.black : AppColors.neutral200,
          width: 2,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(onTap: onPreview, child: AppAssetImage(asset)),
          Positioned(
            left: 7,
            top: 7,
            child: AppSmallOverlayButton(
              icon: Icons.download_outlined,
              onTap: onDownload,
            ),
          ),
          Positioned(
            right: 7,
            top: 7,
            child: AppSmallOverlayButton(
              icon: approved ? Icons.check : Icons.circle_outlined,
              onTap: onApprove,
            ),
          ),
          Positioned(
            left: 7,
            right: 7,
            bottom: 7,
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: AppTypography.bold,
                    shadows: [Shadow(blurRadius: 5)],
                  ),
                ),
                const Spacer(),
                if (!compact) ...[
                  AppSmallOverlayButton(
                    icon: Icons.auto_fix_high,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 5),
                  AppSmallOverlayButton(
                    icon: Icons.history,
                    onTap: onVersions,
                  ),
                  const SizedBox(width: 5),
                  AppSmallOverlayButton(
                    icon: Icons.flag_outlined,
                    onTap: onReport,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageReportNotice extends StatelessWidget {
  const _ImageReportNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSquareIcon(Icons.flag_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCardTitle('Something wrong with an image?'),
                SizedBox(height: 4),
                AppCaption(
                  'Tap the flag icon on an image to report it. Our team will review it and refund credits for a deformed product or model.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedShootDetail extends StatelessWidget {
  const _FailedShootDetail({
    required this.shoot,
    required this.onRerun,
    required this.onToast,
  });

  final ShootViewModel shoot;
  final VoidCallback onRerun;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return AppSpacedColumn(
      gap: 14,
      children: [
        AppPageHeader(
          title: shoot.name,
          body: 'Generated images for Mila',
          small: true,
        ),
        const AppBadge('Failed', kind: AppBadgeKind.warn),
        const AppAlert(
          kind: AppAlertKind.error,
          text: 'Job failed while processing. You can rerun it below.',
        ),
        AppCard(
          child: AppSpacedColumn(
            gap: 10,
            children: [
              const AppEyebrow('Support Ticket ID'),
              Text(
                shoot.supportTicketId ?? 'job_unknown',
                style: AppTypography.mono(fontSize: 12),
              ),
              AppOutlinedButton(
                label: 'Copy',
                fitToContent: true,
                height: 36,
                onPressed: () {
                  unawaited(
                    Clipboard.setData(
                      ClipboardData(
                        text: shoot.supportTicketId ?? 'job_unknown',
                      ),
                    ),
                  );
                  onToast('Ticket ID copied');
                },
              ),
            ],
          ),
        ),
        PrimaryButton(
          label: 'Rerun Job',
          icon: Icons.refresh,
          onPressed: onRerun,
        ),
        AppOutlinedButton(
          label: 'Contact Support',
          onPressed: () => context.go(AppRoutes.dashboardSupport),
        ),
      ],
    );
  }
}
