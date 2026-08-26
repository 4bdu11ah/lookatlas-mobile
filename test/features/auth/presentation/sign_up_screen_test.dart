import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_turnstile.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpSignUpScreen(
    WidgetTester tester, {
    FakeAuthRepository? repository,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            repository ?? FakeAuthRepository(),
          ),
        ],
        child: const MaterialApp(home: SignUpScreen()),
      ),
    );
  }

  testWidgets('SignUpScreen toggles password visibility', (tester) async {
    await pumpSignUpScreen(tester);

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

  testWidgets('SignUpScreen requires Turnstile before submission', (
    tester,
  ) async {
    await pumpSignUpScreen(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Acme Inc.');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'jane@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    final submitButton = find.text('Create account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(
      find.text('Complete the security check before continuing.'),
      findsOneWidget,
    );
  });

  testWidgets('SignUpScreen uses signup Turnstile action', (tester) async {
    await pumpSignUpScreen(tester);

    final turnstile = tester.widget<AuthTurnstile>(
      find.byType(AuthTurnstile),
    );

    expect(turnstile.action, AuthTurnstileAction.signup);
  });

  testWidgets('SignUpScreen resets spent Turnstile token', (
    tester,
  ) async {
    final repository = _RejectingAuthRepository();
    await pumpSignUpScreen(tester, repository: repository);

    final firstTurnstile = tester.widget<AuthTurnstile>(
      find.byType(AuthTurnstile),
    );
    firstTurnstile.onTokenChanged('fresh-signup-token');
    await tester.enterText(find.byType(TextFormField).at(0), 'Acme Inc.');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'jane@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    final submitButton = find.text('Create account');
    await tester.ensureVisible(submitButton);

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final refreshedTurnstile = tester.widget<AuthTurnstile>(
      find.byType(AuthTurnstile),
    );
    expect(refreshedTurnstile.key, isNot(firstTurnstile.key));
    expect(repository.signUpCalls, 1);
    expect(repository.lastCaptchaToken, 'fresh-signup-token');

    await tester.tap(submitButton);
    await tester.pump();

    expect(repository.signUpCalls, 1);
  });
}

class _RejectingAuthRepository extends FakeAuthRepository {
  int signUpCalls = 0;
  String? lastCaptchaToken;

  @override
  Future<Result<AppUser>> signUpWithEmail({
    required String email,
    required String password,
    required String companyName,
    RegisterAttribution? attribution,
    String? captchaToken,
  }) async {
    signUpCalls++;
    lastCaptchaToken = captchaToken;
    return const Result.err(AuthFailure('Registration failed.'));
  }
}
