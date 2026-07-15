part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CreatePage extends ConsumerWidget {
  const _CreatePage({
    required this.onNavigate,
    required this.onOpenModal,
    required this.onToast,
  });

  final ValueChanged<_DashboardPage> onNavigate;
  final ValueChanged<_ModalKind> onOpenModal;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_createShootControllerProvider);
    final controller = ref.read(_createShootControllerProvider.notifier);
    final step = state.step;
    const steps = _CreateStep.values;
    final index = steps.indexOf(step);
    return _Stack(
      children: [
        Row(
          children: [
            _IconButton(
              icon: Icons.arrow_back,
              label: 'Back to shoots',
              onTap: () => onNavigate(_DashboardPage.jobs),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'New Shoot',
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.1,
                            fontWeight: AppTypography.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      _Badge('AI Director', kind: _BadgeKind.dark),
                    ],
                  ),
                  _Caption('AI Director handles everything for you'),
                ],
              ),
            ),
          ],
        ),
        _Stepper(
          step: step,
          onStepChanged: controller.setStep,
        ),
        _Card(
          padding: const EdgeInsets.all(24),
          child: _CreateStepBody(
            step: step,
            onOpenModal: onOpenModal,
            onToast: onToast,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _Button.secondary(
                label: 'Back',
                icon: Icons.arrow_back,
                onTap: index == 0
                    ? () {}
                    : () => controller.setStep(steps[index - 1]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Button(
                label: step == _CreateStep.confirm
                    ? 'Generate 5 Shots'
                    : 'Next',
                icon: step == _CreateStep.confirm
                    ? Icons.auto_awesome
                    : Icons.arrow_forward,
                iconAlignment: step == _CreateStep.confirm
                    ? IconAlignment.start
                    : IconAlignment.end,
                onTap: step == _CreateStep.confirm
                    ? () => onToast('Shoot created. Redirecting to job detail.')
                    : () => controller.setStep(steps[index + 1]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CreateStepBody extends StatelessWidget {
  const _CreateStepBody({
    required this.step,
    required this.onOpenModal,
    required this.onToast,
  });

  final _CreateStep step;
  final ValueChanged<_ModalKind> onOpenModal;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      _CreateStep.product => _Stack(
        gap: 12,
        children: [
          const _SectionTitle('Choose Products'),
          const _BodyText(
            'Select the product roster. Multi-product mode supports pairing or variants.',
          ),
          const _ChoiceCard(
            title: 'Emerald Slip Dress',
            body: 'Primary product, 2 photos',
            asset: '$_img/showcase-dress-before.jpg',
            active: true,
          ),
          const _ChoiceCard(
            title: 'Add new product',
            body: 'Opens inline product modal',
            icon: Icons.add,
          ),
          _Button.secondary(
            label: 'Open Add Product Modal',
            full: true,
            onTap: () => onOpenModal(_ModalKind.product),
          ),
        ],
      ),
      _CreateStep.director => const _Stack(
        gap: 12,
        children: [
          _SectionTitle('Choose Your Creative Director'),
          _SelectLike('Product Detail Page'),
          _ChoiceCard(
            title: 'Isabella Romano',
            body: 'Luxury editorial, Hermes, Loro Piana',
            asset: '$_img/showcase-dress-after.jpg',
            active: true,
          ),
          _ChoiceCard(
            title: 'Jordan Kim',
            body: 'Street energy, Zara, ASOS',
            asset: '$_img/showcase-shoes-after.jpg',
          ),
          _TextAreaLike('Brief the director...'),
        ],
      ),
      _CreateStep.planning => _Stack(
        gap: 12,
        children: [
          const _SectionTitle('Shot Planning'),
          const _BodyText(
            'Director plans cohesive shots. Maximum 8 selected shots.',
          ),
          const _PlanRow('Golden Hour Stride', 'Hero walking shot'),
          const _PlanRow('Texture Closeup', 'Detail crop for PDP'),
          _Button.secondary(
            label: 'Add custom shot',
            icon: Icons.add,
            full: true,
            onTap: () => onOpenModal(_ModalKind.customShot),
          ),
        ],
      ),
      _CreateStep.model => _Stack(
        gap: 12,
        children: [
          const _SectionTitle('Choose Models'),
          const _ChoiceCard(
            title: 'Maya Chen',
            body: 'My model, 170 cm',
            asset: '$_img/step-model.jpg',
            active: true,
          ),
          const _ChoiceCard(
            title: 'Look Atlas model',
            body: 'Available to all users',
            asset: '$_img/showcase-tshirt-after.jpg',
          ),
          _Button.secondary(
            label: 'Open Add Model Modal',
            full: true,
            onTap: () => onOpenModal(_ModalKind.model),
          ),
        ],
      ),
      _CreateStep.confirm => _Stack(
        gap: 12,
        children: [
          const _SectionTitle('Review & Generate'),
          const _MetricCard(
            'Credits',
            '30',
            '5 shots x 3 variations x 2 credits',
          ),
          const _Alert(
            kind: _AlertKind.info,
            text:
                'Not enough credits condition disables generation and shows the warning copy below the summary.',
          ),
          _Button(
            label: 'Generate 5 Shots',
            icon: Icons.auto_awesome,
            full: true,
            onTap: () => onToast('Shoot created. Redirecting to job detail.'),
          ),
        ],
      ),
    };
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step, required this.onStepChanged});

  final _CreateStep step;
  final ValueChanged<_CreateStep> onStepChanged;

  @override
  Widget build(BuildContext context) {
    const steps = _CreateStep.values;
    final current = steps.indexOf(step);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepChip(
              index: i + 1,
              label: const [
                'Product',
                'Director',
                'Shots',
                'Model',
                'Review',
              ][i],
              active: i == current,
              done: i < current,
              onTap: () => onStepChanged(steps[i]),
            ),
            if (i != steps.length - 1)
              Container(
                width: 28,
                height: 1,
                color: i < current ? AppColors.black : AppColors.neutral200,
              ),
          ],
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = active || done;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            color: dark ? AppColors.black : AppColors.white,
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: AppColors.black),
            ),
            child: Text(
              done ? '' : '$index',
              style: TextStyle(
                color: dark ? AppColors.white : AppColors.black,
                fontSize: 12,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.black : AppColors.neutral500,
              fontSize: 12,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    this.body,
    this.asset,
    this.icon,
    this.active = false,
    this.vertical = false,
  });

  final String title;
  final String? body;
  final String? asset;
  final IconData? icon;
  final bool active;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final media = asset == null
        ? Container(
            width: 56,
            height: 56,
            color: AppColors.neutral100,
            alignment: Alignment.center,
            child: Icon(icon ?? Icons.add, color: AppColors.black),
          )
        : _AssetBox(
            asset!,
            width: vertical ? double.infinity : 56,
            height: vertical ? 120 : 56,
          );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? AppColors.neutral100 : AppColors.white,
        border: Border.all(
          color: active ? AppColors.black : AppColors.neutral200,
          width: active ? 2 : 1,
        ),
      ),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                media,
                const SizedBox(height: 8),
                _CardTitle(title),
                if (body != null) _Caption(body!),
              ],
            )
          : Row(
              children: [
                media,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardTitle(title),
                      if (body != null) _Caption(body!),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
