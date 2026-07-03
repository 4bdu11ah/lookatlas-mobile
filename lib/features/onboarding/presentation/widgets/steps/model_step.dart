import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

/// Wizard step 4 — model picker: library tab with a gender filter, plus an
/// upload-your-own tab (mockup 04, states A/B). Stateless: the active tab
/// and the pick-in-flight flag live in [wizardControllerProvider].
class ModelStep extends ConsumerWidget {
  const ModelStep({super.key});

  /// Camera-or-gallery chooser, then the pick itself via the controller.
  Future<void> _uploadModelPhotos(BuildContext context, WidgetRef ref) async {
    final source = await showImageSourceSheet(
      context,
      title: 'Add model photos',
    );
    if (source == null) return;
    final result = await ref
        .read(wizardControllerProvider.notifier)
        .addModelPhotosFrom(source);
    if (!context.mounted) return;
    switch (result) {
      case PhotoPickResult.truncated:
        AppSnackBar.show(
          context,
          'You can upload up to $maxWizardPhotos photos.',
        );
      case PhotoPickResult.failed:
        AppSnackBar.showError(
          context,
          'Could not open your camera or photo library.',
        );
      case PhotoPickResult.added:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          Column(
            children: [
              const WizardStepHeader(
                title: 'Choose a model',
                subtitle:
                    'Pick a model that fits your brand. All models are free '
                    'for commercial use and you own every image we generate.',
              ),
              if (state.selectedModel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: state.selectedModel!.name,
                          style: const TextStyle(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        const TextSpan(text: ' selected'),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.43,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
            ],
          ),
          _Tabs(
            uploadTab: state.modelUploadTab,
            onChanged: (upload) => ref
                .read(wizardControllerProvider.notifier)
                .setModelUploadTab(upload: upload),
          ),
          if (state.modelUploadTab)
            _UploadTab(
              state: state,
              onUpload: () => _uploadModelPhotos(context, ref),
            )
          else
            _LibraryTab(state: state),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.uploadTab, required this.onChanged});

  final bool uploadTab;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outline)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Tab(
              label: 'Our Models',
              active: !uploadTab,
              onTap: () => onChanged(false),
            ),
            _Tab(
              label: 'Upload Your Own',
              active: uploadTab,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? scheme.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: 1.33,
            fontWeight: AppTypography.medium,
            color: active
                ? scheme.onSurface
                : scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// --- State A: model library --------------------------------------------------

class _LibraryTab extends ConsumerWidget {
  const _LibraryTab({required this.state});

  final WizardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(wizardControllerProvider.notifier);
    // Live library from GET /lookatlas-models.
    final modelsAsync = ref.watch(lookAtlasModelsProvider);

    return Column(
      spacing: 20,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            for (final (filter, label) in const [
              (ModelGender.all, 'All'),
              (ModelGender.women, 'Women'),
              (ModelGender.men, 'Men'),
            ])
              _FilterPill(
                label: label,
                active: state.modelGenderFilter == filter,
                onTap: () => controller.setModelGenderFilter(filter),
              ),
          ],
        ),
        switch (modelsAsync) {
          AsyncData(:final value) => _ModelGrid(
            models: [
              for (final model in value)
                if (state.modelGenderFilter == ModelGender.all ||
                    model.gender == state.modelGenderFilter)
                  model,
            ],
            state: state,
            onSelect: controller.selectModel,
          ),
          AsyncError() => _LibraryError(
            onRetry: () => ref.invalidate(lookAtlasModelsProvider),
          ),
          _ => const _LibraryLoading(),
        },
        Text(
          'Need a specific look? Once you sign up, you can create custom AI '
          'models just by describing them.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// The 2-column model grid for the fetched (and gender-filtered) library.
class _ModelGrid extends StatelessWidget {
  const _ModelGrid({
    required this.models,
    required this.state,
    required this.onSelect,
  });

  final List<LookAtlasModel> models;
  final WizardState state;
  final ValueChanged<LookAtlasModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (models.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'No models available for this filter yet.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      spacing: 16,
      children: [
        for (var i = 0; i < models.length; i += 2)
          Row(
            spacing: 16,
            children: [
              for (var j = i; j < i + 2; j++)
                Expanded(
                  child: j < models.length
                      ? _ModelCard(
                          model: models[j],
                          selected:
                              !state.usingUploadedModel &&
                              state.selectedModel?.id == models[j].id,
                          onTap: () => onSelect(models[j]),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}

/// Shimmer placeholders while the library downloads.
class _LibraryLoading extends StatelessWidget {
  const _LibraryLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      children: [
        for (var row = 0; row < 2; row++)
          Row(
            spacing: 16,
            children: [
              for (var col = 0; col < 2; col++)
                const Expanded(
                  child: AspectRatio(aspectRatio: 3 / 4, child: ShimmerBox()),
                ),
            ],
          ),
      ],
    );
  }
}

/// Fetch failed: explain and offer a retry.
class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        spacing: 12,
        children: [
          Icon(Icons.wifi_off_rounded, size: 24, color: scheme.onSurfaceVariant),
          Text(
            "Couldn't load the model library. Check your connection and "
            'try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          WizardButton(label: 'Try again', small: true, onTap: onRetry),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? scheme.onSurface
              : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: 1.33,
            color: active
                ? scheme.surface
                : scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.model,
    required this.selected,
    required this.onTap,
  });

  final LookAtlasModel model;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        foregroundDecoration: selected
            ? BoxDecoration(
                border: Border.all(color: scheme.onSurface, width: 2),
              )
            : BoxDecoration(border: Border.all(color: scheme.outline)),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShotImage(model.imageUrl),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xB3000000), Color(0x00000000)],
                    ),
                  ),
                  child: Text(
                    model.name,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.43,
                      fontWeight: AppTypography.medium,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: scheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 14, color: scheme.surface),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- State B: upload your own -------------------------------------------------

class _UploadTab extends ConsumerWidget {
  const _UploadTab({required this.state, required this.onUpload});

  final WizardState state;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(wizardControllerProvider.notifier);

    return Column(
      spacing: 20,
      children: [
        if (state.uploadingModel)
          SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  const BarSpinner(size: 28),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onUpload,
            child: DashedBorder(
              color: scheme.outline,
              radius: 12,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 28,
                        color: scheme.surface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to add model photos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: AppTypography.semiBold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Up to $maxWizardPhotos photos of the same person from '
                      'different angles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (state.uploadedModelPhotos.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Your uploaded models',
              style: TextStyle(
                fontSize: 14,
                height: 1.43,
                fontWeight: AppTypography.medium,
                color: scheme.onSurface,
              ),
            ),
          ),
          Row(
            spacing: 12,
            children: [
              for (final bytes in state.uploadedModelPhotos)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: controller.useUploadedModel,
                    child: Container(
                      foregroundDecoration: state.usingUploadedModel
                          ? BoxDecoration(
                              border: Border.all(
                                color: scheme.onSurface,
                                width: 2,
                              ),
                            )
                          : null,
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: AppImage.memory(bytes, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              for (
                var i = state.uploadedModelPhotos.length;
                i < maxWizardPhotos;
                i++
              )
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }
}
