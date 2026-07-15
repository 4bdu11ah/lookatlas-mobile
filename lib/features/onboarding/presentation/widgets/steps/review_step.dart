import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/constants/app_assets.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/swipe_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';

/// Wizard step 6 — review the Product / Model / Style picks and start the
/// free shoot (mockup 06).
class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({super.key});

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep> {
  int _productPhoto = 0;

  void _startShoot() {
    ref.read(generationControllerProvider.notifier).start();
    ref.read(swipeControllerProvider.notifier).reset();
    context.go(AppRoutes.onboardingStarting);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    final photos = state.photos;
    final photoIndex = photos.isEmpty
        ? 0
        : _productPhoto.clamp(0, photos.length - 1);

    Widget productImage;
    if (photos.isEmpty) {
      productImage = ShotImage(
        state.category?.imageUrl ?? AppAssets.stepUpload,
      );
    } else {
      productImage = AppImage.memory(
        photos[photoIndex].bytes,
        fit: BoxFit.cover,
      );
    }

    Widget modelImage;
    if (state.usingUploadedModel && state.uploadedModelPhotos.isNotEmpty) {
      modelImage = AppImage.memory(
        state.uploadedModelPhotos.first,
        fit: BoxFit.cover,
      );
    } else {
      modelImage = ShotImage(
        state.selectedModel?.imageUrl ?? AppAssets.stepModel,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 32,
        children: [
          const WizardStepHeader(
            title: 'Everything looks good',
            subtitle:
                'Your director will study your product, plan the shots, and '
                'bring your vision to life.',
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(
                  child: _ReviewColumn(
                    label: 'Product',
                    value: state.productName,
                    image: productImage,
                    overlay: photos.length > 1
                        ? _PhotoCycler(
                            onPrevious: () => setState(
                              () => _productPhoto =
                                  (photoIndex - 1 + photos.length) %
                                  photos.length,
                            ),
                            onNext: () => setState(
                              () => _productPhoto =
                                  (photoIndex + 1) % photos.length,
                            ),
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: _ReviewColumn(
                    label: 'Model',
                    value: state.modelName,
                    image: modelImage,
                  ),
                ),
                Expanded(
                  child: _ReviewColumn(
                    label: 'Style',
                    value: state.selectedDirector?.name ?? '—',
                    image: ShotImage(
                      state.selectedDirector?.imageUrl ??
                          AppAssets.stepGenerate,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              spacing: 16,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Your photos will be ready in about ',
                      ),
                      TextSpan(
                        text: '5 minutes',
                        style: TextStyle(
                          fontWeight: AppTypography.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  "Keep this tab open and we'll show you results as they "
                  "come in. We'll also send you an email when everything "
                  'is ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            spacing: 12,
            children: [
              WizardButton(
                label: 'Start My Free Shoot',
                trailing: Icons.arrow_forward,
                expand: true,
                onTap: _startShoot,
              ),
              Text(
                'Completely free. No credit card required.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.33,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewColumn extends StatelessWidget {
  const _ReviewColumn({
    required this.label,
    required this.value,
    required this.image,
    this.overlay,
  });

  final String label;
  final String value;
  final Widget image;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      spacing: 4,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(8),
                color: scheme.surfaceContainerHighest,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [image, if (overlay != null) overlay!],
              ),
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            height: 1.2,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: AppTypography.medium,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Left/right arrows over the product image to cycle uploaded photos.
class _PhotoCycler extends StatelessWidget {
  const _PhotoCycler({required this.onPrevious, required this.onNext});

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Arrow(icon: Icons.arrow_back, onTap: onPrevious),
        _Arrow(icon: Icons.arrow_forward, onTap: onNext),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: AppColors.white.withValues(alpha: 0.8),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 28,
            child: Icon(icon, size: 14, color: AppColors.inkAlpha70),
          ),
        ),
      ),
    );
  }
}
