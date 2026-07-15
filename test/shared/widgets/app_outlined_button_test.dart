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
}
