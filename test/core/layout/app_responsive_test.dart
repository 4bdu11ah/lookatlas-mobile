import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/layout/app_responsive.dart';

void main() {
  group('AppResponsive.contentMaxWidthFor', () {
    test('uses the phone width below the compact breakpoint', () {
      expect(AppResponsive.contentMaxWidthFor(390), 430);
    });

    test('uses the tablet width at and above the compact breakpoint', () {
      expect(AppResponsive.contentMaxWidthFor(600), 720);
      expect(AppResponsive.contentMaxWidthFor(1280), 720);
    });
  });

  group('AppResponsive.gridColumnsFor', () {
    test('uses available width without exceeding the configured limit', () {
      expect(AppResponsive.gridColumnsFor(219), 1);
      expect(AppResponsive.gridColumnsFor(700), 3);
      expect(AppResponsive.gridColumnsFor(2000), 3);
    });
  });

  testWidgets('ResponsiveContent keeps the tablet width on large screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContent(
            child: SizedBox(key: ValueKey('content'), width: double.infinity),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('content'))).width, 720);
  });
}
