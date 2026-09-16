part of 'dashboard_welcome_block.dart';

class _DarkHero extends StatelessWidget {
  const _DarkHero({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    color: OverviewStyle.ink,
    child: IconTheme(
      data: const IconThemeData(color: AppColors.whiteAlpha60),
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: AppTypography.bodyFontFamily),
        child: child,
      ),
    ),
  );
}

class _WelcomeEyebrow extends StatelessWidget {
  const _WelcomeEyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: AppColors.whiteAlpha60,
      fontSize: 10,
      fontWeight: AppTypography.bold,
      letterSpacing: 2,
    ),
  );
}

class _ConsultHelper extends ConsumerWidget {
  const _ConsultHelper({required this.showRescue});
  final bool showRescue;

  @override
  Widget build(BuildContext context, WidgetRef ref) => OverviewHelperCard(
    key: const ValueKey('dashboard-consult-helper'),
    content: (
      label: 'Guided setup',
      title: showRescue
          ? "Stuck? We'll set it up with you."
          : 'Want a hand with your setup?',
      body: 'Free 30 minutes with an Onboarding Specialist. We handle the setup and walk you through your first shoot.',
      photo: 'assets/images/dashboard/guided_setup.jpg',
      action: 'Book a free call →',
    ),
    dismissTooltip: 'Dismiss onboarding call suggestion',
    onDismiss: () =>
        ref.read(dashboardWelcomeControllerProvider.notifier).dismissConsult(),
    onOpen: () => _showCalendly(context, ref),
  );
}

Future<void> _showCalendly(BuildContext context, WidgetRef ref) async {
  const calendly = 'https://calendly.com/lookatlas/customer-onboarding';
  await showAppBottomSheet<void>(
    context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Let’s build your studio together.',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close booking',
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Calendly opens securely in your browser. Return here after booking.',
              style: TextStyle(color: AppColors.neutral500),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Open Calendly',
              icon: Icons.open_in_new,
              onPressed: () async {
                try {
                  await ref
                      .read(externalUrlServiceProvider)
                      .openCalendly(Uri.parse(calendly));
                } on Object {
                  if (sheetContext.mounted) {
                    AppSnackBar.showError(
                      sheetContext,
                      'Calendly could not open. Please try again.',
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            AppOutlinedButton(
              label: 'I’ve booked my call',
              onPressed: () async {
                await ref
                    .read(dashboardWelcomeControllerProvider.notifier)
                    .confirmCallBooked();
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (context.mounted) {
                  AppSnackBar.show(
                    context,
                    'You’re booked. See you on the call.',
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _CampaignHero extends ConsumerStatefulWidget {
  const _CampaignHero({
    required this.welcome,
    required this.showRescue,
    required this.userId,
  });
  final DashboardWelcomeState welcome;
  final bool showRescue;
  final String userId;

  @override
  ConsumerState<_CampaignHero> createState() => _CampaignHeroState();
}

class _CampaignHeroState extends ConsumerState<_CampaignHero> {
  @override
  void initState() {
    super.initState();
    _trackShown();
  }

  @override
  void didUpdateWidget(covariant _CampaignHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.welcome.campaign?.jobId != widget.welcome.campaign?.jobId) {
      _trackShown();
    }
  }

  void _trackShown() {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            'welcome.flip_shown',
            properties: {'jobId': widget.welcome.campaign!.jobId},
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.welcome.campaign!;
    final key = (userId: widget.userId, jobId: campaign.jobId);
    final campaignState = ref.watch(dashboardCampaignControllerProvider(key));
    final campaignController = ref.read(
      dashboardCampaignControllerProvider(key).notifier,
    );
    final imagesById = {
      for (final image in campaignState.images) image.id: image,
    };
    final images = [
      for (final image in campaignState.images.take(10))
        CampaignShot(
          id: image.id,
          url: image.url.isEmpty ? null : image.url,
          approved: image.approved,
        ),
    ];
    final preferences = ref.watch(dashboardWelcomeControllerProvider);
    return _DarkHero(
      key: const ValueKey('dashboard-campaign-hero'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampaignFlipCard(
            jobId: campaign.jobId,
            images: images,
            checklistClaimed: widget.welcome.checklistRewardClaimedAt != null,
            claiming: preferences.claiming,
            imagesLoading: campaignState.isLoading,
            imageFailure: campaignState.failure,
            onRetryImages: campaignController.load,
            onClaim: () async {
              final success = await ref
                  .read(dashboardWelcomeControllerProvider.notifier)
                  .claimChecklist();
              if (!context.mounted) return;
              success
                  ? AppSnackBar.show(context, '20 free credits added.')
                  : AppSnackBar.showError(
                      context,
                      'Credits could not be claimed. Please try again.',
                    );
            },
            onToggleKeep: (shot, {required approved}) =>
                campaignController.toggleKeep(
                  imagesById[shot.id]!,
                  approved: approved,
                ),
            onOpenShoot: () => context.go(
              AppRoutes.shootDetail(campaign.jobId, fromDashboard: true),
            ),
            onOpenWorkshop: () => context.go(AppRoutes.workshop),
            onDone: () => ref
                .read(dashboardWelcomeControllerProvider.notifier)
                .dismissFlip(),
            showRescue: widget.showRescue
                ? _CampaignRescue(onBook: () => _showCalendly(context, ref))
                : null,
          ),
        ],
      ),
    );
  }
}

class _CampaignRescue extends StatelessWidget {
  const _CampaignRescue({required this.onBook});
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.whiteAlpha20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Stuck? We'll set it up with you.",
          style: TextStyle(
            color: AppColors.white,
            fontWeight: AppTypography.bold,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 14),
          child: Text(
            'Free 30 minutes with an Onboarding Specialist. We handle the '
            'setup and walk you through your first shoot.',
            style: TextStyle(color: AppColors.whiteAlpha60, fontSize: 12),
          ),
        ),
        AppOutlinedButton(
          label: 'Book a free call',
          foregroundColor: AppColors.white,
          borderColor: AppColors.whiteAlpha40,
          backgroundColor: AppColors.transparent,
          onPressed: onBook,
        ),
      ],
    ),
  );
}

class _OneTimeHero extends ConsumerWidget {
  const _OneTimeHero({
    required this.job,
    required this.offerActive,
    required this.offerExpiresAt,
  });
  final DashboardRecentJob job;
  final bool offerActive;
  final DateTime? offerExpiresAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    key: const ValueKey('dashboard-onetime-hero'),
    padding: const EdgeInsets.all(20),
    color: OverviewStyle.ink,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _RetentionThumbnails(job: job),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _WelcomeEyebrow('Your owned shoot'),
                  const SizedBox(height: 4),
                  Text(
                    'Your photos. Yours forever.',
                    style: OverviewStyle.serif(24, color: OverviewStyle.paper),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Full-resolution, no watermarks, full commercial rights. Open the shoot to download.',
          style: OverviewStyle.body(
            12,
            color: OverviewStyle.paper.withValues(alpha: .75),
          ),
        ),
        if (offerActive) ...[
          const SizedBox(height: 8),
          _RetentionOffer(expiresAt: offerExpiresAt),
        ],
        const SizedBox(height: 18),
        OverviewButton(
          'Open shoot to download',
          light: true,
          height: 38,
          icon: LucideIcons.download,
          onPressed: () =>
              context.push(AppRoutes.shootDetail(job.id, fromDashboard: true)),
        ),
        if (offerActive) ...[
          const SizedBox(height: 8),
          _RetentionUpsell(expiresAt: offerExpiresAt),
        ],
      ],
    ),
  );
}

class _RetentionOffer extends ConsumerWidget {
  const _RetentionOffer({required this.expiresAt});
  final DateTime? expiresAt;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = expiresAt == null
        ? null
        : ref.watch(retentionCountdownProvider(expiresAt!));
    final timer = remaining == null
        ? ''
        : ' for ${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: OverviewStyle.paper.withValues(alpha: .08),
        border: const Border(
          left: BorderSide(color: OverviewStyle.paper, width: 2),
        ),
      ),
      child: Text(
        remaining != null && remaining <= Duration.zero
            ? 'Your plan offer has ended.'
            : 'Your 20% off any plan is open$timer and includes 15 bonus credits.',
        style: OverviewStyle.body(
          11.5,
          color: OverviewStyle.paper.withValues(alpha: .95),
        ),
      ),
    );
  }
}

class _RetentionUpsell extends ConsumerWidget {
  const _RetentionUpsell({required this.expiresAt});
  final DateTime? expiresAt;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = expiresAt == null
        ? null
        : ref.watch(retentionCountdownProvider(expiresAt!));
    if (remaining != null && remaining <= Duration.zero) {
      return const SizedBox.shrink();
    }
    return OverviewButton(
      'Claim 20% off any plan →',
      outlined: true,
      height: 34,
      onPressed: () {
        unawaited(
          ref
              .read(analyticsServiceProvider)
              .track('upsell.dashboard_hero_clicked'),
        );
        unawaited(
          context.push<void>(
            '${AppRoutes.selectPlan}?upsell=onetime20&from=dashboard_hero',
          ),
        );
      },
    );
  }
}

class _RetentionThumbnails extends ConsumerWidget {
  const _RetentionThumbnails({required this.job});
  final DashboardRecentJob job;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var product = job.productThumbnail;
    var model = job.modelThumbnail;
    if (product.isEmpty || model.isEmpty) {
      final userId = ref.watch(
        authStateProvider.select((auth) => auth.value?.id),
      );
      if (userId != null) {
        final shoot = ref
            .watch(
              dashboardCampaignControllerProvider((
                userId: userId,
                jobId: job.id,
              )),
            )
            .job;
        product = product.isEmpty ? shoot?.productThumbnail ?? '' : product;
        model = model.isEmpty ? shoot?.modelThumbnail ?? '' : model;
      }
    }
    return SizedBox(
      width: 88,
      height: 48,
      child: Stack(
        children: [
          for (var index = 0; index < 2; index++)
            Positioned(
              left: index * 36,
              top: 0,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: OverviewStyle.paper, width: 2),
                ),
                child: OverviewImage(
                  index == 0 ? product : model,
                  label: index == 0 ? 'Your product' : 'Your model',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
