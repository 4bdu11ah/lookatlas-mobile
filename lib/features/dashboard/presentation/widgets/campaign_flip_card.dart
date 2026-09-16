import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/campaign_selection_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/models/campaign_shot.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

export 'package:look_atlas/features/dashboard/presentation/models/campaign_shot.dart';

class CampaignFlipCard extends ConsumerWidget {
  const CampaignFlipCard({
    required this.jobId,
    required this.images,
    required this.checklistClaimed,
    required this.claiming,
    required this.imagesLoading,
    required this.onClaim,
    required this.onToggleKeep,
    required this.onOpenShoot,
    required this.onOpenWorkshop,
    required this.onDone,
    this.imageFailure,
    this.onRetryImages,
    this.showRescue,
    super.key,
  });

  final String jobId;
  final List<CampaignShot> images;
  final bool checklistClaimed;
  final bool claiming;
  final bool imagesLoading;
  final Failure? imageFailure;
  final VoidCallback onClaim;
  final ToggleCampaignShot onToggleKeep;
  final VoidCallback onOpenShoot;
  final VoidCallback onOpenWorkshop;
  final VoidCallback onDone;
  final VoidCallback? onRetryImages;
  final Widget? showRescue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(campaignSelectionControllerProvider(jobId));
    final controller = ref.read(
      campaignSelectionControllerProvider(jobId).notifier,
    );
    bool approved(CampaignShot shot) =>
        selection.overrides[shot.id] ?? shot.approved;
    final keptCount = images.where(approved).length;
    Future<void> toggle(CampaignShot shot) async {
      final failure = await controller.toggle(shot, images, onToggleKeep);
      if (failure != null && context.mounted) {
        AppSnackBar.showError(
          context,
          failure is ValidationFailure
              ? failure.message
              : "Couldn't save that. Try again.",
        );
      }
    }

    return Semantics(
      container: true,
      label: 'First campaign for shoot $jobId',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CampaignHeading(onOpenWorkshop: onOpenWorkshop),
          if (!checklistClaimed) ...[
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Studio built. Claim your 20 free credits',
              height: 38,
              iconSize: 14,
              textStyle: OverviewStyle.body(12, bold: true),
              icon: Icons.card_giftcard,
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.black,
              isLoading: claiming,
              onPressed: claiming ? null : onClaim,
            ),
          ],
          const SizedBox(height: 16),
          _CampaignImages(
            images: images.take(10).toList(growable: false),
            loading: imagesLoading,
            failure: imageFailure,
            approved: approved,
            inflight: selection.inflight,
            onToggle: toggle,
            onRetry: onRetryImages,
          ),
          const SizedBox(height: 16),
          _CampaignActions(
            keptCount: keptCount,
            checklistClaimed: checklistClaimed,
            onOpenShoot: onOpenShoot,
            onOpenWorkshop: onOpenWorkshop,
            onDone: onDone,
          ),
          if (showRescue case final rescue?) ...[
            const SizedBox(height: 20),
            rescue,
          ],
        ],
      ),
    );
  }
}

class _CampaignActions extends StatelessWidget {
  const _CampaignActions({
    required this.keptCount,
    required this.checklistClaimed,
    required this.onOpenShoot,
    required this.onOpenWorkshop,
    required this.onDone,
  });
  final int keptCount;
  final bool checklistClaimed;
  final VoidCallback onOpenShoot;
  final VoidCallback onOpenWorkshop;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PrimaryButton(
        label: keptCount > 0
            ? 'Open shoot ($keptCount kept)'
            : 'Open shoot (0 kept)',
        height: 38,
        iconSize: 14,
        textStyle: OverviewStyle.body(12, bold: true),
        icon: Icons.download_outlined,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        onPressed: onOpenShoot,
      ),
      const SizedBox(height: 8),
      AppOutlinedButton(
        label: 'Fix a small flaw in Workshop →',
        height: 34,
        textStyle: OverviewStyle.body(11, bold: true),
        foregroundColor: AppColors.white,
        borderColor: AppColors.whiteAlpha40,
        backgroundColor: AppColors.transparent,
        onPressed: onOpenWorkshop,
      ),
      if (checklistClaimed) ...[
        const SizedBox(height: 24),
        const Divider(color: AppColors.whiteAlpha15, height: 1),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onDone,
            child: const Text(
              "I'm all set, hide this",
              style: TextStyle(
                color: AppColors.whiteAlpha50,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.whiteAlpha50,
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class _CampaignHeading extends StatelessWidget {
  const _CampaignHeading({required this.onOpenWorkshop});

  final VoidCallback onOpenWorkshop;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'YOUR FIRST CAMPAIGN',
        style: TextStyle(
          color: AppColors.whiteAlpha50,
          fontSize: 10,
          fontWeight: AppTypography.bold,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 6),
      const Text.rich(
        TextSpan(
          text: 'Your first shoot is done. Pick your ',
          children: [
            TextSpan(
              text: 'heroes',
              style: TextStyle(
                fontFamily: 'InstrumentSerif',
                fontStyle: FontStyle.italic,
                fontWeight: AppTypography.regular,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
        style: TextStyle(
          color: AppColors.white,
          fontFamily: 'InstrumentSerif',
          fontSize: 34,
          height: 1.05,
          letterSpacing: -1,
          fontWeight: AppTypography.regular,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Keep your 3 favorite shots. If one is almost right, ',
            style: TextStyle(
              color: AppColors.whiteAlpha70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          Semantics(
            button: true,
            link: true,
            child: InkWell(
              onTap: onOpenWorkshop,
              child: const Text(
                'fix it in Workshop',
                style: TextStyle(
                  color: AppColors.white,
                  height: 1.5,
                  fontWeight: AppTypography.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.white,
                ),
              ),
            ),
          ),
          const Text(
            ' instead of reshooting.',
            style: TextStyle(
              color: AppColors.whiteAlpha70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    ],
  );
}

class _CampaignImages extends StatelessWidget {
  const _CampaignImages({
    required this.images,
    required this.loading,
    required this.failure,
    required this.approved,
    required this.inflight,
    required this.onToggle,
    required this.onRetry,
  });

  final List<CampaignShot> images;
  final bool loading;
  final Failure? failure;
  final bool Function(CampaignShot) approved;
  final Set<String> inflight;
  final ValueChanged<CampaignShot> onToggle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final kept = images.where(approved).length;
    const itemSize = 96.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          children: [
            const Text(
              'TAP TO KEEP',
              style: TextStyle(
                color: AppColors.whiteAlpha40,
                fontSize: 10,
                fontWeight: AppTypography.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              '$kept of 3 picked',
              style: const TextStyle(
                color: AppColors.whiteAlpha60,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (loading && images.isEmpty)
          SizedBox(
            height: itemSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, _) => const SizedBox.square(
                dimension: itemSize,
                child: ShimmerBox(),
              ),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
            ),
          )
        else if (failure != null && images.isEmpty)
          _CampaignImagesError(onRetry: onRetry)
        else if (images.isEmpty)
          const Text(
            'Open the shoot to choose your favorites.',
            style: TextStyle(color: AppColors.whiteAlpha60),
          )
        else
          SizedBox(
            height: itemSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final shot = images[index];
                return _CampaignImageTile(
                  key: ValueKey(shot.id),
                  shot: shot,
                  size: itemSize,
                  selected: approved(shot),
                  loading: inflight.contains(shot.id),
                  onTap: () => onToggle(shot),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 8),
            ),
          ),
      ],
    );
  }
}

class _CampaignImageTile extends StatelessWidget {
  const _CampaignImageTile({
    required this.shot,
    required this.size,
    required this.selected,
    required this.loading,
    required this.onTap,
    super.key,
  });

  final CampaignShot shot;
  final double size;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? 'Kept campaign shot' : 'Campaign shot',
      child: InkWell(
        onTap: loading ? null : onTap,
        child: AnimatedOpacity(
          opacity: selected ? 1 : .8,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: Container(
            width: size,
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.white : AppColors.whiteAlpha20,
                width: 2,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (shot.url case final url?)
                  AppImage(
                    url,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    semanticLabel: 'Campaign result',
                    errorWidget: const ColoredBox(
                      color: AppColors.whiteAlpha10,
                    ),
                  )
                else
                  const ColoredBox(color: AppColors.whiteAlpha10),
                if (selected)
                  const Positioned(
                    right: 4,
                    top: 4,
                    child: ColoredBox(
                      color: AppColors.white,
                      child: SizedBox.square(
                        dimension: 18,
                        child: Icon(
                          Icons.check,
                          color: AppColors.black,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                if (loading)
                  const ColoredBox(
                    color: AppColors.blackAlpha60,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      ),
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

class _CampaignImagesError extends StatelessWidget {
  const _CampaignImagesError({required this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Text(
          'Campaign images could not load.',
          style: TextStyle(color: AppColors.whiteAlpha60),
        ),
      ),
      TextButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}
