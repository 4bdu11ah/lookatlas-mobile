part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _openSubscriptionDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  ref.read(_billingControllerProvider.notifier).preparePlans();
  await _showBillingDialog<void>(
    context: context,
    maxWidth: 430,
    builder: (_) => const _BillingSubscriptionDialog(),
  );
}

class _BillingSubscriptionDialog extends ConsumerWidget {
  const _BillingSubscriptionDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_billingControllerProvider);
    final controller = ref.read(_billingControllerProvider.notifier);
    return _BillingModal(
      title: 'Modify Subscription',
      subtitle: 'Choose a plan that fits your needs',
      onClose: () => Navigator.pop(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.cancellationScheduled) ...[
            const _BillingNotice(
              text:
                  'Your subscription is scheduled to cancel on Aug 1, 2026. Changing your plan now will resume your subscription.',
            ),
            const SizedBox(height: 24),
          ],
          _BillingCycleSelector(
            selected: state.selectedCycle,
            onSelect: controller.selectCycle,
          ),
          const SizedBox(height: 24),
          for (var index = 0; index < _BillingPlan.values.length; index++) ...[
            _BillingPlanOption(
              id: _BillingPlan.values[index],
              details: _billingPlans[_BillingPlan.values[index]]!,
              cycle: state.selectedCycle,
              samePlan: state.currentPlan == _BillingPlan.values[index],
              current:
                  state.currentPlan == _BillingPlan.values[index] &&
                  state.currentCycle == state.selectedCycle,
              onSelect: () async {
                final changed = await _showPlanConfirmation(
                  context,
                  ref,
                  _BillingPlan.values[index],
                );
                controller.resetAction();
                if (changed && context.mounted) Navigator.pop(context);
              },
            ),
            if (index != _BillingPlan.values.length - 1)
              const SizedBox(height: 20),
          ],
        ],
      ),
      footer: Column(
        children: [
          _BillingActionButton(
            label: 'Cancel Subscription',
            icon: Icons.warning_amber_outlined,
            danger: true,
            outline: true,
            onPressed: () async {
              final cancelled = await _openCancellationDialog(context, ref);
              controller.resetAction();
              if (cancelled && context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _BillingActionButton(
            label: 'Close',
            outline: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _BillingCycleSelector extends StatelessWidget {
  const _BillingCycleSelector({required this.selected, required this.onSelect});

  final _BillingCycle selected;
  final ValueChanged<_BillingCycle> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final cycle in _BillingCycle.values) ...[
          Expanded(
            child: SizedBox(
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: const RoundedRectangleBorder(),
                  backgroundColor: selected == cycle
                      ? AppColors.black
                      : AppColors.white,
                  foregroundColor: selected == cycle
                      ? AppColors.white
                      : AppColors.neutral500,
                  side: BorderSide(
                    color: selected == cycle
                        ? AppColors.black
                        : AppColors.neutral200,
                  ),
                ),
                onPressed: () => onSelect(cycle),
                child: Text(
                  cycle == _BillingCycle.monthly ? 'Monthly' : 'Yearly',
                ),
              ),
            ),
          ),
          if (cycle != _BillingCycle.values.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _BillingPlanOption extends StatelessWidget {
  const _BillingPlanOption({
    required this.id,
    required this.details,
    required this.cycle,
    required this.samePlan,
    required this.current,
    required this.onSelect,
  });

  final _BillingPlan id;
  final _BillingPlanDetails details;
  final _BillingCycle cycle;
  final bool samePlan;
  final bool current;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final price = details.priceFor(cycle);
    final showRibbon = current || details.isPopular;
    return Padding(
      padding: EdgeInsets.only(top: showRibbon ? 12 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: showRibbon ? AppColors.black : AppColors.neutral200,
                width: showRibbon ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Column(
                    children: [
                      Text(
                        '${details.name} plan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _billingMoney(price),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '/month',
                            style: TextStyle(
                              color: AppColors.neutral500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (cycle == _BillingCycle.yearly)
                        Text(
                          '${_billingMoney(id.annualPrice)} billed annually',
                          style: const TextStyle(
                            color: AppColors.neutral500,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${details.credits} credits/month',
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details.tagline,
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      for (final feature in details.features)
                        _BillingFeatureLine(feature: feature),
                      for (final feature in details.excludedFeatures)
                        _BillingFeatureLine(feature: feature, excluded: true),
                      const SizedBox(height: 20),
                      _BillingActionButton(
                        key: ValueKey('billing-plan-${id.name}'),
                        label: current
                            ? 'Current plan'
                            : samePlan
                            ? 'Switch to ${cycle.name}'
                            : id == _BillingPlan.starter
                            ? 'Downgrade to Starter'
                            : 'Upgrade to ${details.name}',
                        outline: id != _BillingPlan.business,
                        onPressed: current ? null : onSelect,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showRibbon)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  color: AppColors.black,
                  child: Text(
                    current ? 'Current Plan' : 'Most Popular',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BillingFeatureLine extends StatelessWidget {
  const _BillingFeatureLine({required this.feature, this.excluded = false});

  final String feature;
  final bool excluded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: excluded ? AppColors.neutral500 : AppColors.black,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                color: excluded ? AppColors.neutral500 : AppColors.black,
                decoration: excluded ? TextDecoration.lineThrough : null,
                fontSize: 14,
                height: 1.43,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _showPlanConfirmation(
  BuildContext context,
  WidgetRef ref,
  _BillingPlan plan,
) async {
  return await _showBillingDialog<bool>(
        context: context,
        maxWidth: 430,
        builder: (_) => _BillingPlanConfirmation(plan: plan),
      ) ??
      false;
}

class _BillingPlanConfirmation extends ConsumerWidget {
  const _BillingPlanConfirmation({required this.plan});

  final _BillingPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_billingControllerProvider);
    final controller = ref.read(_billingControllerProvider.notifier);
    final details = _billingPlans[plan]!;
    final downgrade = details.credits < state.plan.credits;
    if (state.action == _BillingAction.planChangeSuccess) {
      return _BillingPlanChangeSuccess(
        onClose: () => Navigator.pop(context, true),
      );
    }
    final yearly = state.selectedCycle == _BillingCycle.yearly;
    final charge = yearly
        ? '${_billingMoney(plan.annualPrice)} billed annually, '
              '${_billingMoney(details.yearlyPrice)}/month'
        : '${_billingMoney(details.monthlyPrice)}/month';
    return _BillingModal(
      title: '${downgrade ? 'Downgrade' : 'Upgrade'} to ${details.name}',
      onClose: () => Navigator.pop(context, false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (downgrade) ...[
            const _BillingNotice(
              warning: true,
              text:
                  "Heads up, you'll lose AI posing controls, AI-generated product videos, and faster priority rendering.",
            ),
            const SizedBox(height: 24),
          ],
          Text(
            "You'll be charged $charge today.",
            style: const TextStyle(fontSize: 14, height: 1.55),
          ),
          const SizedBox(height: 12),
          const Text(
            'This switch is immediate. Your current plan ends today and the new one starts. Remaining credits carry over.',
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your remaining ${state.creditsRemaining} credits will carry over, and we will add ${details.credits} more for the new plan.',
            style: const TextStyle(fontSize: 14, height: 1.55),
          ),
          const SizedBox(height: 12),
          Text(
            "You'll have ${state.creditsRemaining + details.credits} credits to start.",
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
            ),
          ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: _BillingActionButton(
              label: 'Cancel',
              outline: true,
              onPressed: () => Navigator.pop(context, false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BillingActionButton(
              label: downgrade ? 'Yes, downgrade' : 'Confirm upgrade',
              isLoading: state.action == _BillingAction.changingPlan,
              onPressed: () => controller.changePlan(plan),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingPlanChangeSuccess extends StatelessWidget {
  const _BillingPlanChangeSuccess({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 48, color: AppColors.black),
          const SizedBox(height: 20),
          const Text(
            'Plan updated',
            style: TextStyle(
              fontSize: 20,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your new plan is active.',
            style: TextStyle(color: AppColors.neutral500, fontSize: 14),
          ),
          const SizedBox(height: 28),
          _BillingActionButton(
            key: const ValueKey('billing-plan-success-close'),
            label: 'Close',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
