import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/presentation/controllers/sign_in_ui_controller.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_turnstile.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_in_form_card.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_before_after_header.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_testimonials.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpSignInScreen(
    WidgetTester tester, {
    FakeAuthRepository? repository,
    Size size = const Size(402, 900),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          repository ?? FakeAuthRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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
    final submitButton = find.text('Sign in');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
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
    final submitButton = find.text('Sign in');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(
      find.text('Complete the security check before continuing.'),
      findsOneWidget,
    );
  });

  testWidgets('SignInScreen uses login Turnstile action', (tester) async {
    await pumpSignInScreen(tester);

    final turnstile = tester.widget<AuthTurnstile>(
      find.byType(AuthTurnstile),
    );

    expect(turnstile.action, AuthTurnstileAction.login);
  });

  testWidgets('SignInScreen resets spent Turnstile token', (
    tester,
  ) async {
    final repository = _RejectingAuthRepository();
    await pumpSignInScreen(tester, repository: repository);

    final firstTurnstile = tester.widget<AuthTurnstile>(
      find.byType(AuthTurnstile),
    );
    firstTurnstile.onTokenChanged('fresh-login-token');
    await tester.enterText(
      find.byType(TextFormField).first,
      'jane@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');

    final submitButton = find.text('Sign in');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final refreshedTurnstile = tester.widget<AuthTurnstile>(
      find.byType(AuthTurnstile),
    );
    expect(refreshedTurnstile.key, isNot(firstTurnstile.key));
    expect(repository.signInCalls, 1);
    expect(repository.lastCaptchaToken, 'fresh-login-token');

    await tester.tap(submitButton);
    await tester.pump();

    expect(repository.signInCalls, 1);
  });

  testWidgets('SignInScreen toggles password visibility', (tester) async {
    await pumpSignInScreen(tester);

    final passwordField = find.byType(TextFormField).last;
    await tester.ensureVisible(passwordField);
    await tester.pumpAndSettle();

    final obscuredPasswordInput = tester.widget<EditableText>(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(obscuredPasswordInput.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    final toggleButton = find.byTooltip('Show password');
    await tester.ensureVisible(toggleButton);
    await tester.tap(toggleButton);
    await tester.pump();

    final visiblePasswordInput = tester.widget<EditableText>(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(visiblePasswordInput.obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('SignInScreen renders Variant 8 elements and brand strip', (
    tester,
  ) async {
    await pumpSignInScreen(tester);

    expect(find.byType(SignUpBeforeAfterHeader), findsOneWidget);
    expect(find.text('ORIGINAL'), findsOneWidget);
    expect(find.text('LOOKATLAS'), findsOneWidget);
    expect(find.text('2000+ brands'), findsOneWidget);
    expect(find.text('BURGA'), findsOneWidget);
    expect(find.text('NOOKLA'), findsOneWidget);
    expect(find.text('GOODFAIR'), findsOneWidget);
    expect(find.text('APOLLO'), findsOneWidget);

    final burga = tester.widget<Text>(find.text('BURGA'));
    expect(burga.style?.fontFamily, 'Sekuya');

    final nookla = tester.widget<Text>(find.text('NOOKLA'));
    expect(nookla.style?.fontFamily, 'RethinkSans');

    final goodfair = tester.widget<Text>(find.text('GOODFAIR'));
    expect(goodfair.style?.fontFamily, 'Qahiri');

    final apollo = tester.widget<Text>(find.text('APOLLO'));
    expect(apollo.style?.fontFamily, 'RedRose');

    expect(find.byType(SignUpTestimonials), findsOneWidget);
  });

  testWidgets(
    'SignInScreen renders wide Variant 5 two-column layout on tablet/desktop (>= 800px)',
    (tester) async {
      await pumpSignInScreen(
        tester,
        size: const Size(1024, 768),
      );

      expect(find.byType(SignUpBeforeAfterHeader), findsOneWidget);
      expect(find.byType(SignInFormCard), findsOneWidget);
      expect(find.byType(SignUpTestimonials), findsOneWidget);

      final heroCenter = tester.getCenter(find.byType(SignUpBeforeAfterHeader));
      final formCenter = tester.getCenter(find.byType(SignInFormCard));
      expect(heroCenter.dx, lessThan(formCenter.dx));

      final testimonialsWidget = tester.widget<SignUpTestimonials>(
        find.byType(SignUpTestimonials),
      );
      expect(testimonialsWidget.isColumn, isTrue);

      expect(find.text('Alex Richard'), findsOneWidget);
      expect(find.text('Marcus Vance'), findsOneWidget);

      final alexCenter = tester.getCenter(find.text('Alex Richard'));
      final marcusCenter = tester.getCenter(find.text('Marcus Vance'));
      expect(marcusCenter.dy, greaterThan(alexCenter.dy));

      final testimonialsRect = tester.getRect(find.byType(SignUpTestimonials));
      final formRect = tester.getRect(find.byType(SignInFormCard));
      expect(testimonialsRect.bottom, equals(formRect.bottom));
    },
  );

  testWidgets(
    'SignInScreen renders compact Variant 8 on small mobile (320px width) without overflow',
    (tester) async {
      await pumpSignInScreen(
        tester,
        size: const Size(320, 640),
      );

      expect(find.byType(SignUpBeforeAfterHeader), findsOneWidget);
      expect(find.byType(SignInFormCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Scrolling past hero updates status bar style via riverpod', (
    tester,
  ) async {
    await pumpSignInScreen(tester);

    expect(container.read(signInScrolledUnderProvider), isFalse);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('2000+ brands'),
      200,
      scrollable: scrollable,
    );
    expect(container.read(signInScrolledUnderProvider), isTrue);
  });

  testWidgets(
    'Horizontal scroll in testimonials carousel does not alter status bar state',
    (tester) async {
      await pumpSignInScreen(tester);

      expect(container.read(signInScrolledUnderProvider), isFalse);
      expect(container.read(signInIsScrolledProvider), isFalse);

      final horizontalScrollable = find.descendant(
        of: find.byType(SignUpTestimonials),
        matching: find.byType(Scrollable),
      );
      expect(horizontalScrollable, findsOneWidget);

      final mainScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byType(SignUpTestimonials),
        300,
        scrollable: mainScrollable,
      );
      await tester.pumpAndSettle();

      final stateBeforeHorizontalDrag = container.read(
        signInScrolledUnderProvider,
      );

      await tester.drag(horizontalScrollable, const Offset(-150, 0));
      await tester.pump();

      expect(
        container.read(signInScrolledUnderProvider),
        stateBeforeHorizontalDrag,
      );
    },
  );
}

class _RejectingAuthRepository extends FakeAuthRepository {
  int signInCalls = 0;
  String? lastCaptchaToken;

  @override
  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    signInCalls++;
    lastCaptchaToken = captchaToken;
    return const Result.err(AuthFailure('Invalid credentials.'));
  }
}
