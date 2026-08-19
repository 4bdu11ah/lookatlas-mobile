import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/controllers/onboarding_submission_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/calibrate_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/director_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/intro_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/model_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/product_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/review_step.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/look_atlas_loader.dart';

/// The authenticated free-shoot wizard (screens 01–06 of the mockups).
/// One route hosts all six steps; [wizardControllerProvider] owns which step
/// is visible and every selection, so state survives hot reloads and
/// navigation away and back.
class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  bool _isCheckingAccess = true;
  bool _accessCheckFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (ref.read(authRepositoryProvider).currentUser == null) return;
    setState(() {
      _isCheckingAccess = true;
      _accessCheckFailed = false;
    });
    try {
      final status = await ref.read(onboardingStatusProvider.future);
      if (!mounted) return;
      if (status.hasActiveSubscription) {
        context.go(AppRoutes.home);
        return;
      }
      final jobStatus = status.onboardingJobStatus?.toLowerCase();
      if ({'generating', 'enqueued', 'processing'}.contains(jobStatus)) {
        ref.read(generationControllerProvider.notifier).start();
        context.go(AppRoutes.onboardingSwipe);
        return;
      }
      if (jobStatus == 'completed') {
        ref.read(generationControllerProvider.notifier).start();
        context.go(AppRoutes.onboardingSwipe);
        return;
      }
      if (status.freeShootUsed) {
        context.go(AppRoutes.onboardingActivate);
        return;
      }
      setState(() => _isCheckingAccess = false);
      try {
        final products = await ref.read(onboardingProductsProvider.future);
        if (products.isNotEmpty) {
          ref
              .read(onboardingSubmissionControllerProvider.notifier)
              .restoreProductId(products.first.id);
        }
      } on Object {
        // Restoring a saved product is optional. Access was already checked.
      }
      try {
        await ref.read(updateOnboardingStatusUseCaseProvider)(
          OnboardingTrackingStatus.onboarding,
        );
      } on Object {
        // Funnel analytics must not block an already-authorized user.
      }
    } on Object {
      if (mounted) {
        setState(() {
          _isCheckingAccess = false;
          _accessCheckFailed = true;
        });
      }
    }
  }

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final state = ref.read(wizardControllerProvider);
    if (state.step == WizardStep.product &&
        state.productPhase == ProductPhase.upload &&
        state.photos.isNotEmpty &&
        !state.allAnglesTagged) {
      AppSnackBar.show(context, 'Tag each photo with an angle to continue.');
      return;
    }
    if (state.step == WizardStep.product &&
        state.productPhase == ProductPhase.upload) {
      final saved = await ref
          .read(onboardingSubmissionControllerProvider.notifier)
          .saveProductAngles(state);
      if (!context.mounted) return;
      if (!saved) {
        final failure = ref
            .read(onboardingSubmissionControllerProvider)
            .failure;
        AppSnackBar.showError(
          context,
          failure?.message ?? 'Could not save your product photo angles.',
        );
        return;
      }
    }
    final moved = ref.read(wizardControllerProvider.notifier).next();
    if (!moved && state.step == WizardStep.product) {
      AppSnackBar.show(
        context,
        state.productPhase == ProductPhase.category
            ? 'Pick a category to continue.'
            : 'Add at least two photos to continue.',
      );
    }
  }

  void _back(BuildContext context, WidgetRef ref) {
    final moved = ref.read(wizardControllerProvider.notifier).back();
    // Backing out of the first step leaves the funnel for sign-in.
    if (!moved) context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAccess) {
      return const Scaffold(body: Center(child: LookAtlasLoader()));
    }
    if (_accessCheckFailed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not check your onboarding status.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _bootstrap,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final state = ref.watch(wizardControllerProvider);
    final isSavingAsset = ref.watch(
      onboardingSubmissionControllerProvider.select(
        (value) => value.isSavingProduct || value.isSavingModel,
      ),
    );
    final uploadedModelId = ref.watch(
      onboardingSubmissionControllerProvider.select((value) => value.modelId),
    );
    final scheme = Theme.of(context).colorScheme;
    final isModelReady =
        !state.usingUploadedModel ||
        state.selectedUserModel != null ||
        uploadedModelId != null;

    final continueLabel =
        state.step == WizardStep.product &&
            state.productPhase == ProductPhase.upload &&
            state.photos.isNotEmpty &&
            !state.allAnglesTagged
        ? 'Select angles'
        : 'Continue';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            WizardProgressBar(fraction: state.progress),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.015),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(
                    (
                      state.step,
                      state.step == WizardStep.product
                          ? state.productPhase
                          : null,
                    ),
                  ),
                  child: switch (state.step) {
                    WizardStep.intro => const IntroStep(),
                    WizardStep.product => ProductStep(
                      phase: state.productPhase,
                    ),
                    WizardStep.calibrate => const CalibrateStep(),
                    WizardStep.model => const ModelStep(),
                    WizardStep.director => const DirectorStep(),
                    WizardStep.review => const ReviewStep(),
                  },
                ),
              ),
            ),
            // The intro step sells with its own full-width CTA instead of the
            // Back/Continue bar; the review step keeps only Back.
            if (state.step != WizardStep.intro)
              WizardNavBar(
                onBack: () => _back(context, ref),
                showContinue: state.step != WizardStep.review,
                continueLabel: continueLabel,
                onContinue: state.canContinue && isModelReady && !isSavingAsset
                    ? () => _continue(context, ref)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
