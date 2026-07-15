import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/workshop/presentation/screens/workshop_screen.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';

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
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (imagePicker != null)
            imagePickerProvider.overrideWithValue(imagePicker),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WorkshopScreen(),
        ),
      ),
    );
    await tester.pump();
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
      image: XFile('/picked/gallery-reference.jpg'),
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
    expect(find.text('(Optional, up to 4)'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('camera choice captures and adds a reference', (tester) async {
    final imagePicker = _FakeImagePicker(
      image: XFile('/captured/camera-reference.jpg'),
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
    expect(find.text('(Optional, up to 4)'), findsOneWidget);
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
    expect(find.text('(Optional, up to 4)'), findsOneWidget);
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
    expect(find.text('(Optional, up to 4)'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('unlocks and generates an edit from a prompt', (tester) async {
    final imagePicker = _FakeImagePicker(
      image: await _assetXFile('assets/images/onboarding/step-model.jpg'),
    );
    await pumpWorkshop(tester, imagePicker: imagePicker);

    expect(
      find.textContaining('Reshape any photo with a sentence'),
      findsOneWidget,
    );
    expect(find.text('Click or drop a base image'), findsOneWidget);

    final generateButton = find.byKey(const Key('workshop-generate-button'));
    final uploadTile = find.byKey(const Key('workshop-upload-tile'));

    await tester.ensureVisible(generateButton);
    await tester.tap(generateButton);
    await tester.pumpAndSettle();
    expect(find.text('Unlock Workshop'), findsOneWidget);

    await tester.tap(find.text('Upgrade to continue'));
    await tester.pumpAndSettle();

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
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.text('Edit complete'), findsOneWidget);
    await tester.ensureVisible(find.text('Use as base'));
    expect(find.text('Use as base'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
  });
}
