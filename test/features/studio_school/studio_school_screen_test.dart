import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/models/studio_school_catalog.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/credit_calculator.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/lesson_player_dialog.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';

import '../../helpers/fake_welcome_repository.dart';
import '../../helpers/learning_center_test_app.dart';
import '../../helpers/learning_center_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLearningCenterTestFonts);

  testWidgets('hub_reference_rendersEditorialHeroAndCustomAppBar', (
    tester,
  ) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
    );
    expect(find.text('Make better work, faster.'), findsOneWidget);
    expect(find.byType(CustomAppBar), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Open navigation'), findsNothing);
    expect(find.text('Start with the essentials.'), findsOneWidget);
    expect(find.text('Start first lesson'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Make better work, faster.'));
    expect(title.style?.fontFamily, 'InstrumentSerif');
    expect(title.style?.fontSize, 44);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      LearningCenterStyle.paper,
    );
  });

  testWidgets('hub_search_matchesWordsAcrossLessonCards', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
    );
    await tester.enterText(
      find.byKey(const ValueKey('learning-center-search')),
      'credit math',
    );
    await tester.pumpAndSettle();
    expect(find.text('How credits work'), findsOneWidget);
    expect(
      find.textContaining('1 result for', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Start first lesson'), findsNothing);
    expect(find.text("Fix it, don't reshoot"), findsNothing);
  });

  testWidgets('hub_searchNoMatch_clearRestoresContinueCard', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
    );
    await tester.enterText(
      find.byKey(const ValueKey('learning-center-search')),
      'zzzz',
    );
    await tester.pumpAndSettle();
    expect(find.text('Try a simpler search.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Start first lesson'), findsOneWidget);
  });

  testWidgets('hub_readOnly_lessonsRemainReadable', (tester) async {
    await pumpLearningCenter(tester, repository: FakeWelcomeRepository());
    expect(find.text('Learn without tracked progress'), findsOneWidget);
    await tester.tap(find.text('Start first lesson'));
    await tester.pumpAndSettle();
    expect(find.byType(StudioLessonPlayer), findsOneWidget);
    expect(find.text('Credits are your shoot fuel'), findsOneWidget);
    await tester.tap(find.byTooltip('Close lesson'));
    await tester.pumpAndSettle();
  });

  testWidgets('player_calculatorAndCompletion_chainsToNextLesson', (
    tester,
  ) async {
    final repository = FakeWelcomeRepository(state: fakeEligibleWelcomeState());
    await pumpLearningCenter(tester, repository: repository);
    await tester.tap(find.text('Start first lesson'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.byType(CreditCalculator), findsOneWidget);
    expect(find.text('15 images'), findsOneWidget);
    expect(find.textContaining('4K: 45'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('studio-school-done')));
    await tester.pumpAndSettle();
    expect(repository.completeCalls, 1);
    expect(find.text('Lesson complete.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Lesson complete.'), findsOneWidget);
    await tester.tap(find.text('Next lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Almost right is fixable'), findsOneWidget);
    await tester.tap(find.byTooltip('Close lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Continue lesson'), findsOneWidget);
  });

  testWidgets('player_allLessons_usesAppCustomDialogWithExactContent', (
    tester,
  ) async {
    await pumpLearningCenter(tester, repository: FakeWelcomeRepository());
    for (final lesson in studioSchoolLessons) {
      final row = find.byKey(ValueKey('studio-school-${lesson.id.apiValue}'));
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
      final dialog = tester.widget<AppDialog>(find.byType(AppDialog));
      expect(dialog.config, AppDialogConfig.standard);
      expect(
        tester.getSize(find.byType(StudioLessonPlayer)).width,
        lessThanOrEqualTo(358),
      );
      expect(find.text(lesson.cards.first.title), findsOneWidget);
      expect(
        find.text('Idea 1 of ${lesson.cards.length}'.toUpperCase()),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close lesson'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('reward_allComplete_claimsAndShowsClaimedState', (tester) async {
    final repository = FakeWelcomeRepository(
      state: fakeEligibleWelcomeState(
        completed: WelcomeLessonId.values.toSet(),
      ),
    );
    await pumpLearningCenter(tester, repository: repository);
    await tester.tap(find.byKey(const ValueKey('studio-school-claim')));
    await tester.pumpAndSettle();
    expect(repository.claimCalls, 1);
    expect(find.text('20 free credits added.'), findsOneWidget);
    expect(find.text('Review lessons'), findsOneWidget);
  });

  testWidgets('player_offline_disablesTrackedCompletion', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
      online: false,
    );
    await tester.tap(find.text('Start first lesson'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    final done = tester.widget<LearningAction>(
      find.byKey(const ValueKey('studio-school-done')),
    );
    expect(done.onPressed, isNull);
    expect(find.text('Reconnect to save lesson progress.'), findsOneWidget);
  });

  testWidgets('hub_appBarBack_returnsToDashboard', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Destination /'), findsOneWidget);
  });

  testWidgets('hub_guideRow_opensRequestedTab', (tester) async {
    await pumpLearningCenter(
      tester,
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
    );
    final row = find.byKey(const ValueKey('learning-guide-models'));
    await tester.scrollUntilVisible(
      row.hitTestable(),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(
      find.text('Choose the Look Atlas cast or build your own roster.'),
      findsOneWidget,
    );
  });

  testWidgets('hub_320px_fitsWithKeyboardAndLesson', (tester) async {
    await pumpLearningCenter(
      tester,
      size: const Size(320, 720),
      repository: FakeWelcomeRepository(state: fakeEligibleWelcomeState()),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Start first lesson'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close lesson'));
    await tester.pumpAndSettle();
  });
}
