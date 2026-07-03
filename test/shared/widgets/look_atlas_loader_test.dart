import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/shared/widgets/look_atlas_loader.dart';

void main() {
  // The loader animates forever, so tests use pump() with a duration,
  // never pumpAndSettle().
  testWidgets('renders and animates without errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LookAtlasLoader(
          title: 'Signing you in',
          subtitle: 'This only takes a moment',
        ),
      ),
    );

    expect(find.text('Signing you in'), findsOneWidget);
    expect(find.text('This only takes a moment'), findsOneWidget);

    // Frames before, during and after convergence must not throw.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('shows the static wordmark when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: LookAtlasLoader()),
      ),
    );

    expect(find.text('Look Atlas'), findsOneWidget);
  });
}
