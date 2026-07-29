part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootProgress extends StatelessWidget {
  const _ShootProgress({required this.progress});

  final double progress;

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
              const Expanded(
                child: Text(
                  'Generating images...',
                  style: TextStyle(
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
          _ProgressBar(value: progress),
        ],
      ),
    );
  }
}

class _ShootSummary extends StatelessWidget {
  const _ShootSummary({required this.shoot, this.modelName});

  final _Shoot shoot;
  final String? modelName;

  @override
  Widget build(BuildContext context) {
    return _Stack(
      gap: 8,
      children: [
        _ShootStat(
          label: 'Product',
          title: shoot.name,
          caption: 'Selected product',
          asset: shoot.productAsset,
        ),
        _ShootStat(
          label: 'Model',
          title: modelName ?? 'Model',
          caption: 'Primary model',
          asset: shoot.modelAsset,
        ),
        _ShootStat(
          label: 'Created',
          title: shoot.date,
          caption: 'Shoot created',
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
          _Eyebrow(label),
          const SizedBox(height: 9),
          Row(
            children: [
              if (asset != null) ...[
                _AssetBox(asset!, width: 45, height: 45),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_CardTitle(title), _Caption(caption)],
                ),
              ),
            ],
          ),
        ],
      ),
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
                _SquareIcon(Icons.video_camera_back_outlined),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardTitle('Model Video'),
                    _Caption('AI-generated motion'),
                  ],
                ),
              ],
            ),
          ),
          const _Hairline(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const _SquareIcon(Icons.movie_creation_outlined),
                const SizedBox(height: 10),
                const _BodyText(
                  'Create an 8-second cinematic video from your best variation.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Generate Video',
                  icon: Icons.auto_awesome,
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
    required this.shots,
    required this.onApprove,
    required this.onPreview,
    required this.onEdit,
    required this.onVersions,
    required this.onVariation,
    required this.onDownload,
  });

  final bool isProcessing;
  final List<ShootShot> shots;
  final ValueChanged<ShootImage> onApprove;
  final ValueChanged<ShootImage> onPreview;
  final ValueChanged<ShootImage> onEdit;
  final ValueChanged<ShootImage> onVersions;
  final ValueChanged<int> onVariation;
  final ValueChanged<ShootImage> onDownload;

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
            child: _SectionTitle('Generated Images'),
          ),
          const _Hairline(),
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              child: Column(
                children: [
                  _SquareIcon(Icons.schedule),
                  SizedBox(height: 14),
                  _SectionTitle('Generating images...'),
                  SizedBox(height: 6),
                  _Caption('This may take a few minutes'),
                ],
              ),
            )
          else if (shots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: _Caption('No generated images are available yet.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shots.length,
              separatorBuilder: (_, _) => const _Hairline(),
              itemBuilder: (context, index) {
                final shot = shots[index];
                return _ShotGroup(
                  number: shot.index + 1,
                  title: shot.title,
                  images: shot.images,
                  onApprove: onApprove,
                  onPreview: onPreview,
                  onEdit: onEdit,
                  onVersions: onVersions,
                  onVariation: () => onVariation(shot.index),
                  onDownload: onDownload,
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
    required this.images,
    required this.onApprove,
    required this.onPreview,
    required this.onEdit,
    required this.onVersions,
    required this.onVariation,
    required this.onDownload,
  });

  final int number;
  final String title;
  final List<ShootImage> images;
  final ValueChanged<ShootImage> onApprove;
  final ValueChanged<ShootImage> onPreview;
  final ValueChanged<ShootImage> onEdit;
  final ValueChanged<ShootImage> onVersions;
  final VoidCallback onVariation;
  final ValueChanged<ShootImage> onDownload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
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
              Expanded(child: _CardTitle('Shot $number: $title')),
              AppOutlinedButton(
                label: 'Add',
                icon: Icons.add,
                fitToContent: true,
                height: 36,
                onPressed: onVariation,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final image = images[index];
              return _ResultTile(
                asset: image.url,
                label: 'V${image.variationIndex + 1}',
                approved: image.approved,
                onApprove: () => onApprove(image),
                onPreview: () => onPreview(image),
                onEdit: () => onEdit(image),
                onVersions: () => onVersions(image),
                onDownload: () => onDownload(image),
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
    required this.onApprove,
    required this.onPreview,
    required this.onEdit,
    required this.onVersions,
    required this.onDownload,
  });

  final String asset;
  final String label;
  final bool approved;
  final VoidCallback onApprove;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onVersions;
  final VoidCallback onDownload;

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
          InkWell(onTap: onPreview, child: _AssetImage(asset)),
          Positioned(
            left: 7,
            top: 7,
            child: _SmallOverlayButton(
              icon: Icons.download_outlined,
              onTap: onDownload,
            ),
          ),
          Positioned(
            right: 7,
            top: 7,
            child: _SmallOverlayButton(
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
                _SmallOverlayButton(icon: Icons.auto_fix_high, onTap: onEdit),
                const SizedBox(width: 5),
                _SmallOverlayButton(icon: Icons.history, onTap: onVersions),
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

  final _Shoot shoot;
  final VoidCallback onRerun;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _Stack(
      gap: 14,
      children: [
        _PageHeader(
          title: shoot.name,
          body: 'Generated images for Mila',
          small: true,
        ),
        const _Badge('Failed', kind: _BadgeKind.warn),
        const _Alert(
          kind: _AlertKind.error,
          text: 'Job failed while processing. You can rerun it below.',
        ),
        _Card(
          child: _Stack(
            gap: 10,
            children: [
              const _Eyebrow('Support Ticket ID'),
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
