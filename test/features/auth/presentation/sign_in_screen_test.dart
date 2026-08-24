import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_in_screen.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpSignInScreen(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(home: SignInScreen()),
      ),
    );
  }

  testWidgets('SignInScreen renders the email/password form', (tester) async {
    await pumpSignInScreen(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign in'), findsOneWidget);

    // Sign-up now lives on its own screen, linked from the footer.
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('SignInScreen shows the Google button, and the Apple button '
      'only on Apple platforms', (tester) async {
    await pumpSignInScreen(tester);

    expect(find.text('or continue with'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(Container());
    await pumpSignInScreen(tester);

    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('SignInScreen surfaces validation errors on submit', (
    tester,
  ) async {
    await pumpSignInScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'short');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('SignInScreen requires Turnstile before submission', (
    tester,
  ) async {
    await pumpSignInScreen(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'jane@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'secret123',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(
      find.text('Complete the security check before continuing.'),
      findsOneWidget,
    );
  });

  testWidgets('SignInScreen toggles password visibility', (tester) async {
    await pumpSignInScreen(tester);

    final passwordField = find.byType(TextFormField).last;
    final obscuredPasswordInput = tester.widget<EditableText>(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(obscuredPasswordInput.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    final visiblePasswordInput = tester.widget<EditableText>(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(visiblePasswordInput.obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
