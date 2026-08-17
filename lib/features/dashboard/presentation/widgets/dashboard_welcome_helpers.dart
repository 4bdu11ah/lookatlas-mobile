part of 'dashboard_welcome_block.dart';

class _DarkHero extends StatelessWidget {
  const _DarkHero({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    color: AppColors.black,
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
  Widget build(BuildContext context, WidgetRef ref) => Container(
    key: const ValueKey('dashboard-consult-helper'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SchoolSquareIcon(
              icon: Icons.phone_outlined,
              size: 44,
              inverted: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showRescue
                        ? "Stuck? We'll set it up with you."
                        : 'Want a hand with your setup?',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Free 30 minutes with an Onboarding Specialist. We handle '
                    'the setup and walk you through your first shoot.',
                    style: TextStyle(color: AppColors.neutral500, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 58),
          child: Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  label: 'Book a free call',
                  height: 40,
                  onPressed: () => _showCalendly(context, ref),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss onboarding call suggestion',
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                onPressed: () => ref
                    .read(dashboardWelcomeControllerProvider.notifier)
                    .dismissConsult(),
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.neutral400,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
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
                  icon: const Icon(Icons.close),
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
          _DashboardStudioScene(welcome: widget.welcome),
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

class _OneTimeHero extends ConsumerStatefulWidget {
  const _OneTimeHero({
    required this.job,
    required this.offerActive,
    required this.offerExpiresAt,
  });
  final DashboardRecentJob job;
  final bool offerActive;
  final DateTime? offerExpiresAt;

  @override
  ConsumerState<_OneTimeHero> createState() => _OneTimeHeroState();
}

class _OneTimeHeroState extends ConsumerState<_OneTimeHero> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.offerExpiresAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _DarkHero(
    key: const ValueKey('dashboard-onetime-hero'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final source in [
              widget.job.productThumbnail,
              widget.job.modelThumbnail,
            ])
              if (source.isNotEmpty)
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: AppImage(source, fit: BoxFit.cover),
                ),
          ],
        ),
        const SizedBox(height: 18),
        const _WelcomeEyebrow('Your shoot'),
        const Text(
          'Your photos. Yours forever.',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 32,
            height: 1.02,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Full-resolution, no watermarks, full commercial rights. Open the shoot to download.',
          style: TextStyle(color: AppColors.whiteAlpha70),
        ),
        if (widget.offerActive) ...[
          const SizedBox(height: 10),
          Text(
            _offerCopy(),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Open shoot',
          icon: Icons.download_outlined,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          onPressed: () => unawaited(
            context.push<void>(AppRoutes.shootDetail(widget.job.id)),
          ),
        ),
        if (widget.offerActive) ...[
          const SizedBox(height: 10),
          AppOutlinedButton(
            label: 'Claim 20% off',
            icon: Icons.arrow_forward,
            iconAlignment: IconAlignment.end,
            foregroundColor: AppColors.white,
            borderColor: AppColors.whiteAlpha40,
            backgroundColor: AppColors.transparent,
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
          ),
        ],
      ],
    ),
  );

  String _offerCopy() {
    final expiresAt = widget.offerExpiresAt;
    if (expiresAt == null) {
      return 'Your 20% off any plan is open, with 100 bonus credits.';
    }
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) return 'Your plan offer has ended.';
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return 'Your 20% off any plan is open. $hours:$minutes:$seconds left '
        '(+100 bonus credits).';
  }
}
