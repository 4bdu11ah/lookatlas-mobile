import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

void main() {
  // The spinner repeats forever, so tests use pump() with a duration,
  // never pumpAndSettle().
  testWidgets('BarSpinner renders four bars and animates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: BarSpinner())),
    );

    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BarSpinner),
        matching: find.byType(Opacity),
      ),
      findsNWidgets(4),
    );

    // A frame mid-cycle must not throw (animation is running).
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('ButtonLoader shows the spinner and optional text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: ButtonLoader(text: 'Signing in')),
      ),
    );

    expect(find.byType(BarSpinner), findsOneWidget);
    expect(find.text('Signing in'), findsOneWidget);
  });

  testWidgets('PrimaryButton swaps its label for the loader while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PrimaryButton(
            label: 'Sign in',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(ButtonLoader), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('PrimaryButton supports custom content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PrimaryButton(
            onPressed: () {},
            child: const Text('Custom content'),
          ),
        ),
      ),
    );

    expect(find.text('Custom content'), findsOneWidget);
  });

  testWidgets('PrimaryButton supports custom loading content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PrimaryButton(
            label: 'Generate',
            onPressed: () {},
            isLoading: true,
            loadingChild: const ButtonLoader(
              text: 'Starting…',
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    final loader = tester.widget<ButtonLoader>(find.byType(ButtonLoader));
    expect(find.text('Starting…'), findsOneWidget);
    expect(loader.color, Colors.white);
  });

  testWidgets('PrimaryButton fits its width to content when requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: Align(
              alignment: Alignment.topLeft,
              child: PrimaryButton(
                label: 'Done',
                onPressed: () {},
                fitToContent: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(FilledButton)).width, lessThan(300));
  });

  testWidgets('PrimaryButton supports a trailing icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PrimaryButton(
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

  testWidgets('PrimaryButton rotates its icon by the supplied angle', (
    tester,
  ) async {
    const angle = -math.pi / 6;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PrimaryButton(
            label: 'Send',
            icon: Icons.send,
            iconAngle: angle,
            onPressed: () {},
          ),
        ),
      ),
    );

    final rotation = tester.widget<Transform>(
      find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(Transform),
      ),
    );
    expect(rotation.transform.entry(0, 0), closeTo(math.cos(angle), 0.0001));
    expect(rotation.transform.entry(1, 0), closeTo(math.sin(angle), 0.0001));
  });

  testWidgets('PrimaryButton fitToContent shrinks in narrow space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 90,
            child: PrimaryButton(
              label: 'Generate Video',
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
