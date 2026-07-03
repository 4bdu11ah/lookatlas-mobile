import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester,
    void Function(ImageSource?) onResult,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  onResult(await showImageSourceSheet(context));
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('offers camera and gallery and returns the choice', (
    tester,
  ) async {
    ImageSource? result;
    await pumpHost(tester, (r) => result = r);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);

    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(result, ImageSource.gallery);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(result, ImageSource.camera);
  });

  testWidgets('cancel dismisses without a choice', (tester) async {
    ImageSource? result = ImageSource.camera;
    await pumpHost(tester, (r) => result = r);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Take a photo'), findsNothing);
  });
}
