import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/controllers/onboarding_submission_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';

class UserModelUploadTab extends ConsumerWidget {
  const UserModelUploadTab({
    required this.state,
    required this.isSavingModel,
    required this.onUpload,
    super.key,
  });

  final WizardState state;
  final bool isSavingModel;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModels = ref.watch(onboardingUserModelsProvider);
    final uploadedModelId = ref.watch(
      onboardingSubmissionControllerProvider.select((value) => value.modelId),
    );
    return Column(
      spacing: 20,
      children: [
        _UploadPicker(
          isUploading: state.uploadingModel || isSavingModel,
          onUpload: onUpload,
        ),
        if (state.uploadedModelPhotos.isNotEmpty) _LocalPhotos(state: state),
        switch (userModels) {
          AsyncData(:final value) when value.isNotEmpty => _UserModelGrid(
            models: value,
            selectedModelId: state.selectedUserModel?.id ?? uploadedModelId,
            onSelect: ref
                .read(wizardControllerProvider.notifier)
                .selectUserModel,
          ),
          AsyncError() => _UserModelsError(
            onRetry: () => ref.invalidate(onboardingUserModelsProvider),
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _UploadPicker extends StatelessWidget {
  const _UploadPicker({required this.isUploading, required this.onUpload});

  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (isUploading) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const BarSpinner(size: 28),
              Text(
                'Uploading...',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onUpload,
      child: DashedBorder(
        color: scheme.outline,
        radius: 12,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: AppTypography.semiBold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Up to $maxModelPhotos photos of the same person from '
                'different angles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalPhotos extends ConsumerWidget {
  const _LocalPhotos({required this.state});

  final WizardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'Your uploaded model',
          style: TextStyle(
            fontSize: 14,
            fontWeight: AppTypography.medium,
            color: scheme.onSurface,
          ),
        ),
        Row(
          spacing: 12,
          children: [
            for (final bytes in state.uploadedModelPhotos)
              Expanded(
                child: GestureDetector(
                  onTap: ref
                      .read(wizardControllerProvider.notifier)
                      .useUploadedModel,
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
              var index = state.uploadedModelPhotos.length;
              index < maxModelPhotos;
              index++
            )
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}

class _UserModelGrid extends StatelessWidget {
  const _UserModelGrid({
    required this.models,
    required this.selectedModelId,
    required this.onSelect,
  });

  final List<OnboardingUserModel> models;
  final String? selectedModelId;
  final ValueChanged<OnboardingUserModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'Your custom models',
          style: TextStyle(
            fontSize: 14,
            fontWeight: AppTypography.medium,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 4,
          ),
          itemCount: models.length,
          itemBuilder: (context, index) {
            final model = models[index];
            return _UserModelCard(
              model: model,
              selected: selectedModelId == model.id,
              onTap: () => onSelect(model),
            );
          },
        ),
      ],
    );
  }
}

class _UserModelCard extends StatelessWidget {
  const _UserModelCard({
    required this.model,
    required this.selected,
    required this.onTap,
  });

  final OnboardingUserModel model;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (model.imageUrl.isNotEmpty)
              ShotImage(model.imageUrl)
            else
              ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person_outline,
                  size: 40,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: AppColors.blackAlpha70,
                child: Text(
                  model.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserModelsError extends StatelessWidget {
  const _UserModelsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Could not refresh custom models.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
