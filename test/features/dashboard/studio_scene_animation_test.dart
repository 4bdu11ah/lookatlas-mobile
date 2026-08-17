import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/studio_scene_animation.dart';

void main() {
  test('studioProgress_nonLinearState_keepsFirstMissingStepActive', () {
    const progress = StudioProgress(
      addProduct: true,
      calibrate: false,
      calibrationOptional: false,
      pickAngles: false,
      createModel: true,
      chooseDirection: false,
      runShoot: false,
    );

    expect(progress.activeStep, StudioStep.calibrate);
    expect(progress.isDone(StudioStep.createModel), isTrue);
    expect(progress.doneCount, 2);
  });

  testWidgets('studioScene_reducedMotion_usesLivePainterWithoutGif', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ColoredBox(
            color: Colors.black,
            child: StudioSceneAnimation(progress: StudioProgress.empty()),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(Image), findsNothing);
    expect(
      find.bySemanticsLabel('Studio setup illustration, 0 of 6 steps complete'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
