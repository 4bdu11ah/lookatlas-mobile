library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/layout/app_responsive.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/create_shoot_controller.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/shoot_draft_controller.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/shoots_controller.dart';
import 'package:look_atlas/features/shoots/presentation/dialogs/shoot_modal.dart';
import 'package:look_atlas/features/shoots/presentation/models/create_step.dart';
import 'package:look_atlas/features/shoots/presentation/models/shoot_modal_kind.dart';
import 'package:look_atlas/shared/widgets/app_bottom_sheet.dart';
import 'package:look_atlas/shared/widgets/app_card.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_feedback.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_spaced_column.dart';
import 'package:look_atlas/shared/widgets/app_tap_icon_button.dart';
import 'package:look_atlas/shared/widgets/app_text.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

part '../widgets/create_shoot_director_settings.dart';
part '../widgets/create_shoot_director_widgets.dart';
part '../widgets/create_shoot_planning_widgets.dart';
part '../widgets/create_shoot_selection_widgets.dart';
part '../widgets/create_shoot_widgets.dart';

typedef _CreateShootState = CreateShootState;
typedef _CreateShootController = CreateShootController;
typedef _CreateStep = CreateStep;
typedef _ShootModalKind = ShootModalKind;

class CreateShootScreen extends ConsumerStatefulWidget {
  const CreateShootScreen({super.key, this.draftId});

  final String? draftId;

  @override
  ConsumerState<CreateShootScreen> createState() => _CreateShootScreenState();
}

class _CreateShootScreenState extends ConsumerState<CreateShootScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(
        () => ref
            .read(shootDraftProvider.notifier)
            .initializeEditor(widget.draftId),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Failure?>(
      shootDraftProvider.select((state) => state.failure),
      (previous, next) {
        if (next != null && next != previous) {
          AppSnackBar.showError(
            context,
            'Draft saved on this device, but cloud sync failed.',
          );
        }
      },
    );
    ref.listen<CreateShootState>(createShootControllerProvider, (_, next) {
      ref.read(shootDraftProvider.notifier).scheduleSave(next);
    });
    ref.listen(
      createShootControllerProvider.select((state) => state.step),
      _scrollToTop,
    );
    final hasChanges = ref.watch(
      createShootControllerProvider.select((state) => state.hasChanges),
    );
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_closeCreateShoot(context, ref));
      },
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        appBar: CustomAppBar(
          title: 'Create Shoot',
          showBackButton: true,
          onBack: () => unawaited(_closeCreateShoot(context, ref)),
        ),
        body: SafeArea(
          bottom: false,
          child: ResponsiveContent(
            child: Align(
              key: const ValueKey('create-shoot-top-alignment'),
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: _CreatePage(
                  onComplete: (jobId) =>
                      context.go(AppRoutes.shootDetail(jobId)),
                  onOpenModal: (kind) => openShootModal(context, ref, kind),
                  onToast: (text) => AppSnackBar.show(context, text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToTop(_CreateStep? previous, _CreateStep next) {
    if (previous == null || previous == next) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }
}

Future<void> _closeCreateShoot(BuildContext context, WidgetRef ref) async {
  if (ref.read(createShootControllerProvider).hasChanges) {
    final discard = await showAppDialog<bool>(
      context: context,
      title: 'Leave Shoot Room?',
      subtitle: 'Your setup is not finished.',
      barrierDismissible: false,
      builder: (_) => const Text(
        'Keep this draft and resume it anytime, or discard your current selections.',
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
      footer: Builder(
        builder: (dialogContext) => Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                label: 'Discard & Exit',
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PrimaryButton(
                label: 'Keep Draft & Exit',
                foregroundColor: AppColors.white,
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
            ),
          ],
        ),
      ),
    );
    if (discard == null || !context.mounted) return;
    if (discard) {
      final deleted = await ref
          .read(shootDraftProvider.notifier)
          .discardActive();
      if (!deleted) {
        if (context.mounted) {
          AppSnackBar.showError(context, 'Could not delete this draft.');
        }
        return;
      }
    } else {
      await ref
          .read(shootDraftProvider.notifier)
          .flush(
            ref.read(createShootControllerProvider),
          );
    }
  }
  if (!context.mounted) return;
  context.go(AppRoutes.dashboardShoots);
}

class _CreatePage extends ConsumerWidget {
  const _CreatePage({
    required this.onComplete,
    required this.onOpenModal,
    required this.onToast,
  });

  final ValueChanged<String> onComplete;
  final ValueChanged<_ShootModalKind> onOpenModal;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createShootControllerProvider);
    final controller = ref.read(createShootControllerProvider.notifier);
    final isAdmin =
        ref.watch(authStateProvider).asData?.value?.role.toLowerCase() ==
        'admin';
    final hasUnloadedStep = switch (state.step) {
      _CreateStep.product => state.catalog == null,
      _CreateStep.model => !state.hasLoadedModels,
      _CreateStep.director => !state.hasLoadedDirectorSetup,
      _ => false,
    };
    if (state.failure != null && hasUnloadedStep) {
      return AppCard(
        child: AppSpacedColumn(
          gap: 12,
          children: [
            Text(state.failure!.message),
            AppOutlinedButton(
              label: 'Try again',
              icon: Icons.refresh,
              onPressed: () => unawaited(controller.retry()),
            ),
          ],
        ),
      );
    }
    final steps = state.steps;
    final index = steps.indexOf(state.step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CreateShootHeader(
          isAdmin: isAdmin,
          demoMode: state.demoMode,
          onDemoChanged: (enabled) => controller.setDemoMode(enabled: enabled),
        ),
        const SizedBox(height: 10),
        _Stepper(step: state.step, steps: steps),
        const SizedBox(height: 10),
        if (state.showValidation && state.validationErrors.isNotEmpty) ...[
          _ValidationSummary(errors: state.validationErrors),
          const SizedBox(height: 10),
        ],
        AppCard(
          padding: const EdgeInsets.all(15),
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
                onPressed: state.isPlanning
                    ? null
                    : index == 0
                    ? () => unawaited(_closeCreateShoot(context, ref))
                    : () => controller.setStep(steps[index - 1]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: state.step == _CreateStep.confirm ? 2 : 1,
              child: PrimaryButton(
                label: state.step == _CreateStep.confirm
                    ? state.demoMode
                          ? 'Generate Demo'
                          : 'Generate ${state.chosenShots.length} Shots'
                    : 'Next',
                icon: state.step == _CreateStep.confirm
                    ? Icons.auto_awesome
                    : Icons.arrow_forward,
                iconAlignment: state.step == _CreateStep.confirm
                    ? IconAlignment.start
                    : IconAlignment.end,
                foregroundColor: AppColors.white,
                isLoading: state.isSubmitting,
                onPressed: state.isPlanning
                    ? null
                    : state.step == _CreateStep.confirm
                    ? (state.demoMode
                              ? state.canGenerateDemo
                              : state.canGenerate)
                          ? () async {
                              if (state.demoMode) {
                                await _submitDemoShoot(
                                  context,
                                  ref,
                                  onComplete,
                                  onToast,
                                );
                              } else {
                                await _submitCreateShoot(
                                  context,
                                  ref,
                                  onComplete,
                                  onToast,
                                  onOpenModal,
                                );
                              }
                            }
                          : null
                    : () => controller.continueTo(steps[index + 1]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _submitDemoShoot(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String> onComplete,
  ValueChanged<String> onToast,
) async {
  final controller = ref.read(createShootControllerProvider.notifier);
  final result = await controller.createDemoShoot();
  if (!context.mounted) return;
  result.fold(
    (jobId) {
      onToast('Demo shoots created. Generation started.');
      unawaited(ref.read(shootsControllerProvider.notifier).load());
      unawaited(ref.read(shootDraftProvider.notifier).completeActive());
      controller.reset();
      onComplete(jobId);
    },
    (failure) => AppSnackBar.showError(context, failure.message),
  );
}

Future<void> _submitCreateShoot(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String> onComplete,
  ValueChanged<String> onToast,
  ValueChanged<_ShootModalKind> onOpenModal,
) async {
  final state = ref.read(createShootControllerProvider);
  final controller = ref.read(createShootControllerProvider.notifier);
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
      unawaited(ref.read(shootsControllerProvider.notifier).load());
      unawaited(ref.read(shootDraftProvider.notifier).completeActive());
      controller.reset();
      onComplete(jobId);
    },
    (failure) {
      if (failure is NetworkFailure &&
          (failure.code == 'RELAX_PLAN_INELIGIBLE' ||
              failure.details['upsell'] == 'pro')) {
        onOpenModal(_ShootModalKind.contextPaywall);
      }
      AppSnackBar.showError(context, failure.message);
    },
  );
}

Future<String?> _selectBagSubCategory(BuildContext context) =>
    showAppBottomSheet<String>(
      context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionTitle('What type of bag is this?'),
              const SizedBox(height: 6),
              const AppCaption('This helps AI place the product correctly.'),
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
  final ValueChanged<_ShootModalKind> onOpenModal;

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
        onAdd: () => onOpenModal(_ShootModalKind.product),
        onCalibrate: () => context.push(AppRoutes.dashboardProducts),
      ),
      _CreateStep.model => _ModelStep(
        models: state.models,
        isLoading: state.isLoadingModels,
        userModelCount: state.catalog?.userModels.length ?? 0,
        libraryModelCount: state.catalog?.libraryModels.length ?? 0,
        useLibraryModels: state.useLibraryModels,
        selectedKeys: state.selectedModelKeys.toSet(),
        selectedModels: state.selectedModels,
        productOnly: state.productOnly,
        onSelect: controller.toggleModel,
        onRemove: controller.removeModel,
        onClear: controller.clearModels,
        onProductOnlyChanged: (value) =>
            controller.setProductOnly(productOnly: value),
        onSourceChanged: (useLibrary) =>
            controller.setModelSource(useLibraryModels: useLibrary),
        onAdd: () => onOpenModal(_ShootModalKind.model),
      ),
      _CreateStep.director => _DirectorStep(
        directors: state.directors,
        isLoading: state.isLoadingDirectorSetup,
        settings: state.settings,
        selected: state.selectedDirector,
        catalog: state.catalog,
        demoMode: state.demoMode,
        demoDirectors: state.demoDirectors,
        onSelect: state.demoMode
            ? controller.toggleDemoDirector
            : controller.selectDirector,
        onDemoDirectorChanged: controller.updateDemoDirector,
        onSettingsChanged: controller.updateSettings,
        onUpgrade: () => onOpenModal(_ShootModalKind.contextPaywall),
        onPortfolio: (index) {
          controller.previewDirectorAt(index);
          onOpenModal(_ShootModalKind.directorPortfolio);
        },
      ),
      _CreateStep.planning => _PlanningStep(
        details: (
          directorName: state.directors[state.selectedDirector].name,
          directorStyle: state.directors[state.selectedDirector].subtitle,
          useCase: _planningUseCaseLabel(state.settings.useCase),
          shotCount: state.settings.numberOfShots,
        ),
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
        onCustom: () => onOpenModal(_ShootModalKind.customShot),
      ),
      _CreateStep.confirm =>
        state.demoMode
            ? _DemoReviewStep(state: state)
            : _ReviewStep(
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
    final demoMode = !steps.contains(_CreateStep.planning);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          _StepChip(
            index: index + 1,
            label: demoMode && steps[index] == _CreateStep.director
                ? 'Directors'
                : labels[steps[index]]!,
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
