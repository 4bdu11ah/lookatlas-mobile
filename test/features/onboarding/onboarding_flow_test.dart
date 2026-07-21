import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:look_atlas/features/billing/di/billing_api_providers.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/swipe_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/activate_paywall_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/generation_progress_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/onetime_success_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/starting_shoot_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/swipe_results_screen.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/swipe_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';

import '../../helpers/fake_repositories.dart';

/// A minimal valid 1x1 transparent PNG, so Image.memory can decode the fake
/// wizard photos.
final Uint8List kTinyPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x00, 0x02, 0x00, //
  0x00, 0x05, 0x00, 0x01, 0xE9, 0xFA, 0xDC, 0xD8, 0x00, 0x00, 0x00, 0x00, //
  0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

void main() {
  late ProviderContainer container;

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
        // No network in widget tests: serve the bundled starter library.
        lookAtlasModelsProvider.overrideWith(
          (ref) async => fallbackLibraryModels,
        ),
        billingPlansProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: container.read(routerProvider)),
      ),
    );
    return container.read(routerProvider);
  }

  /// Unmounts the tree so periodic timers owned by screens are cancelled,
  /// then advances the clock so one-shot timers scheduled by image caching
  /// fire before the pending-timer check.
  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('wizard walks intro → product → model → director → review', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.go(AppRoutes.onboarding);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Step 1 — intro.
    expect(find.byType(OnboardingWizardScreen), findsOneWidget);
    expect(find.text('Get My Free Photos'), findsOneWidget);
    await tester.ensureVisible(find.text('Get My Free Photos'));
    await tester.tap(find.text('Get My Free Photos'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Step 2A — category picker; picking a category only enables Continue,
    // it does not advance by itself.
    expect(find.text('What are you shooting?'), findsOneWidget);
    await tester.ensureVisible(find.text('Tops'));
    await tester.tap(find.text('Tops'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('What are you shooting?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Step 2B — upload. The drop zone opens the camera/gallery chooser.
    expect(find.text('Upload your tops photos'), findsOneWidget);
    await tester.ensureVisible(find.text('Tap to add photos'));
    await tester.tap(find.text('Tap to add photos'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Inject photos instead of driving the native picker; the second one is
    // untagged so the angle dropdown gets exercised.
    container.read(wizardControllerProvider.notifier).addPhotos([
      WizardPhoto(bytes: kTinyPng, angle: 'Front'),
      WizardPhoto(bytes: kTinyPng),
    ]);
    await tester.pump();
    expect(find.text('Select angles'), findsOneWidget);
    await tester.ensureVisible(find.text('Select angle'));
    await tester.tap(find.text('Select angle'));
    await tester.pumpAndSettle();
    // 'Side' is unique on screen ('Back' also matches the nav button and
    // the angle-guidance example label).
    await tester.tap(find.text('Side'));
    await tester.pumpAndSettle();
    expect(find.text('Select angle'), findsNothing);
    expect(find.text('Side'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Step 4 — model (calibrate is feature-flagged off).
    expect(find.text('Choose a model'), findsOneWidget);
    await tester.ensureVisible(find.text('Amara'));
    await tester.tap(find.text('Amara'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Step 5 — director.
    expect(find.text('What should your photos look like?'), findsOneWidget);
    await tester.ensureVisible(find.text('Alex Chen'));
    await tester.tap(find.text('Alex Chen'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Step 6 — review.
    expect(find.text('Everything looks good'), findsOneWidget);
    expect(find.text('Start My Free Shoot'), findsOneWidget);
    expect(find.text('Alex Chen'), findsOneWidget);

    await tester.ensureVisible(find.text('Start My Free Shoot'));
    await tester.tap(find.text('Start My Free Shoot'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('director eye button opens full portfolio and can select style', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.go(AppRoutes.onboarding);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    container.read(wizardControllerProvider.notifier)
      ..next()
      ..selectCategory(ProductCategory.tops)
      ..next()
      ..addPhotos([
        WizardPhoto(bytes: kTinyPng, angle: 'Front'),
        WizardPhoto(bytes: kTinyPng, angle: 'Back'),
      ])
      ..next()
      ..selectModel(fallbackLibraryModels.first)
      ..next();
    expect(container.read(wizardControllerProvider).step, WizardStep.director);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('What should your photos look like?'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('The Story'), findsOneWidget);
    expect(find.text('Signature Approach'), findsOneWidget);
    expect(find.text('Use Director'), findsOneWidget);

    await tester.tap(find.text('Use Director'));
    await tester.pumpAndSettle();
    expect(
      container.read(wizardControllerProvider).selectedDirector?.id,
      'alex',
    );
    expect(find.text('Portfolio'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets(
    'starting loader hands off to generation, then to the swipe view',
    (tester) async {
      final router = await pumpApp(tester);
      container.read(generationControllerProvider.notifier).start();
      router.go(AppRoutes.onboardingStarting);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(StartingShootScreen), findsOneWidget);

      // The ring animation runs ~3.6s, then redirects to the grid.
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GenerationProgressScreen), findsOneWidget);
      expect(find.text('Creating your photos'), findsOneWidget);

      // One image completes every 900ms; 15 images + redirect delay.
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SwipeScreen), findsOneWidget);

      await teardownTree(tester);
    },
  );

  testWidgets('swiping through the deck lands on results with kept shots', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    container.read(generationControllerProvider.notifier).start();
    // Let the whole shoot finish so every card is ready.
    router.go(AppRoutes.onboardingSwipe);
    await tester.pump();
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(container.read(generationControllerProvider).isComplete, isTrue);
    expect(find.text('Your shoot is underway'), findsOneWidget);

    // Save 5, pass 10.
    for (var i = 0; i < 15; i++) {
      final key = i < 5
          ? const ValueKey('swipe-save')
          : const ValueKey('swipe-pass');
      await tester.tap(find.byKey(key));
      // Three pumps: start the release animation, run it to completion,
      // then rebuild with the next card.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(container.read(swipeControllerProvider).decisions.length, 15);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SwipeResultsScreen), findsOneWidget);
    expect(container.read(swipeControllerProvider).savedCount, 5);
    expect(find.textContaining('Your catalog is'), findsOneWidget);
    expect(find.text('Unlock my 5 photos in HD'), findsWidgets);

    // Silence the leftover milestone/proof timers.
    await teardownTree(tester);
  });

  testWidgets('activate shows the analyzing loader, then the paywall', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.go(AppRoutes.onboardingActivate);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ActivatePaywallScreen), findsOneWidget);
    expect(find.text('PLEASE HOLD'), findsOneWidget);

    // Loader runs 4.5s, then the paywall fades in.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Keep your shoot going.'), findsOneWidget);
    expect(find.text('Start Pro'), findsOneWidget);
    expect(find.text(r'Download in HD · $8.99'), findsOneWidget);

    expect(find.text('Start Studio'), findsOneWidget);
    expect(find.text(r'Save $240/yr'), findsOneWidget);
    await tester.tap(find.text('Monthly'));
    await tester.pump();
    expect(find.textContaining(r'$49'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('one-time success rejects a missing checkout session', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.go(AppRoutes.onboardingSuccess);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OnetimeSuccessScreen), findsOneWidget);
    expect(find.text("Payment didn't go through"), findsOneWidget);

    await teardownTree(tester);
  });
}
