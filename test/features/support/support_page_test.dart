import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpSupport(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              user: const AppUser(
                id: 'user-1',
                email: 'dev@lookatlas.com',
                companyName: 'Dev Preview Co',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SupportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('support page renders the reference content and navigation', (
    tester,
  ) async {
    await pumpSupport(tester);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Support'), findsNWidgets(2));
    expect(
      find.text("Get help with Look Atlas. We're here to assist you."),
      findsOneWidget,
    );
    expect(find.text('Contact Info'), findsOneWidget);
    expect(find.text('support@lookatlas.com'), findsOneWidget);
    expect(find.text('Mon-Fri, 9AM-6PM EST'), findsOneWidget);
    expect(
      find.text('We typically respond within 24 hours'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Send us a Message'));
    await tester.pumpAndSettle();
    final nameField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('support-name-field')),
        matching: find.byType(TextField),
      ),
    );
    final emailField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('support-email-field')),
        matching: find.byType(TextField),
      ),
    );
    expect(nameField.controller?.text, 'Dev Preview Co');
    expect(emailField.controller?.text, 'dev@lookatlas.com');
    expect(find.text('Medium - Feature request'), findsOneWidget);
  });

  testWidgets('support form updates priority and message count', (
    tester,
  ) async {
    await pumpSupport(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('support-message-field')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('support-message-field')),
      'The generated image is missing a product.',
    );
    await tester.pump();
    expect(find.text('41 characters'), findsOneWidget);

    await tester.tap(find.text('Medium - Feature request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High - Bug report').last);
    await tester.pumpAndSettle();
    expect(find.text('High - Bug report'), findsOneWidget);
  });

  testWidgets('support form validates required fields', (tester) async {
    await pumpSupport(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('support-submit-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('support-submit-button')));
    await tester.pump();

    expect(
      find.text('Please complete all required fields.'),
      findsOneWidget,
    );
    expect(find.text('Message Received!'), findsNothing);
  });

  testWidgets('support submission shows success and resets ticket fields', (
    tester,
  ) async {
    await pumpSupport(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('support-subject-field')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('support-subject-field')),
      'Image generation issue',
    );
    await tester.enterText(
      find.byKey(const ValueKey('support-message-field')),
      'The generated image is missing the selected product.',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('support-submit-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('support-submit-button')));
    await tester.pump();

    expect(find.text('Sending...'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Message Received!'), findsOneWidget);
    expect(
      find.text(
        "Thank you for contacting us. We'll get back to you within 24 hours.",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('0 characters'), findsOneWidget);
    expect(find.text('Image generation issue'), findsNothing);
  });

  testWidgets('support page fits the 320px audit width', (tester) async {
    await pumpSupport(tester, size: const Size(320, 720));

    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('support-submit-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
