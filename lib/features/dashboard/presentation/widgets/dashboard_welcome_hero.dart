part of 'dashboard_welcome_block.dart';

const _welcomeSteps = <DashboardWelcomeStepId, (String, String, String)>{
  DashboardWelcomeStepId.product: (
    'Add your product',
    'A few clear photos on a plain background',
    AppRoutes.dashboardProducts,
  ),
  DashboardWelcomeStepId.calibration: (
    'Calibrate sizes',
    'Tell us how big your piece is',
    AppRoutes.dashboardProducts,
  ),
  DashboardWelcomeStepId.angles: (
    'Label your angles',
    'Label each photo front, side, detail',
    AppRoutes.dashboardProducts,
  ),
  DashboardWelcomeStepId.model: (
    'Create your model',
    'Build once, use in every shoot',
    AppRoutes.dashboardModels,
  ),
  DashboardWelcomeStepId.direction: (
    'Choose your direction',
    'Directors set the mood of the shoot',
    AppRoutes.dashboardShoots,
  ),
  DashboardWelcomeStepId.firstShoot: (
    'Run your first shoot',
    'First photos land in minutes',
    AppRoutes.dashboardShoots,
  ),
};

class _StudioSetupHero extends ConsumerWidget {
  const _StudioSetupHero({required this.welcome});

  final DashboardWelcomeState welcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complete = welcome.checklistComplete;
    return _DarkHero(
      key: const ValueKey('dashboard-studio-setup'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!complete)
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  onPressed: () => ref
                      .read(dashboardWelcomeControllerProvider.notifier)
                      .collapse(skipped: true),
                  child: const Text('Skip for now'),
                ),
              IconButton(
                tooltip: 'Collapse studio setup',
                onPressed: () => ref
                    .read(dashboardWelcomeControllerProvider.notifier)
                    .collapse(),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
            ],
          ),
          const _WelcomeEyebrow('Welcome to Look Atlas'),
          const Text.rich(
            TextSpan(
              text: 'Let’s build your ',
              children: [
                TextSpan(
                  text: 'studio',
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
              height: 1.02,
              letterSpacing: -1.1,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Six steps and your first campaign is live.',
            style: TextStyle(color: AppColors.whiteAlpha70, fontSize: 14),
          ),
          _DashboardStudioScene(welcome: welcome),
          _Checklist(welcome: welcome),
        ],
      ),
    );
  }
}

class _DashboardStudioScene extends StatelessWidget {
  const _DashboardStudioScene({required this.welcome});

  final DashboardWelcomeState welcome;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 190,
    child: StudioSceneAnimation(
      key: const ValueKey('dashboard-studio-scene'),
      progress: StudioProgress(
        addProduct: welcome.steps[DashboardWelcomeStepId.product] ?? false,
        calibrate:
            (welcome.steps[DashboardWelcomeStepId.calibration] ?? false) &&
            !welcome.calibrationOptional,
        calibrationOptional: welcome.calibrationOptional,
        pickAngles: welcome.steps[DashboardWelcomeStepId.angles] ?? false,
        createModel: welcome.steps[DashboardWelcomeStepId.model] ?? false,
        chooseDirection:
            welcome.steps[DashboardWelcomeStepId.direction] ?? false,
        runShoot: welcome.steps[DashboardWelcomeStepId.firstShoot] ?? false,
      ),
      height: 190,
    ),
  );
}

class _Checklist extends ConsumerWidget {
  const _Checklist({required this.welcome});

  final DashboardWelcomeState welcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = welcome.completedCount;
    final claiming = ref.watch(
      dashboardWelcomeControllerProvider.select((value) => value.claiming),
    );
    final activeStep = DashboardWelcomeStepId.values
        .where((step) => welcome.steps[step] != true)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _WelcomeEyebrow('Studio setup'),
            Text(
              '$completed of 6',
              style: const TextStyle(
                color: AppColors.whiteAlpha60,
                fontSize: 12,
              ),
            ),
          ],
        ),
        ClipRect(
          child: LinearProgressIndicator(
            minHeight: 3,
            value: completed / 6,
            color: AppColors.white,
            backgroundColor: AppColors.whiteAlpha15,
          ),
        ),
        const SizedBox(height: 10),
        for (final entry in _welcomeSteps.entries)
          _ChecklistRow(
            index: entry.key.index,
            content: entry.value,
            done: welcome.steps[entry.key] ?? false,
            active: entry.key == activeStep,
            onGuide: () => showDashboardStepGuide(context, ref, entry.key),
          ),
        if (welcome.checklistComplete &&
            welcome.checklistRewardClaimedAt == null)
          _ClaimBox(
            claiming: claiming,
            onClaim: () async {
              final success = await ref
                  .read(dashboardWelcomeControllerProvider.notifier)
                  .claimChecklist();
              if (context.mounted) {
                final message = success
                    ? '20 free credits added.'
                    : 'Credits could not be claimed. Please try again.';
                success
                    ? AppSnackBar.show(context, message)
                    : AppSnackBar.showError(context, message);
              }
            },
          )
        else if (!welcome.checklistComplete)
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Icon(
                  Icons.diamond_outlined,
                  size: 17,
                  color: AppColors.whiteAlpha50,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Finish all 6 steps and get 20 free credits.',
                    style: TextStyle(
                      color: AppColors.whiteAlpha50,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.index,
    required this.content,
    required this.done,
    required this.active,
    required this.onGuide,
  });

  final int index;
  final (String, String, String) content;
  final bool done;
  final bool active;
  final VoidCallback onGuide;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      decoration: BoxDecoration(
        color: active ? AppColors.whiteAlpha06 : null,
        border: Border(
          left: BorderSide(
            color: active ? AppColors.white : AppColors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? AppColors.white : null,
              border: Border.all(
                color: done ? AppColors.white : AppColors.whiteAlpha30,
              ),
            ),
            child: done
                ? const Icon(Icons.check, size: 15, color: AppColors.black)
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.whiteAlpha50,
                      fontSize: 10,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.$1,
                  style: TextStyle(
                    color: done ? AppColors.whiteAlpha50 : AppColors.white,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.whiteAlpha50,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                if (active)
                  Text(
                    content.$2,
                    style: const TextStyle(
                      color: AppColors.whiteAlpha60,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (!done)
            OutlinedButton(
              onPressed: onGuide,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(76, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                side: const BorderSide(color: AppColors.whiteAlpha30),
                foregroundColor: AppColors.whiteAlpha80,
              ),
              child: const Text(
                'SHOW ME',
                style: TextStyle(fontSize: 10, letterSpacing: .8),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClaimBox extends StatelessWidget {
  const _ClaimBox({required this.claiming, required this.onClaim});
  final bool claiming;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 18),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.whiteAlpha30),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Your studio is built.',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: AppTypography.bold,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 3, bottom: 13),
          child: Text(
            '20 free credits are waiting for you.',
            style: TextStyle(color: AppColors.whiteAlpha60, fontSize: 12),
          ),
        ),
        PrimaryButton(
          label: 'Claim 20 credits',
          icon: Icons.diamond_outlined,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          isLoading: claiming,
          onPressed: claiming ? null : onClaim,
        ),
      ],
    ),
  );
}
