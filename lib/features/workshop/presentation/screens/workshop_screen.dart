import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/constants/app_assets.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/presentation/controllers/workshop_controller.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';
import 'package:look_atlas/shared/widgets/app_dotted_border.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_text_button.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

part '../widgets/workshop_widgets.dart';
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
    final controller = ref.read(workshopControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(
        title: 'Workshop',
        showBackButton: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WorkshopHero(),
                const SizedBox(height: 22),
                AppTextButton(
                  icon: Icons.info_outline,
                  label: 'HOW DOES THIS WORK?',
                  onPressed: () => context.go(AppRoutes.workshopGuide),
                  fitToContent: true,
                ),
                const SizedBox(height: 22),
                if (state.validationMessage != null) ...[
                  _WorkshopAlert(
                    icon: Icons.error_outline,
                    text: state.validationMessage!,
                    tone: _WorkshopAlertTone.danger,
                  ),
                  const SizedBox(height: 12),
                ] else if (state.referenceLimitReached) ...[
                  const _WorkshopAlert(
                    icon: Icons.info_outline,
                    text: 'Reference limit reached. Remove one to add more.',
                    tone: _WorkshopAlertTone.warning,
                  ),
                  const SizedBox(height: 12),
                ],
                _BaseImagePanel(
                  image: state.baseImage,
                  onUpload: _pickBaseImage,
                  onRemove: controller.removeBaseImage,
                ),
                if (state.hasBaseImage) ...[
                  const SizedBox(height: 14),
                  _ModePicker(
                    selected: state.editMode,
                    onChanged: controller.setMode,
                  ),
                ],
                const SizedBox(height: 14),
                _ReferenceStrip(
                  references: state.references,
                  onAdd: _addReference,
                  onRemove: controller.removeReference,
                ),
                const SizedBox(height: 14),
                _PromptCard(
                  controller: _promptController,
                  onChanged: controller.updatePrompt,
                ),
                const SizedBox(height: 14),
                _GenerateButton(
                  locked: !state.isUnlocked,
                  busy: state.isGenerating,
                  enabled: state.canGenerate,
                  onTap: () => unawaited(_handleGenerate(context)),
                ),
                const SizedBox(height: 16),
                _ResultPanel(
                  state: state,
                  onDownload: () => AppSnackBar.showSuccess(
                    context,
                    'Result prepared for download.',
                  ),
                  onUseAsBase: controller.useResultAsBase,
                ),
                const SizedBox(height: 16),
                _HistoryPanel(
                  history: state.history,
                  selectedIndex: state.selectedHistoryIndex,
                  onSelect: (index) {
                    controller.selectHistory(index);
                    unawaited(
                      _showPreview(
                        context,
                        ref.read(workshopControllerProvider),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addReference() async {
    final source = await showImageSourceSheet(
      context,
      title: 'Add a reference',
    );
    if (source == null || !mounted) return;
    await ref
        .read(workshopControllerProvider.notifier)
        .addReferenceFrom(source);
  }

  Future<void> _pickBaseImage() async {
    final source = await showImageSourceSheet(
      context,
      title: 'Add a base image',
    );
    if (source == null || !mounted) return;
    await ref
        .read(workshopControllerProvider.notifier)
        .pickBaseImageFrom(source);
  }

  Future<void> _handleGenerate(BuildContext context) async {
    final state = ref.read(workshopControllerProvider);
    if (!state.isUnlocked) {
      await _showPaywallSheet(context);
      return;
    }
    final success = await ref
        .read(workshopControllerProvider.notifier)
        .generate();
    if (!context.mounted || !success) return;
    AppSnackBar.showSuccess(context, 'Edit complete');
  }

  Future<void> _showPaywallSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (_) => _WorkshopPaywallSheet(
        onUpgrade: () {
          ref.read(workshopControllerProvider.notifier).unlock();
          Navigator.pop(context);
          AppSnackBar.showSuccess(context, 'Workshop unlocked.');
        },
      ),
    );
  }

  Future<void> _showPreview(BuildContext context, WorkshopState state) {
    if (state.history.isEmpty) return Future<void>.value();
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.blackAlpha90,
      builder: (_) => _WorkshopPreviewDialog(
        item: state.history[state.selectedHistoryIndex],
      ),
    );
  }
}
