part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class CreateShootScreen extends ConsumerWidget {
  const CreateShootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: CustomAppBar(
        title: 'Create Shoot',
        showBackButton: true,
        onBack: () => _closeCreateShoot(context, ref),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: _CreatePage(
                onComplete: (jobId) => context.go(AppRoutes.shootDetail(jobId)),
                onOpenModal: (kind) => _openDashboardModal(context, ref, kind),
                onToast: (text) => AppSnackBar.show(context, text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _closeCreateShoot(BuildContext context, WidgetRef ref) {
  ref.read(_createShootControllerProvider.notifier).reset();
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(AppRoutes.dashboardShoots);
}

class _CreatePage extends ConsumerWidget {
  const _CreatePage({
    required this.onComplete,
    required this.onOpenModal,
    required this.onToast,
  });

  final ValueChanged<String> onComplete;
  final ValueChanged<_ModalKind> onOpenModal;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_createShootControllerProvider);
    final controller = ref.read(_createShootControllerProvider.notifier);
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: BarSpinner()),
      );
    }
    if (state.failure != null && state.catalog == null) {
      return _Card(
        child: _Stack(
          gap: 12,
          children: [
            Text(state.failure!.message),
            AppOutlinedButton(
              label: 'Try again',
              icon: Icons.refresh,
              onPressed: () => unawaited(controller.load()),
            ),
          ],
        ),
      );
    }
    final index = _CreateStep.values.indexOf(state.step);
    final canContinue = switch (state.step) {
      _CreateStep.product => state.products.isNotEmpty,
      _CreateStep.model => state.models.isNotEmpty,
      _CreateStep.planning => state.chosenShots.isNotEmpty,
      _ => true,
    };
    return _Stack(
      gap: 14,
      children: [
        const _CreateShootHeader(),
        _Stepper(step: state.step),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: _CreateStepBody(
            state: state,
            controller: controller,
            onOpenModal: onOpenModal,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                label: 'Back',
                icon: Icons.arrow_back,
                onPressed: index == 0
                    ? () {}
                    : () => controller.setStep(_CreateStep.values[index - 1]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: state.step == _CreateStep.confirm
                    ? 'Generate ${state.chosenShots.length} Shots'
                    : 'Next',
                icon: state.step == _CreateStep.confirm
                    ? Icons.auto_awesome
                    : Icons.arrow_forward,
                iconAlignment: IconAlignment.end,
                isLoading: state.isSubmitting,
                onPressed: state.step == _CreateStep.confirm
                    ? () async {
                        final result = await controller.createShoot();
                        if (!context.mounted) return;
                        result.fold(
                          (jobId) {
                            onToast('Shoot created. Generation started.');
                            controller.reset();
                            onComplete(jobId);
                          },
                          (failure) => AppSnackBar.showError(
                            context,
                            failure.message,
                          ),
                        );
                      }
                    : canContinue
                    ? () => controller.setStep(_CreateStep.values[index + 1])
                    : null,
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
    required this.state,
    required this.controller,
    required this.onOpenModal,
  });

  final _CreateShootState state;
  final _CreateShootController controller;
  final ValueChanged<_ModalKind> onOpenModal;

  @override
  Widget build(BuildContext context) {
    return switch (state.step) {
      _CreateStep.product => _ProductStep(
        products: state.products,
        selected: state.selectedProduct,
        onSelect: controller.selectProduct,
        onAdd: () => onOpenModal(_ModalKind.product),
      ),
      _CreateStep.model => _ModelStep(
        models: state.models,
        userModelCount: state.catalog?.userModels.length ?? 0,
        libraryModelCount: state.catalog?.libraryModels.length ?? 0,
        useLibraryModels: state.useLibraryModels,
        selected: state.selectedModel,
        onSelect: controller.selectModel,
        onSourceChanged: (useLibrary) =>
            controller.setModelSource(useLibraryModels: useLibrary),
        onAdd: () => onOpenModal(_ModalKind.model),
      ),
      _CreateStep.director => _DirectorStep(
        directors: state.directors,
        settings: state.settings,
        selected: state.selectedDirector,
        onSelect: controller.selectDirector,
        onSettingsChanged: controller.updateSettings,
        onPortfolio: () => onOpenModal(_ModalKind.directorPortfolio),
      ),
      _CreateStep.planning => _PlanningStep(
        isPlanned: state.isPlanned,
        isPlanning: state.isPlanning,
        shots: state.plannedShots,
        selectedShots: state.selectedShots,
        onPlan: () async {
          final failure = await controller.planShots();
          if (failure != null && context.mounted) {
            AppSnackBar.showError(context, failure.message);
          }
        },
        onToggle: controller.toggleShot,
        onCustom: () => onOpenModal(_ModalKind.customShot),
      ),
      _CreateStep.confirm => _ReviewStep(state: state),
    };
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});

  final _CreateStep step;

  @override
  Widget build(BuildContext context) {
    const steps = _CreateStep.values;
    final current = steps.indexOf(step);
    const labels = [
      'Product',
      'Model',
      'Director',
      'Shot Planning',
      'Generate',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            _StepChip(
              index: index + 1,
              label: labels[index],
              active: index == current,
              done: index < current,
            ),
            if (index != steps.length - 1)
              SizedBox(
                width: 18,
                height: 28,
                child: Center(
                  child: Container(
                    key: ValueKey('create-step-connector-$index'),
                    height: 1,
                    color: index < current
                        ? AppColors.black
                        : AppColors.neutral200,
                  ),
                ),
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
  });

  final int index;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.white : AppColors.black;
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Container(
            key: ValueKey('create-step-circle-$index'),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.black : AppColors.neutralLight,
            ),
            child: done
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: foreground,
                  )
                : Text(
                    '$index',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            key: ValueKey('create-step-label-$index'),
            height: 24,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? AppColors.black : AppColors.neutral500,
                fontSize: 9,
                height: 1.2,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
