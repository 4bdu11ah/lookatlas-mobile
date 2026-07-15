import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/shared/widgets/app_text_button.dart';

void main() {
  testWidgets('AppTextButton shows its icon and invokes its callback', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextButton(
            icon: Icons.lightbulb_outline,
            label: 'How it works',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
    expect(tester.getSize(find.byType(AppTextButton)).height, 42);

    await tester.tap(find.text('How it works'));

    expect(pressed, isTrue);
  });

  testWidgets('AppTextButton ignores taps while disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppTextButton(
            icon: Icons.lightbulb_outline,
            label: 'How it works',
            onPressed: null,
          ),
        ),
      ),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));

    expect(inkWell.onTap, isNull);
  });

  testWidgets('AppTextButton fits its width to content when requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: AppTextButton(
              icon: Icons.lightbulb_outline,
              label: 'How it works',
              onPressed: () {},
              fitToContent: true,
            ),
          ),
        ),
      ),
    );

    final buttonWidth = tester.getSize(find.byType(AppTextButton)).width;
    final labelWidth = tester.getSize(find.text('How it works')).width;

    expect(buttonWidth, closeTo(labelWidth + 50, 0.1));
  });
}
