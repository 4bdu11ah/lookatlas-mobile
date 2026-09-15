import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';

import '../../helpers/fake_welcome_repository.dart';
import '../../helpers/learning_center_test_app.dart';
import '../../helpers/learning_center_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLearningCenterTestFonts);
  testWidgets('guides_defaultTab_rendersHtmlWorkflow', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(),
      initialLocation: '/guides',
    );
    expect(find.text('Guides'), findsNWidgets(2));
    expect(find.byType(CustomAppBar), findsOneWidget);
    expect(find.byTooltip('Open navigation'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(
      find.text('From reference photos to approved keepers.'),
      findsOneWidget,
    );
    expect(find.text('Reusable products'), findsOneWidget);
  });
  testWidgets('guides_tabs_switchAllFourWalkthroughs', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(),
      initialLocation: '/guides',
    );
    for (final (tab, title) in [
      ('productPhotos', 'Give the planner a clean, truthful reference set.'),
      ('models', 'Choose the Look Atlas cast or build your own roster.'),
      ('shoots', 'Plan the contact sheet before generation starts.'),
    ]) {
      final button = find.byKey(ValueKey('guide-tab-$tab'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('guides_deepLink_selectsProductPhotos', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(),
      initialLocation: '/guides?tab=product-photos',
    );
    expect(
      find.text('Give the planner a clean, truthful reference set.'),
      findsOneWidget,
    );
    expect(
      find.text('From reference photos to approved keepers.'),
      findsNothing,
    );
  });
  testWidgets('guides_action_opensProducts', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(),
      initialLocation: '/guides?tab=product-photos',
    );
    final action = find.text('Open Products');
    await tester.scrollUntilVisible(
      action,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Destination /products'), findsOneWidget);
  });
  testWidgets('guides_back_returnsToHub', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(),
      initialLocation: '/guides',
    );
    await tester.tap(find.text('Studio School'));
    await tester.pumpAndSettle();
    expect(find.text('Make better work, faster.'), findsOneWidget);
  });
  testWidgets('guides_appBarBack_returnsToHub', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(),
      initialLocation: '/guides',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Make better work, faster.'), findsOneWidget);
  });
  testWidgets('guides_320px_allTabsFit', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(),
      initialLocation: '/guides',
      size: const Size(320, 720),
    );
    for (final tab in ['productPhotos', 'models', 'shoots', 'gettingStarted']) {
      final button = find.byKey(ValueKey('guide-tab-$tab'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
