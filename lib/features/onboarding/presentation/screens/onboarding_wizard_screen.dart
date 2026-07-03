import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/calibrate_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/intro_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/model_step.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/steps/product_step.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';

/// The pre-login free-shoot wizard, currently trimmed to end at the model
/// step: intro -> product -> choose model -> sign-up. The director, review
/// and post-shoot screens are parked in `parked_features/` (to be pushed
/// separately); `./restore_parked_features.sh` restores this file to the
/// full six-step flow.
class OnboardingWizardScreen extends ConsumerWidget {
  const OnboardingWizardScreen({super.key});

  void _continue(BuildContext context, WidgetRef ref) {
    final state = ref.read(wizardControllerProvider);
    if (state.step == WizardStep.product &&
        state.productPhase == ProductPhase.upload &&
        state.photos.isNotEmpty &&
        !state.allAnglesTagged) {
      AppSnackBar.show(context, 'Tag each photo with an angle to continue.');
      return;
    }
    // Funnel currently ends at the model step — hand off to sign-up.
    if (state.step == WizardStep.model) {
      context.go(AppRoutes.signUp);
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                  key: ValueKey((
                    state.step,
                    state.step == WizardStep.product
                        ? state.productPhase
                        : null,
                  )),
                  child: switch (state.step) {
                    WizardStep.intro => const IntroStep(),
                    WizardStep.product => ProductStep(
                      phase: state.productPhase,
                    ),
                    WizardStep.calibrate => const CalibrateStep(),
                    WizardStep.model => const ModelStep(),
                    // Parked steps — unreachable while the funnel ends at
                    // the model step (restore_parked_features.sh).
                    WizardStep.director ||
                    WizardStep.review => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
            // The intro step sells with its own full-width CTA instead of the
            // Back/Continue bar.
            if (state.step != WizardStep.intro)
              WizardNavBar(
                onBack: () => _back(context, ref),
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
