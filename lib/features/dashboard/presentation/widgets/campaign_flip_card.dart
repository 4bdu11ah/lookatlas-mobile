import 'package:flutter/material.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

@immutable
class CampaignShot {
  const CampaignShot({
    required this.id,
    required this.url,
    required this.approved,
  });

  final String id;
  final String? url;
  final bool approved;
}

typedef ToggleCampaignShot =
    Future<Failure?> Function(CampaignShot shot, {required bool approved});

class CampaignFlipCard extends StatefulWidget {
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
  State<CampaignFlipCard> createState() => CampaignFlipCardState();
}

@visibleForTesting
class CampaignFlipCardState extends State<CampaignFlipCard> {
  final Set<String> _inflight = {};
  final Map<String, bool> _approvedOverrides = {};

  bool _approved(CampaignShot shot) =>
      _approvedOverrides[shot.id] ?? shot.approved;

  int get keptCount => widget.images.where(_approved).length;

  Future<void> _toggle(CampaignShot shot) async {
    if (_inflight.contains(shot.id)) return;
    final next = !_approved(shot);
    setState(() {
      _inflight.add(shot.id);
      _approvedOverrides[shot.id] = next;
    });
    final failure = await widget.onToggleKeep(shot, approved: next);
    if (!mounted) return;
    if (failure != null) {
      setState(() => _approvedOverrides[shot.id] = !next);
      AppSnackBar.showError(context, "Couldn't save that. Try again.");
    }
    setState(() => _inflight.remove(shot.id));
  }

  @override
  void didUpdateWidget(covariant CampaignFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.images.map((shot) => shot.id).toSet();
    _approvedOverrides.removeWhere((id, _) => !currentIds.contains(id));
    for (final shot in widget.images) {
      final local = _approvedOverrides[shot.id];
      if (!_inflight.contains(shot.id) && local == shot.approved) {
        _approvedOverrides.remove(shot.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'First campaign for shoot ${widget.jobId}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CampaignHeading(onOpenWorkshop: widget.onOpenWorkshop),
        if (!widget.checklistClaimed) ...[
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Studio built. Claim your 20 free credits',
            icon: Icons.card_giftcard,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
            isLoading: widget.claiming,
            onPressed: widget.claiming ? null : widget.onClaim,
          ),
        ],
        const SizedBox(height: 24),
        _CampaignImages(
          images: widget.images.take(10).toList(growable: false),
          loading: widget.imagesLoading,
          failure: widget.imageFailure,
          approved: _approved,
          inflight: _inflight,
          onToggle: _toggle,
          onRetry: widget.onRetryImages,
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: keptCount > 0
              ? 'Open shoot ($keptCount kept)'
              : 'Open the shoot',
          icon: Icons.download_outlined,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          onPressed: widget.onOpenShoot,
        ),
        const SizedBox(height: 10),
        AppOutlinedButton(
          label: 'Fix a small flaw',
          icon: Icons.auto_fix_high,
          foregroundColor: AppColors.white,
          borderColor: AppColors.whiteAlpha40,
          backgroundColor: AppColors.transparent,
          onPressed: widget.onOpenWorkshop,
        ),
        if (widget.checklistClaimed) ...[
          const SizedBox(height: 24),
          const Divider(color: AppColors.whiteAlpha15, height: 1),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.onDone,
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
        if (widget.showRescue case final rescue?) ...[
          const SizedBox(height: 20),
          rescue,
        ],
      ],
    ),
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
      const SizedBox(height: 12),
      const Text.rich(
        TextSpan(
          text: 'Your first shoot is done. Pick your ',
          children: [
            TextSpan(
              text: 'heroes',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontWeight: AppTypography.regular,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
        style: TextStyle(
          color: AppColors.white,
          fontSize: 32,
          height: 1.05,
          letterSpacing: -1,
          fontWeight: AppTypography.bold,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Keep your 3 favorite shots. If one is almost right, ',
            style: TextStyle(color: AppColors.whiteAlpha70, height: 1.5),
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
            style: TextStyle(color: AppColors.whiteAlpha70, height: 1.5),
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
    final itemSize = MediaQuery.sizeOf(context).width >= 400 ? 112.0 : 96.0;
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
              style: const TextStyle(color: AppColors.whiteAlpha60),
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
              itemBuilder: (_, _) => SizedBox.square(
                dimension: itemSize,
                child: const ShimmerBox(),
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
                    right: 6,
                    top: 6,
                    child: ColoredBox(
                      color: AppColors.white,
                      child: SizedBox.square(
                        dimension: 22,
                        child: Icon(
                          Icons.check,
                          color: AppColors.black,
                          size: 17,
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
