import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  Future<void> pumpGuides(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardFeatureScreen.guides(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('guides page renders the reference default tab', (tester) async {
    await pumpGuides(tester);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Guides'), findsNWidgets(2));
    expect(
      find.text(
        'Everything you need to master Look Atlas and create stunning on-model product photography.',
      ),
      findsOneWidget,
    );
    expect(find.text('Welcome to Look Atlas'), findsOneWidget);
    expect(find.text('What You Can Do'), findsOneWidget);
    expect(find.text('Generate On-Model Photos'), findsOneWidget);
    expect(find.text('Create Product Videos'), findsOneWidget);
    expect(find.text('AI-Powered Edits'), findsOneWidget);
  });

  testWidgets('guide tabs switch to each reference section', (tester) async {
    await pumpGuides(tester);

    await tester.tap(
      find.byKey(const ValueKey('guide-tab-productPhotos')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Taking Great Product Photos'), findsOneWidget);
    expect(find.text('Why Multiple Angles Matter'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-tab-models')));
    await tester.pumpAndSettle();
    expect(find.text('Choosing Your Models'), findsOneWidget);
    expect(find.text('Upload Your Own Models'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-tab-shoots')));
    await tester.pumpAndSettle();
    expect(find.text('Mastering Shoots'), findsOneWidget);
    expect(find.text('Complete Job Workflow'), findsOneWidget);
  });

  testWidgets('guide tab controls expose accessible labels', (tester) async {
    await pumpGuides(tester);

    expect(find.bySemanticsLabel('Getting Started'), findsOneWidget);
    expect(find.bySemanticsLabel('Product Photos'), findsOneWidget);
    expect(find.bySemanticsLabel('Models'), findsOneWidget);
    expect(find.bySemanticsLabel('Shoots'), findsOneWidget);
  });

  testWidgets('guides fit the 320px audit width across tabs', (tester) async {
    await pumpGuides(tester, size: const Size(320, 720));

    for (final tab in ['productPhotos', 'models', 'shoots', 'gettingStarted']) {
      await tester.tap(find.byKey(ValueKey('guide-tab-$tab')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
