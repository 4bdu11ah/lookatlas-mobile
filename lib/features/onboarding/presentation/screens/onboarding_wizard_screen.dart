import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/controllers/onboarding_submission_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/calibrate_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/director_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/intro_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/model_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/product_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/review_step.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';

/// The pre-login free-shoot wizard (screens 01–06 of the onboarding mockups).
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (ref.read(authRepositoryProvider).currentUser == null) return;
    try {
      final responses = await Future.wait([
        ref.read(onboardingStatusProvider.future),
        ref.read(onboardingProductsProvider.future),
      ]);
      final status = responses[0] as OnboardingStatus;
      final products = responses[1] as List<OnboardingProduct>;
      if (!mounted) return;
      if (products.isNotEmpty) {
        ref
            .read(onboardingSubmissionControllerProvider.notifier)
            .restoreProductId(products.first.id);
      }
      final jobStatus = status.onboardingJobStatus?.toLowerCase();
      if ({'generating', 'enqueued', 'processing'}.contains(jobStatus)) {
        context.go(AppRoutes.onboardingSwipe);
        return;
      }
      if (jobStatus == 'completed') {
        context.go(AppRoutes.onboardingSwipe);
        return;
      }
      if (status.freeShootUsed) {
        context.go(AppRoutes.onboardingActivate);
        return;
      }
      await ref.read(updateOnboardingStatusUseCaseProvider)(
        OnboardingTrackingStatus.onboarding,
      );
    } on Object {
      // Status bootstrap failure is recoverable. Wizard remains usable and
      // the first mutating API call will surface a concrete server error.
    }
  }

  void _continue(BuildContext context, WidgetRef ref) {
    final state = ref.read(wizardControllerProvider);
    if (state.step == WizardStep.product &&
        state.productPhase == ProductPhase.upload &&
        state.photos.isNotEmpty &&
        !state.allAnglesTagged) {
      AppSnackBar.show(context, 'Tag each photo with an angle to continue.');
      return;
    }
    final moved = ref.read(wizardControllerProvider.notifier).next();
    if (!moved && state.step == WizardStep.product) {
      AppSnackBar.show(
        context,
        state.productPhase == ProductPhase.category
            ? 'Pick a category to continue.'
            : 'Add at least one photo to continue.',
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
    final state = ref.watch(wizardControllerProvider);
    final scheme = Theme.of(context).colorScheme;

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
                onContinue: state.canContinue
                    ? () => _continue(context, ref)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
