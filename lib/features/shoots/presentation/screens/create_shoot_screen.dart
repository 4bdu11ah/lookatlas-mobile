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
        child: ResponsiveContent(
          child: Align(
            key: const ValueKey('create-shoot-top-alignment'),
            alignment: Alignment.topCenter,
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
    if (state.failure != null && state.catalog == null) {
      return _Card(
        child: _Column(
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
    final steps = state.steps;
    final index = steps.indexOf(state.step);
    final canContinue = switch (state.step) {
      _CreateStep.product => state.selectedProducts.isNotEmpty,
      _CreateStep.model => state.selectedModels.isNotEmpty,
      _CreateStep.director =>
        state.directors.isNotEmpty &&
            (!state.isDemo || state.selectedDirectorIds.isNotEmpty),
      _CreateStep.planning => state.chosenShots.isNotEmpty,
      _ => true,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CreateShootHeader(
          isAdmin: state.isAdmin,
          isDemo: state.isDemo,
          onDemoChanged: (value) => controller.setDemo(isDemo: value),
        ),
        const SizedBox(height: 10),
        _Stepper(step: state.step, steps: steps),
        const SizedBox(height: 10),
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
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                key: ValueKey(
                  index == 0 ? 'create-shoot-cancel' : 'create-shoot-back',
                ),
                label: index == 0 ? 'Cancel' : 'Back',
                icon: index == 0 ? Icons.close : Icons.arrow_back,
                onPressed: index == 0
                    ? () => _closeCreateShoot(context, ref)
                    : () => controller.setStep(steps[index - 1]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: state.step == _CreateStep.confirm
                    ? state.isDemo
                          ? 'Generate ${state.selectedDirectorIds.length} Directors'
                          : 'Generate ${state.chosenShots.length} Shots'
                    : 'Next',
                icon: state.step == _CreateStep.confirm
                    ? Icons.auto_awesome
                    : Icons.arrow_forward,
                iconAlignment: IconAlignment.end,
                foregroundColor: state.step == _CreateStep.confirm
                    ? AppColors.white
                    : AppColors.black,
                isLoading: state.isSubmitting,
                onPressed: state.step == _CreateStep.confirm
                    ? state.canGenerate
                          ? () async {
                              await _submitCreateShoot(
                                context,
                                ref,
                                onComplete,
                                onToast,
                                onOpenModal,
                              );
                            }
                          : null
                    : canContinue
                    ? () => controller.setStep(steps[index + 1])
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _submitCreateShoot(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String> onComplete,
  ValueChanged<String> onToast,
  ValueChanged<_ModalKind> onOpenModal,
) async {
  final state = ref.read(_createShootControllerProvider);
  final controller = ref.read(_createShootControllerProvider.notifier);
  if (state.needsPrimaryProductSubCategory) {
    final subCategory = await _selectBagSubCategory(context);
    if (subCategory == null || !context.mounted) return;
    final failure = await controller.setPrimaryProductSubCategory(subCategory);
    if (failure != null) {
      if (context.mounted) AppSnackBar.showError(context, failure.message);
      return;
    }
  }
  final result = await controller.createShoot();
  if (!context.mounted) return;
  result.fold(
    (jobId) {
      onToast('Shoot created. Generation started.');
      controller.reset();
      onComplete(jobId);
    },
    (failure) {
      if (failure is NetworkFailure &&
          (failure.code == 'RELAX_PLAN_INELIGIBLE' ||
              failure.details['upsell'] == 'pro')) {
        onOpenModal(_ModalKind.contextPaywall);
      }
      AppSnackBar.showError(context, failure.message);
    },
  );
}

Future<String?> _selectBagSubCategory(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionTitle('What type of bag is this?'),
              const SizedBox(height: 6),
              const _Caption('This helps AI place the product correctly.'),
              const SizedBox(height: 12),
              for (final value in const [
                'Tote',
                'Crossbody',
                'Clutch',
                'Backpack',
              ])
                ListTile(
                  title: Text(value),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.pop(context, value),
                ),
            ],
          ),
        ),
      ),
    );

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
        isLoading: state.isLoading,
        selectedIds: state.selectedProductIds.toSet(),
        selectedProducts: state.selectedProducts,
        productMode: state.productMode,
        onSelect: controller.toggleProduct,
        onClear: controller.clearProducts,
        onModeChanged: controller.setProductMode,
        onAdd: () => onOpenModal(_ModalKind.product),
        onCalibrate: () => context.push(AppRoutes.dashboardProducts),
      ),
      _CreateStep.model => _ModelStep(
        models: state.models,
        userModelCount: state.catalog?.userModels.length ?? 0,
        libraryModelCount: state.catalog?.libraryModels.length ?? 0,
        useLibraryModels: state.useLibraryModels,
        selectedKeys: state.selectedModelKeys.toSet(),
        selectedModels: state.selectedModels,
        onSelect: controller.toggleModel,
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
        onPortfolio: (index) {
          controller.selectDirector(index);
          onOpenModal(_ModalKind.directorPortfolio);
        },
        isDemo: state.isDemo,
        selectedDirectorIds: state.selectedDirectorIds.toSet(),
        onDemoSelect: controller.toggleDemoDirector,
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
      _CreateStep.confirm => _ReviewStep(
        state: state,
        onLaneChanged: controller.setLane,
      ),
    };
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step, required this.steps});

  final _CreateStep step;
  final List<_CreateStep> steps;

  @override
  Widget build(BuildContext context) {
    final current = steps.indexOf(step);
    const labels = {
      _CreateStep.product: 'Product',
      _CreateStep.model: 'Model',
      _CreateStep.director: 'Director',
      _CreateStep.planning: 'Shot Planning',
      _CreateStep.confirm: 'Generate',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          _StepChip(
            index: index + 1,
            label: labels[steps[index]]!,
            active: index == current,
            done: index < current,
          ),
          if (index != steps.length - 1)
            SizedBox(
              width: 15,
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
      width: 50,
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
