import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/shared/widgets/app_dotted_border.dart';

void main() {
  testWidgets('AppDottedBorder preserves its child size and content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppDottedBorder(
            child: SizedBox(
              width: 180,
              height: 80,
              child: Text('Upload'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Upload'), findsOneWidget);
    expect(tester.getSize(find.byType(AppDottedBorder)), const Size(180, 80));
  });

  testWidgets('AppDottedBorder controls dot width separately from thickness', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppDottedBorder(
            color: Colors.black,
            strokeWidth: 1.5,
            dotWidth: 8,
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      ),
    );

    final customPaint = find.descendant(
      of: find.byType(AppDottedBorder),
      matching: find.byType(CustomPaint),
    );
    final renderObject = tester.renderObject<RenderCustomPaint>(customPaint);

    expect(
      renderObject,
      paints..line(
        p1: const Offset(0.75, 0.75),
        p2: const Offset(8.75, 0.75),
        color: Colors.black,
        strokeWidth: 1.5,
      ),
    );
  });
}
