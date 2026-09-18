import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_before_after_header.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_testimonials.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  Future<void> pumpResetPasswordScreen(
    WidgetTester tester, {
    FakeAuthRepository? repository,
    Size size = const Size(402, 900),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            repository ?? _TrackingResetAuthRepository(),
          ),
        ],
        child: const MaterialApp(home: ResetPasswordScreen()),
      ),
    );
  }

  testWidgets(
    'ResetPasswordScreen renders clean form without hero header or testimonials footer',
    (tester) async {
      await pumpResetPasswordScreen(tester);

      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('Reset password'), findsNothing);
      expect(find.text('Reset your password'), findsOneWidget);
      expect(
        find.text("Enter your email and we'll send you a reset link"),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);

      // Verify no hero header and no testimonials footer
      expect(find.byType(SignUpBeforeAfterHeader), findsNothing);
      expect(find.byType(SignUpTestimonials), findsNothing);
    },
  );

  testWidgets('ResetPasswordScreen validates email before submit', (
    tester,
  ) async {
    await pumpResetPasswordScreen(tester);

    await tester.enterText(find.byType(TextFormField), 'invalid-email');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });

  testWidgets('ResetPasswordScreen submits valid email', (tester) async {
    final repository = _TrackingResetAuthRepository();
    await pumpResetPasswordScreen(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(repository.resetCalls, 1);
    expect(repository.lastEmail, 'user@example.com');
  });

  testWidgets('ResetPasswordScreen renders on small mobile without overflow', (
    tester,
  ) async {
    await pumpResetPasswordScreen(
      tester,
      size: const Size(320, 640),
    );

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TrackingResetAuthRepository extends FakeAuthRepository {
  int resetCalls = 0;
  String? lastEmail;

  @override
  Future<Result<void>> resetPassword({required String email}) async {
    resetCalls++;
    lastEmail = email;
    return const Result.ok(null);
  }
}
