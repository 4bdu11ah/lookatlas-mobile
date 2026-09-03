import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/shared/widgets/app_bottom_sheet.dart';

void main() {
  testWidgets('app bottom sheets respect the top safe area by default', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppBottomSheet<void>(
              context,
              isScrollControlled: true,
              builder: (_) => const SizedBox.expand(
                key: ValueKey('sheet-content'),
              ),
            ),
            child: const Text('Open sheet'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    final logicalTopPadding =
        tester.view.padding.top / tester.view.devicePixelRatio;
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('sheet-content'))).dy,
      logicalTopPadding,
    );
  });
}
