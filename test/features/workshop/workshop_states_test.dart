import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/features/workshop/di/workshop_providers.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/presentation/screens/workshop_screen.dart';
import 'package:look_atlas/services/image_save_service.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

import '../../helpers/fake_repositories.dart';

class _StateImagePicker extends ImagePicker {
  _StateImagePicker(this.image);

  final XFile image;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => image;
}

class _NoopImageSaveService extends ImageSaveService {
  @override
  Future<void> save(Uint8List bytes, {required String fileName}) async {}
}

Future<XFile> _testImage() async {
  final data = await rootBundle.load(
    'assets/images/onboarding/step-model.jpg',
  );
  return XFile.fromData(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    path: 'step-model.jpg',
  );
}

void main() {
  Future<void> pumpWorkshop(
    WidgetTester tester, {
    required FakeWorkshopRepository repository,
    bool isPremium = true,
    bool settle = true,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.workshop,
      routes: [
        GoRoute(
          path: AppRoutes.workshop,
          builder: (_, _) => const WorkshopScreen(),
        ),
        GoRoute(
          path: AppRoutes.workshopGuide,
          builder: (_, _) => const WorkshopGuideScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workshopRepositoryProvider.overrideWithValue(repository),
          imageSaveServiceProvider.overrideWithValue(
            _NoopImageSaveService(),
          ),
          imagePickerProvider.overrideWithValue(
            _StateImagePicker(await _testImage()),
          ),
          isPremiumProvider.overrideWithValue(isPremium),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
  }

  Future<void> prepareReady(WidgetTester tester) async {
    final upload = find.byKey(const Key('workshop-upload-tile'));
    await tester.ensureVisible(upload);
    await tester.tap(upload);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workshop-prompt-field')),
      'Replace the handbag and keep the lighting unchanged.',
    );
    await tester.pump();
  }

  testWidgets('initialLoad_keepsEditorVisible_andShowsHistorySkeletons', (
    tester,
  ) async {
    final load = Completer<Result<WorkshopWorkspace>>();
    final repository = FakeWorkshopRepository(onLoad: () => load.future);

    await pumpWorkshop(tester, repository: repository, settle: false);

    expect(find.text('Click or drop a base image'), findsOneWidget);
    expect(find.byType(ShimmerBox), findsNWidgets(3));

    load.complete(
      const Result.ok(WorkshopWorkspace(history: [])),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShimmerBox), findsNothing);
    expect(find.textContaining('Nothing yet.'), findsOneWidget);
  });

  testWidgets('guideButton_opensGuideScreen_andGotItReturns', (tester) async {
    await pumpWorkshop(tester, repository: FakeWorkshopRepository());

    await tester.tap(find.text('HOW DOES THIS WORK?'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkshopGuideScreen), findsOneWidget);
    expect(find.text('Workshop Guide'), findsOneWidget);
    expect(find.text('How Workshop works'), findsOneWidget);
    expect(find.text('One image, one prompt, one credit.'), findsOneWidget);
    expect(find.text('Lock this image'), findsWidgets);
    expect(find.text('Examples'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Got it'),
      600,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkshopScreen), findsOneWidget);
    expect(find.byType(WorkshopGuideScreen), findsNothing);
  });

  testWidgets('lockedGenerate_opensSubscriberPaywall', (tester) async {
    await pumpWorkshop(
      tester,
      repository: FakeWorkshopRepository(),
      isPremium: false,
    );
    final generate = find.byKey(const Key('workshop-generate-button'));
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pumpAndSettle();

    expect(find.text('SUBSCRIBER FEATURE'), findsOneWidget);
    expect(find.text('Edit any image in seconds.'), findsOneWidget);
    expect(find.text('View plans'), findsOneWidget);
  });

  testWidgets('generateWithoutBase_showsCanonicalValidation', (tester) async {
    await pumpWorkshop(tester, repository: FakeWorkshopRepository());
    final generate = find.byKey(const Key('workshop-generate-button'));
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pump();

    expect(find.text('Upload a base image first.'), findsOneWidget);
  });

  testWidgets('generateWithoutPrompt_showsCanonicalValidation', (tester) async {
    await pumpWorkshop(tester, repository: FakeWorkshopRepository());
    final upload = find.byKey(const Key('workshop-upload-tile'));
    await tester.ensureVisible(upload);
    await tester.tap(upload);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    final generate = find.byKey(const Key('workshop-generate-button'));
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pump();

    expect(
      find.text('Write a prompt describing the edit you want.'),
      findsOneWidget,
    );
  });

  testWidgets('overlongPrompt_showsCanonicalValidation', (tester) async {
    await pumpWorkshop(tester, repository: FakeWorkshopRepository());
    await prepareReady(tester);
    await tester.enterText(
      find.byKey(const Key('workshop-prompt-field')),
      List.filled(1001, 'x').join(),
    );
    await tester.pump();

    final generate = find.byKey(const Key('workshop-generate-button'));
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pump();

    expect(
      find.text('Prompt must be 1000 characters or fewer.'),
      findsOneWidget,
    );
  });

  testWidgets('generationLifecycle_showsStartingAndRotatingProgress', (
    tester,
  ) async {
    final response = Completer<Result<WorkshopGeneration>>();
    final repository = FakeWorkshopRepository(
      onGenerate: (_) => response.future,
    );
    await pumpWorkshop(tester, repository: repository);
    await prepareReady(tester);

    final generate = find.byKey(const Key('workshop-generate-button'));
    await tester.ensureVisible(generate);
    expect(tester.widget(generate), isA<PrimaryButton>());
    await tester.tap(generate);
    await tester.pump();

    final startingButton = tester.widget<PrimaryButton>(generate);
    expect(find.text('Starting…'), findsOneWidget);
    expect(startingButton.isLoading, isTrue);
    expect(startingButton.onPressed, isNull);
    expect(
      tester.widget<ButtonLoader>(find.byType(ButtonLoader)).color,
      AppColors.white,
    );
    expect(
      DefaultTextStyle.of(
        tester.element(find.text('Starting…')),
      ).style.color,
      AppColors.white,
    );
    expect(find.text('Your edit will appear here'), findsOneWidget);

    response.complete(
      const Result.ok(
        WorkshopGeneration(
          id: 'generation-1',
          status: WorkshopGenerationStatus.processing,
        ),
      ),
    );
    await tester.pump();
    final processingButton = tester.widget<PrimaryButton>(generate);
    expect(processingButton.isLoading, isFalse);
    expect(processingButton.onPressed, isNull);
    expect(find.text('Reading your reference…'), findsOneWidget);
    expect(find.textContaining('safe to leave this page'), findsOneWidget);

    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Composing the scene…'), findsOneWidget);
  });

  testWidgets('generationFailure_showsCanonicalErrorAndClearsProgress', (
    tester,
  ) async {
    final repository = FakeWorkshopRepository(
      onGenerate: (_) async => const Result.err(
        NetworkFailure('Rejected.', code: 'content_moderation'),
      ),
    );
    await pumpWorkshop(tester, repository: repository);
    await prepareReady(tester);

    final generate = find.byKey(const Key('workshop-generate-button'));
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The image or prompt was rejected by content moderation. Please adjust and try again — your credit was refunded.',
      ),
      findsOneWidget,
    );
    expect(find.text('Your edit will appear here'), findsOneWidget);
  });
}
