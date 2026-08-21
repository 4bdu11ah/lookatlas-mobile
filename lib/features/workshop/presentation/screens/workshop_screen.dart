import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/constants/app_assets.dart';
import 'package:look_atlas/core/layout/app_responsive.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/presentation/controllers/workshop_controller_provider.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_dotted_border.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

part '../widgets/workshop_editor_widgets.dart';
part '../widgets/workshop_image_widgets.dart';
part '../widgets/workshop_overlay_widgets.dart';
part '../widgets/workshop_result_widgets.dart';
part '../widgets/workshop_shared_widgets.dart';
part 'workshop_guide_screen.dart';

class WorkshopScreen extends ConsumerStatefulWidget {
  const WorkshopScreen({super.key});

  @override
  ConsumerState<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends ConsumerState<WorkshopScreen> {
  late final TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(
      text: ref.read(workshopControllerProvider).prompt,
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workshopControllerProvider);
    final isPremium = ref.watch(isPremiumProvider);
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: const CustomAppBar(
        title: 'Workshop',
        showBackButton: true,
      ),
      body: ResponsiveContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _WorkshopContent(
            state: state,
            isPremium: isPremium,
            promptController: _promptController,
            actions: _WorkshopScreenActions(
              showGuide: _showGuide,
              pickBase: _pickBaseImage,
              addReference: _addReference,
              generate: _handleGenerate,
              downloadResult: () => _download(state.result),
              useResultAsBase: _useResultAsBase,
              openHistory: _openHistory,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addReference() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final source = await showImageSourceSheet(
      context,
      title: 'Add a reference',
    );
    if (source == null || !mounted) return;
    await ref
        .read(workshopControllerProvider.notifier)
        .addReferenceFrom(source);
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _pickBaseImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final source = await showImageSourceSheet(
      context,
      title: 'Add a base image',
    );
    if (source == null || !mounted) return;
    await ref
        .read(workshopControllerProvider.notifier)
        .pickBaseImageFrom(source);
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _handleGenerate() async {
    if (!ref.read(isPremiumProvider)) {
      await _showPaywall();
      return;
    }
    await ref.read(workshopControllerProvider.notifier).generate();
  }

  Future<void> _showGuide() => context.push<void>(AppRoutes.workshopGuide);

  Future<void> _showPaywall() async {
    final upgrade = await showAppDialog<bool>(
      context: context,
      title: 'SUBSCRIBER FEATURE',
      subtitle: 'Edit any image in seconds.',
      builder: (_) => const _WorkshopPaywallDialog(),
    );
    if ((upgrade ?? false) && mounted) context.go(AppRoutes.paywall);
  }

  Future<void> _openHistory(int index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(workshopControllerProvider.notifier).selectHistory(index);
    final history = ref.read(workshopControllerProvider).history;
    if (index >= history.length) return;
    final generation = history[index];
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.blackAlpha60,
      builder: (_) => _WorkshopPreviewDialog(
        item: generation,
        position: index + 1,
        total: history.length,
        onDownload: () => unawaited(_download(generation)),
        onUseAsBase: () => unawaited(
          _useGenerationAsBase(generation, closePreview: true),
        ),
        onDelete: () {
          Navigator.pop(context);
          unawaited(_confirmDelete(generation));
        },
      ),
    );
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _download(WorkshopGeneration? generation) async {
    if (generation == null) return;
    final failure = await ref
        .read(workshopControllerProvider.notifier)
        .saveGeneration(generation);
    if (!mounted) return;
    if (failure == null) {
      AppSnackBar.showSuccess(context, 'Image saved to Photos.');
    } else {
      AppSnackBar.showError(context, failure.message);
    }
  }

  Future<void> _useResultAsBase() async {
    final success = await ref
        .read(workshopControllerProvider.notifier)
        .useResultAsBase();
    if (!mounted || success) return;
    _showControllerFailure();
  }

  Future<void> _useGenerationAsBase(
    WorkshopGeneration generation, {
    required bool closePreview,
  }) async {
    final success = await ref
        .read(workshopControllerProvider.notifier)
        .useGenerationAsBase(generation);
    if (!mounted) return;
    if (!success) {
      _showControllerFailure();
      return;
    }
    if (closePreview) Navigator.pop(context);
    AppSnackBar.showSuccess(context, 'Result set as base image.');
  }

  void _showControllerFailure() {
    final failure = ref.read(workshopControllerProvider).failure;
    if (failure != null) AppSnackBar.showError(context, failure.message);
  }

  Future<void> _confirmDelete(WorkshopGeneration generation) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => _WorkshopDeleteDialog(
        onCancel: () => Navigator.pop(dialogContext, false),
        onDelete: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref
        .read(workshopControllerProvider.notifier)
        .deleteGeneration(generation.id);
    if (!mounted) return;
    if (failure == null) {
      AppSnackBar.showSuccess(context, 'Generation deleted.');
    } else {
      AppSnackBar.showError(context, failure.message);
    }
  }
}

class _WorkshopContent extends ConsumerWidget {
  const _WorkshopContent({
    required this.state,
    required this.isPremium,
    required this.promptController,
    required this.actions,
  });

  final WorkshopState state;
  final bool isPremium;
  final TextEditingController promptController;
  final _WorkshopScreenActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(workshopControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WorkshopHeader(onShowGuide: actions.showGuide),
        const SizedBox(height: 16),
        _WorkshopEditor(
          state: state,
          isPremium: isPremium,
          promptController: promptController,
          actions: _WorkshopEditorActions(
            pickBase: actions.pickBase,
            removeBase: controller.removeBaseImage,
            changeMode: controller.setMode,
            addReference: actions.addReference,
            removeReference: controller.removeReference,
            changePrompt: controller.updatePrompt,
            generate: actions.generate,
            retry: controller.load,
          ),
        ),
        const SizedBox(height: 20),
        _WorkshopResultPanel(
          state: state,
          onDownload: actions.downloadResult,
          onUseAsBase: actions.useResultAsBase,
        ),
        const SizedBox(height: 16),
        _WorkshopHistoryPanel(
          isLoading: state.isLoading,
          history: state.history,
          onSelect: actions.openHistory,
        ),
      ],
    );
  }
}

class _WorkshopScreenActions {
  const _WorkshopScreenActions({
    required this.showGuide,
    required this.pickBase,
    required this.addReference,
    required this.generate,
    required this.downloadResult,
    required this.useResultAsBase,
    required this.openHistory,
  });

  final VoidCallback showGuide;
  final VoidCallback pickBase;
  final VoidCallback addReference;
  final VoidCallback generate;
  final VoidCallback downloadResult;
  final VoidCallback useResultAsBase;
  final ValueChanged<int> openHistory;
}
