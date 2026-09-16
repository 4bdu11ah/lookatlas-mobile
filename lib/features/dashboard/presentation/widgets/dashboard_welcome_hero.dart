part of 'dashboard_welcome_block.dart';

const _welcomeSteps = <DashboardWelcomeStepId, (String, String)>{
  DashboardWelcomeStepId.product: (
    'Add your first product',
    'A few clear photos on a plain background.',
  ),
  DashboardWelcomeStepId.calibration: (
    'Calibrate product fit',
    'Optional for non-apparel products.',
  ),
  DashboardWelcomeStepId.angles: (
    'Select camera angles',
    'Label your front, side, and detail views.',
  ),
  DashboardWelcomeStepId.model: (
    'Choose your model',
    'Select from house models or upload custom talent.',
  ),
  DashboardWelcomeStepId.direction: ('Set creative direction', ''),
  DashboardWelcomeStepId.firstShoot: ('Generate your first shoot', ''),
};

class _StudioSetupHero extends ConsumerWidget {
  const _StudioSetupHero({required this.welcome});
  final DashboardWelcomeState welcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    key: const ValueKey('dashboard-studio-setup'),
    decoration: BoxDecoration(border: Border.all(color: OverviewStyle.line)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: OverviewStyle.ink,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'WELCOME TO LOOK ATLAS',
                      style: OverviewStyle.body(
                        10,
                        bold: true,
                        color: OverviewStyle.paper.withValues(alpha: .6),
                      ).copyWith(letterSpacing: 1),
                    ),
                  ),
                  _SetupControl(
                    label: 'Skip',
                    tooltip: 'Skip studio setup for now',
                    onPressed: () => ref
                        .read(dashboardWelcomeControllerProvider.notifier)
                        .collapse(skipped: true),
                  ),
                  const SizedBox(width: 6),
                  _SetupControl(
                    label: '',
                    icon: LucideIcons.chevronUp,
                    tooltip: 'Collapse studio setup',
                    onPressed: () => ref
                        .read(dashboardWelcomeControllerProvider.notifier)
                        .collapse(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text.rich(
                const TextSpan(
                  text: "Let's build your ",
                  children: [
                    TextSpan(
                      text: 'studio',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
                style: OverviewStyle.serif(
                  38,
                  height: 1.02,
                  color: OverviewStyle.paper,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Six clear moves take you from a product in your library to a finished first campaign.',
                style: OverviewStyle.body(
                  12,
                  color: OverviewStyle.paper.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 16),
              OverviewStudioScene(welcome: welcome),
            ],
          ),
        ),
        _Checklist(welcome: welcome),
      ],
    ),
  );
}

class _SetupControl extends StatelessWidget {
  const _SetupControl({
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.icon,
  });
  final IconData? icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: OverviewStyle.paper.withValues(alpha: .2)),
        ),
        child: icon != null
            ? Icon(
                icon,
                size: 12,
                color: OverviewStyle.paper.withValues(alpha: .8),
              )
            : Text(
                label.toUpperCase(),
                style: OverviewStyle.body(
                  9,
                  bold: true,
                  color: OverviewStyle.paper.withValues(alpha: .8),
                ),
              ),
      ),
    ),
  );
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.welcome});
  final DashboardWelcomeState welcome;
  @override
  Widget build(BuildContext context) {
    final activeStep = DashboardWelcomeStepId.values
        .where((step) => welcome.steps[step] != true)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OverviewLabel('Studio setup'),
                    const SizedBox(height: 4),
                    Text(
                      '${welcome.completedCount} of 6',
                      style: OverviewStyle.serif(24, height: 1),
                    ),
                  ],
                ),
              ),
              Text(
                '${(welcome.completedCount / 6 * 100).round()}% complete',
                style: OverviewStyle.body(10, bold: true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: welcome.completedCount / 6,
            minHeight: 3,
            color: OverviewStyle.ink,
            backgroundColor: OverviewStyle.soft,
            borderRadius: BorderRadius.zero,
          ),
          const SizedBox(height: 14),
          for (final entry in _welcomeSteps.entries)
            _ChecklistRow(
              step: entry.key,
              content: entry.value,
              done: welcome.steps[entry.key] ?? false,
              active: entry.key == activeStep,
              optional:
                  entry.key == DashboardWelcomeStepId.calibration &&
                  welcome.calibrationOptional,
            ),
          const SizedBox(height: 14),
          _ChecklistReward(welcome: welcome),
        ],
      ),
    );
  }
}

class _ChecklistRow extends ConsumerWidget {
  const _ChecklistRow({
    required this.step,
    required this.content,
    required this.done,
    required this.active,
    required this.optional,
  });
  final DashboardWelcomeStepId step;
  final (String, String) content;
  final bool done;
  final bool active;
  final bool optional;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    decoration: BoxDecoration(
      color: active ? OverviewStyle.soft.withValues(alpha: .7) : null,
      border: Border(
        top: const BorderSide(color: OverviewStyle.line),
        left: BorderSide(
          width: active ? 2 : 0,
          color: active ? OverviewStyle.ink : Colors.transparent,
        ),
        bottom: step == DashboardWelcomeStepId.firstShoot
            ? const BorderSide(color: OverviewStyle.line)
            : BorderSide.none,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? OverviewStyle.ink : null,
            border: Border.all(
              color: done ? OverviewStyle.ink : OverviewStyle.line,
            ),
          ),
          child: done
              ? const Icon(
                  LucideIcons.check,
                  size: 13,
                  color: OverviewStyle.paper,
                )
              : Text(
                  (step.index + 1).toString().padLeft(2, '0'),
                  style: OverviewStyle.body(10, bold: true),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.$1,
                style:
                    OverviewStyle.body(
                      12,
                      bold: true,
                      color: done ? OverviewStyle.muted : OverviewStyle.ink,
                    ).copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
              ),
              if (optional || (!done && active && content.$2.isNotEmpty)) ...[
                const SizedBox(height: 2),
                Text(
                  optional ? 'Skipped, no apparel detected.' : content.$2,
                  style: OverviewStyle.body(10),
                ),
              ],
            ],
          ),
        ),
        if (!done) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () => showDashboardStepGuide(context, ref, step),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: OverviewStyle.line),
              ),
              child: Text(
                'SHOW ME',
                style: OverviewStyle.body(
                  9,
                  bold: true,
                ).copyWith(letterSpacing: .45),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ChecklistReward extends ConsumerWidget {
  const _ChecklistReward({required this.welcome});
  final DashboardWelcomeState welcome;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claiming = ref.watch(
      dashboardWelcomeControllerProvider.select((value) => value.claiming),
    );
    final claimed = welcome.checklistRewardClaimedAt != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OverviewStyle.soft,
        border: Border.all(color: OverviewStyle.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            claimed
                ? 'Your 20 free credits have been claimed.'
                : 'Finish all 6 steps for 20 free credits.',
            style: OverviewStyle.body(12, bold: true, color: OverviewStyle.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Your credits are added to your balance as soon as your first campaign renders.',
            style: OverviewStyle.body(10.5),
          ),
          if (!claimed) ...[
            const SizedBox(height: 10),
            OverviewButton(
              claiming
                  ? 'Claiming reward…'
                  : welcome.checklistComplete
                  ? 'Claim reward'
                  : 'Claim reward when ready',
              height: 36,
              icon: LucideIcons.gift,
              onPressed: claiming || !welcome.checklistComplete
                  ? null
                  : () async {
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
            ),
          ],
        ],
      ),
    );
  }
}
