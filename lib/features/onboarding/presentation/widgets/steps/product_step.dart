import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/controllers/onboarding_submission_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';

part '../product_step_category_widgets.dart';
part '../product_step_photo_widgets.dart';

/// Wizard step 2 — product category picker, then photo upload with per-photo
/// angle tagging (mockup 02, states A–C). Stateless: every bit of state,
/// including the pick-in-flight flag, lives in [wizardControllerProvider].
class ProductStep extends ConsumerWidget {
  const ProductStep({required this.phase, super.key});

  /// Which sub-state to render. Passed in (rather than watched) so the
  /// outgoing copy of this widget keeps showing its own phase while the
  /// wizard's AnimatedSwitcher fades between the two.
  final ProductPhase phase;

  /// Camera-or-gallery chooser, then the pick itself via the controller.
  Future<void> _addPhotos(BuildContext context, WidgetRef ref) async {
    final source = await showImageSourceSheet(
      context,
      title: 'Add product photos',
    );
    if (source == null) return;
    final previousCount = ref.read(wizardControllerProvider).photos.length;
    final result = await ref
        .read(wizardControllerProvider.notifier)
        .addProductPhotosFrom(source);
    if (!context.mounted) return;
    final wizard = ref.read(wizardControllerProvider);
    if (wizard.photos.length > previousCount) {
      final saved = await ref
          .read(onboardingSubmissionControllerProvider.notifier)
          .saveProductPhotos(wizard);
      if (!context.mounted) return;
      if (!saved) {
        final failure = ref
            .read(onboardingSubmissionControllerProvider)
            .failure;
        AppSnackBar.showError(
          context,
          failure?.message ?? 'Could not upload your product photos.',
        );
      }
    }
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
    final isSavingProduct = ref.watch(
      onboardingSubmissionControllerProvider.select(
        (value) => value.isSavingProduct,
      ),
    );
    return phase == ProductPhase.category
        ? _CategoryPicker(
            selected: state.category,
            // Selecting only highlights the tile and enables Continue —
            // moving on is an explicit Continue tap.
            onSelect: (c) =>
                ref.read(wizardControllerProvider.notifier).selectCategory(c),
          )
        : _PhotoUpload(
            state: state,
            isSavingProduct: isSavingProduct,
            onAddPhotos: () => _addPhotos(context, ref),
          );
  }
}

// --- State A: category picker ----------------------------------------------
