import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';

void main() {
  testWidgets('AppOutlinedButton shows label and invokes callback', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppOutlinedButton(
            label: 'Cancel',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));

    expect(pressed, isTrue);
  });

  testWidgets('AppOutlinedButton supports compact icon actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: AppOutlinedButton(
              label: 'Reset',
              icon: Icons.refresh,
              onPressed: () {},
              fitToContent: true,
              height: 34,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(tester.getSize(find.byType(AppOutlinedButton)).height, 34);
  });

  testWidgets('AppOutlinedButton supports a trailing icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppOutlinedButton(
            label: 'Next',
            icon: Icons.arrow_forward,
            iconAlignment: IconAlignment.end,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getCenter(find.text('Next')).dx,
      lessThan(tester.getCenter(find.byIcon(Icons.arrow_forward)).dx),
    );
  });

  testWidgets('AppOutlinedButton rotates its icon by the supplied angle', (
    tester,
  ) async {
    const angle = math.pi / 4;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppOutlinedButton(
            label: 'Launch',
            icon: Icons.arrow_forward,
            iconAngle: angle,
            onPressed: () {},
          ),
        ),
      ),
    );

    final rotation = tester.widget<Transform>(
      find.ancestor(
        of: find.byIcon(Icons.arrow_forward),
        matching: find.byType(Transform),
      ),
    );
    expect(rotation.transform.entry(0, 0), closeTo(math.cos(angle), 0.0001));
    expect(rotation.transform.entry(1, 0), closeTo(math.sin(angle), 0.0001));
  });

  testWidgets('AppOutlinedButton fitToContent shrinks in narrow space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 90,
            child: AppOutlinedButton(
              label: 'View all shoots',
              fitToContent: true,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
