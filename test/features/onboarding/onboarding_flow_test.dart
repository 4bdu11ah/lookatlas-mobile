import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';

import '../../helpers/fake_repositories.dart';

// NOTE: the funnel is currently trimmed to end at the model step; the
// director/review/generation/swipe/results/paywall screens and their tests
// are parked in `parked_features/` (restore_parked_features.sh brings back
// the full-flow test suite).

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

  testWidgets(
    'wizard walks intro → product → model, then hands off to sign-up',
    (tester) async {
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

      // Step 2A — category picker; picking only enables Continue.
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

      // Inject photos instead of driving the native picker; the second one
      // is untagged so the angle dropdown gets exercised.
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

      // Step 4 — model library, served by the (overridden) API provider.
      expect(find.text('Choose a model'), findsOneWidget);
      await tester.ensureVisible(find.text('Amara'));
      await tester.tap(find.text('Amara'));
      await tester.pump();
      expect(
        container.read(wizardControllerProvider).selectedModel?.name,
        'Amara',
      );

      // Continue after choosing a model ends the trimmed funnel at sign-up.
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SignUpScreen), findsOneWidget);

      await teardownTree(tester);
    },
  );
}
