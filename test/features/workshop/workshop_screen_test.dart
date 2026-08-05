import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/features/workshop/di/workshop_providers.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/presentation/screens/workshop_screen.dart';
import 'package:look_atlas/services/image_save_service.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

import '../../helpers/fake_repositories.dart';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.image, this.error});

  final XFile? image;
  final Exception? error;
  ImageSource? lastSource;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    if (error != null) throw error!;
    return image;
  }
}

class _FakeImageSaveService extends ImageSaveService {
  Uint8List? savedBytes;
  String? savedFileName;

  @override
  Future<void> save(Uint8List bytes, {required String fileName}) async {
    savedBytes = bytes;
    savedFileName = fileName;
  }
}

Future<XFile> _assetXFile(String path) async {
  final data = await rootBundle.load(path);
  return XFile.fromData(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    path: path,
  );
}

void main() {
  Future<void> pumpWorkshop(
    WidgetTester tester, {
    ImagePicker? imagePicker,
    FakeWorkshopRepository? repository,
    _FakeImageSaveService? imageSaveService,
    bool isPremium = false,
    bool settle = true,
  }) async {
    final workshopRepository = repository ?? FakeWorkshopRepository();
    final saveService = imageSaveService ?? _FakeImageSaveService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workshopRepositoryProvider.overrideWithValue(workshopRepository),
          imageSaveServiceProvider.overrideWithValue(saveService),
          isPremiumProvider.overrideWithValue(isPremium),
          if (imagePicker != null)
            imagePickerProvider.overrideWithValue(imagePicker),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WorkshopScreen(),
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

  testWidgets('reference add opens camera and gallery choices', (tester) async {
    await pumpWorkshop(tester);

    final addReference = find.byKey(
      const Key('workshop-reference-add-button'),
    );
    await tester.ensureVisible(addReference);
    await tester.tap(addReference);
    await tester.pumpAndSettle();

    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('base image opens camera and gallery choices', (tester) async {
    await pumpWorkshop(tester);

    final baseImage = find.byKey(const Key('workshop-upload-tile'));
    await tester.ensureVisible(baseImage);
    await tester.tap(baseImage);
    await tester.pumpAndSettle();

    expect(find.text('Add a base image'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('gallery choice sets the base image', (tester) async {
    final imagePicker = _FakeImagePicker(
      image: await _assetXFile('assets/images/onboarding/step-model.jpg'),
    );
    await pumpWorkshop(tester, imagePicker: imagePicker);

    final baseImage = find.byKey(const Key('workshop-upload-tile'));
    await tester.ensureVisible(baseImage);
    await tester.tap(baseImage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(imagePicker.lastSource, ImageSource.gallery);
    expect(
      find.byKey(const Key('workshop-base-image-preview')),
      findsOneWidget,
    );
    expect(find.text('Click or drop a base image'), findsNothing);
    expect(find.text('Landscape'), findsOneWidget);
  });

  testWidgets('edit modes appear only after selecting a base image', (
    tester,
  ) async {
    final imagePicker = _FakeImagePicker(
      image: await _assetXFile('assets/images/onboarding/step-model.jpg'),
    );
    await pumpWorkshop(tester, imagePicker: imagePicker);

    expect(find.text('Lock this image'), findsNothing);
    expect(find.text('Use as inspiration'), findsNothing);

    final baseImage = find.byKey(const Key('workshop-upload-tile'));
    await tester.ensureVisible(baseImage);
    await tester.tap(baseImage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Lock this image'), findsOneWidget);
    expect(find.text('Use as inspiration'), findsOneWidget);
  });

  testWidgets('new base images default to lock mode and show its tag', (
    tester,
  ) async {
    final imagePicker = _FakeImagePicker(
      image: await _assetXFile('assets/images/onboarding/step-model.jpg'),
    );
    await pumpWorkshop(tester, imagePicker: imagePicker);

    final baseImage = find.byKey(const Key('workshop-upload-tile'));
    await tester.ensureVisible(baseImage);
    await tester.tap(baseImage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('workshop-default-mode-tag')),
      findsOneWidget,
    );
    final lockMode = find.byKey(const Key('workshop-mode-lock'));
    final lockIcon = find.descendant(
      of: lockMode,
      matching: find.byIcon(Icons.lock_outline),
    );
    expect(tester.widget<Icon>(lockIcon).color, Colors.white);

    final inspirationMode = find.byKey(
      const Key('workshop-mode-inspiration'),
    );
    await tester.ensureVisible(inspirationMode);
    await tester.tap(inspirationMode);
    await tester.pump();
    expect(tester.widget<Icon>(lockIcon).color, isNot(Colors.white));

    await tester.ensureVisible(baseImage);
    await tester.tap(baseImage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(tester.widget<Icon>(lockIcon).color, Colors.white);
  });

  testWidgets('close button removes the selected base image', (tester) async {
    final imagePicker = _FakeImagePicker(
      image: await _assetXFile('assets/images/onboarding/step-model.jpg'),
    );
    await pumpWorkshop(tester, imagePicker: imagePicker);

    final baseImage = find.byKey(const Key('workshop-upload-tile'));
    await tester.ensureVisible(baseImage);
    await tester.tap(baseImage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('workshop-base-image-remove-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Click or drop a base image'), findsOneWidget);
    expect(find.text('Lock this image'), findsNothing);
    expect(find.text('Use as inspiration'), findsNothing);
    expect(find.text('Take a photo'), findsNothing);
  });

  testWidgets('selected base image can be replaced from the camera', (
    tester,
  ) async {
    final imagePicker = _FakeImagePicker(
      image: await _assetXFile(
        'assets/images/onboarding/showcase-dress-before.jpg',
      ),
    );
    await pumpWorkshop(tester, imagePicker: imagePicker);

    final baseImage = find.byKey(const Key('workshop-upload-tile'));
    await tester.ensureVisible(baseImage);
    await tester.tap(baseImage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    await tester.tap(baseImage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(imagePicker.lastSource, ImageSource.camera);
    expect(
      find.byKey(const Key('workshop-base-image-preview')),
      findsOneWidget,
    );
    expect(find.text('Portrait'), findsOneWidget);
  });

  testWidgets('gallery choice adds the picked reference', (tester) async {
    final imagePicker = _FakeImagePicker(
      image: await _assetXFile('assets/images/onboarding/step-model.jpg'),
    );
    await pumpWorkshop(tester, imagePicker: imagePicker);

    final addReference = find.byKey(
      const Key('workshop-reference-add-button'),
    );
    await tester.ensureVisible(addReference);
    await tester.tap(addReference);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(imagePicker.lastSource, ImageSource.gallery);
    expect(find.text('(optional, up to 4)'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('camera choice captures and adds a reference', (tester) async {
    final imagePicker = _FakeImagePicker(
      image: await _assetXFile('assets/images/onboarding/step-model.jpg'),
    );
    await pumpWorkshop(tester, imagePicker: imagePicker);

    final addReference = find.byKey(
      const Key('workshop-reference-add-button'),
    );
    await tester.ensureVisible(addReference);
    await tester.tap(addReference);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(imagePicker.lastSource, ImageSource.camera);
    expect(find.text('(optional, up to 4)'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('native picker cancellation leaves references unchanged', (
    tester,
  ) async {
    final imagePicker = _FakeImagePicker();
    await pumpWorkshop(tester, imagePicker: imagePicker);

    final addReference = find.byKey(
      const Key('workshop-reference-add-button'),
    );
    await tester.ensureVisible(addReference);
    await tester.tap(addReference);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(imagePicker.lastSource, ImageSource.gallery);
    expect(find.text('(optional, up to 4)'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('picker failure shows the workshop error alert', (tester) async {
    final imagePicker = _FakeImagePicker(error: Exception('picker failed'));
    await pumpWorkshop(tester, imagePicker: imagePicker);

    final addReference = find.byKey(
      const Key('workshop-reference-add-button'),
    );
    await tester.ensureVisible(addReference);
    await tester.tap(addReference);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not open your camera or photo library.'),
      findsOneWidget,
    );
    expect(find.text('(optional, up to 4)'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('premium user generates an edit through the repository', (
    tester,
  ) async {
    final imagePicker = _FakeImagePicker(
      image: await _assetXFile('assets/images/onboarding/step-model.jpg'),
    );
    final repository = FakeWorkshopRepository();
    await pumpWorkshop(
      tester,
      imagePicker: imagePicker,
      repository: repository,
      isPremium: true,
    );

    expect(
      find.textContaining('Reshape any photo with a sentence'),
      findsOneWidget,
    );
    expect(find.text('Click or drop a base image'), findsOneWidget);

    final generateButton = find.byKey(const Key('workshop-generate-button'));
    final uploadTile = find.byKey(const Key('workshop-upload-tile'));

    await tester.ensureVisible(uploadTile);
    await tester.tap(uploadTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Place the model at a Paris cafe at golden hour.',
    );
    await tester.pump();

    await tester.ensureVisible(generateButton);
    await tester.tap(generateButton);
    await tester.pumpAndSettle();

    expect(repository.lastRequest?.mode, WorkshopEditMode.lock);
    expect(repository.lastRequest?.prompt, contains('Paris cafe'));
    expect(repository.lastRequest?.base.bytes, isNotEmpty);
    await tester.ensureVisible(find.text('Use as base'));
    expect(find.text('Use as base'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('history preview deletes through the repository', (tester) async {
    const generation = WorkshopGeneration(
      id: 'history-1',
      status: WorkshopGenerationStatus.completed,
      prompt: 'Make it editorial.',
      imageUrl: 'https://example.com/history.jpg',
    );
    final repository = FakeWorkshopRepository(history: [generation]);
    await pumpWorkshop(tester, repository: repository, isPremium: true);

    final history = find.byKey(const Key('workshop-history-history-1'));
    await tester.ensureVisible(history);
    await tester.tap(history);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final appDialog = tester.widget<AppDialog>(find.byType(AppDialog));
    expect(appDialog.config, same(AppDialogConfig.standard));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Delete generation?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.deletedGenerationId, 'history-1');
    expect(find.text('Generation deleted.'), findsOneWidget);
  });

  testWidgets('history preview does not replace current result', (
    tester,
  ) async {
    const generation = WorkshopGeneration(
      id: 'history-1',
      status: WorkshopGenerationStatus.completed,
      prompt: 'Make it editorial.',
      imageUrl: 'https://example.com/history.jpg',
    );
    await pumpWorkshop(
      tester,
      repository: FakeWorkshopRepository(history: [generation]),
      isPremium: true,
    );

    final history = find.byKey(const Key('workshop-history-history-1'));
    await tester.ensureVisible(history);
    await tester.tap(history);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workshop-preview-close')));
    await tester.pumpAndSettle();

    final emptyResult = find.text('Your edit will appear here');
    await tester.ensureVisible(emptyResult);
    expect(emptyResult, findsOneWidget);
  });

  testWidgets('history preview can download and use result as base', (
    tester,
  ) async {
    const generation = WorkshopGeneration(
      id: 'history-1',
      status: WorkshopGenerationStatus.completed,
      prompt: 'Make it editorial.',
      imageUrl: 'https://example.com/history.jpg',
    );
    final repository = FakeWorkshopRepository(history: [generation]);
    final imageSaveService = _FakeImageSaveService();
    await pumpWorkshop(
      tester,
      repository: repository,
      imageSaveService: imageSaveService,
      isPremium: true,
    );

    final history = find.byKey(const Key('workshop-history-history-1'));
    await tester.ensureVisible(history);
    await tester.tap(history);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('workshop-history-preview')), findsOneWidget);
    expect(find.text('Make it editorial.'), findsOneWidget);
    expect(find.text('1 of 1'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('workshop-preview-download')),
          )
          .dy,
      tester.getTopLeft(find.byKey(const Key('workshop-preview-use-base'))).dy,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('workshop-preview-delete'))).dy,
      greaterThan(
        tester
            .getBottomLeft(
              find.byKey(const Key('workshop-preview-download')),
            )
            .dy,
      ),
    );
    await tester.tap(find.text('Download').last);
    await tester.pumpAndSettle();
    expect(find.text('Image saved to Photos.'), findsOneWidget);
    expect(imageSaveService.savedBytes, isNotEmpty);
    expect(imageSaveService.savedFileName, 'look-atlas-history-1.png');

    await tester.tap(find.text('Use as base').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('workshop-base-image-preview')),
      findsOneWidget,
    );
    expect(find.text('Result set as base image.'), findsOneWidget);
    final emptyResult = find.text('Your edit will appear here');
    await tester.ensureVisible(emptyResult);
    expect(emptyResult, findsOneWidget);
  });

  testWidgets('active generation polls detail every three seconds', (
    tester,
  ) async {
    const active = WorkshopGeneration(
      id: 'active-1',
      status: WorkshopGenerationStatus.processing,
      prompt: 'Change the background.',
    );
    const completed = WorkshopGeneration(
      id: 'active-1',
      status: WorkshopGenerationStatus.completed,
      prompt: 'Change the background.',
      imageUrl: 'https://example.com/completed.jpg',
    );
    final repository = FakeWorkshopRepository(
      active: active,
      history: [completed],
    );
    await pumpWorkshop(
      tester,
      repository: repository,
      isPremium: true,
      settle: false,
    );

    expect(find.text('Reading your reference…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ShimmerBox), findsWidgets);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(repository.detailCalls, 1);
    await tester.ensureVisible(find.text('Use as base'));
    expect(find.text('Use as base'), findsOneWidget);
  });
}
