import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_welcome_repository.dart';
import '../../helpers/learning_center_test_app.dart';
import '../../helpers/learning_center_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLearningCenterTestFonts);
  setUp(() => debugDisableShadows = false);
  tearDown(() => debugDisableShadows = true);

  testWidgets('hub_390px_matchesEditorialReference', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
    );
    await _expectGolden(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/learning_center_hub.png'),
    );
  });
  testWidgets('reader_390px_matchesFirstCreditCard', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
    );
    await tester.tap(find.text('Start first lesson'));
    await tester.pumpAndSettle();
    await _expectGolden(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/learning_center_reader.png'),
    );
    await tester.tap(find.byTooltip('Close lesson'));
    await tester.pumpAndSettle();
  });
  testWidgets('guides_390px_matchesWorkflowReference', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
      initialLocation: '/guides',
    );
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.pump();
    await _expectGolden(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/learning_center_guides.png'),
    );
  });
  testWidgets('support_390px_matchesFormReference', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
      initialLocation: '/support',
    );
    await tester.enterText(
      find.byKey(const ValueKey('support-subject-field')),
      'Question about credit usage',
    );
    await tester.enterText(
      find.byKey(const ValueKey('support-message-field')),
      'I would like clarification on whether rolling over credits expires if I pause my subscription.',
    );
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _expectGolden(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/learning_center_support.png'),
    );
  });
}

Future<void> _expectGolden(Finder finder, Matcher matcher) async {
  try {
    await expectLater(finder, matcher);
  } finally {
    debugDisableShadows = true;
  }
}
