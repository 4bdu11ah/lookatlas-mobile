import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/support/domain/entities/support_ticket.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/fake_support_repository.dart';
import '../../helpers/fake_welcome_repository.dart';
import '../../helpers/learning_center_test_app.dart';
import '../../helpers/learning_center_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLearningCenterTestFonts);
  testWidgets('support_reference_rendersHtmlFormAndCategories', (tester) async {
    await pumpLearningCenter(tester, repository: FakeWelcomeRepository(), initialLocation: '/support');
    expect(find.byIcon(LucideIcons.menu), findsOneWidget);
    expect(find.text("Tell us what you're trying to do."), findsOneWidget);
    expect(find.text('Something not working'), findsOneWidget);
    expect(find.text('Billing & credits'), findsOneWidget);
    expect(find.text('How to use'), findsOneWidget);
    expect(find.byKey(const ValueKey('support-subject-field')), findsOneWidget);
  });
  testWidgets('support_emptyDraft_showsValidation', (tester) async {
    final repository = FakeSupportRepository();
    await pumpLearningCenter(tester, repository: FakeWelcomeRepository(), supportRepository: repository, initialLocation: '/support');
    await tester.ensureVisible(find.byKey(const ValueKey('support-submit-button')));
    await tester.tap(find.byKey(const ValueKey('support-submit-button')));
    await tester.pumpAndSettle();
    expect(find.text('Please complete all required fields.'), findsOneWidget);
    expect(repository.requests, isEmpty);
  });
  testWidgets('support_submission_showsReturnedTicketAndBackLink', (tester) async {
    final repository = FakeSupportRepository();
    final pending = Completer<Result<SupportTicketReceipt>>();
    repository.pending = pending.future;
    await pumpLearningCenter(tester, repository: FakeWelcomeRepository(), supportRepository: repository, initialLocation: '/support');
    await tester.tap(find.text('How to use'));
    await tester.enterText(find.byKey(const ValueKey('support-subject-field')), 'Credit rollover');
    await tester.enterText(find.byKey(const ValueKey('support-message-field')), 'Can I pause my subscription and keep my credits?');
    await tester.ensureVisible(find.byKey(const ValueKey('support-submit-button')));
    await tester.tap(find.byKey(const ValueKey('support-submit-button')));
    await tester.pump();
    expect(find.text('SENDING...'), findsOneWidget);
    pending.complete(repository.result);
    await tester.pumpAndSettle();
    expect(repository.requests.single.title, '[How to use Look Atlas] Credit rollover');
    expect(find.text('Request sent.'), findsOneWidget);
    expect(find.textContaining('#LA-1042'), findsOneWidget);
    await tester.tap(find.text('Back to Learning Center'));
    await tester.pumpAndSettle();
    expect(find.text('Make better work, faster.'), findsOneWidget);
  });
  testWidgets('support_320px_fitsForm', (tester) async {
    await pumpLearningCenter(tester, repository: FakeWelcomeRepository(), initialLocation: '/support', size: const Size(320, 720));
    await tester.ensureVisible(find.byKey(const ValueKey('support-submit-button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
