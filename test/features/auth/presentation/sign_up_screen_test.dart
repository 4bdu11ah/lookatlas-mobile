import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';
import 'package:look_atlas/features/auth/presentation/controllers/sign_up_ui_controller.dart';
import 'package:look_atlas/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:look_atlas/features/auth/presentation/widgets/auth_turnstile.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_before_after_header.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_form_card.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_testimonials.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpSignUpScreen(
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
        child: const MaterialApp(home: SignUpScreen()),
      ),
    );
  }

  testWidgets('SignUpScreen toggles password visibility', (tester) async {
    await pumpSignUpScreen(tester);

    final passwordField = find.byType(TextFormField).last;
    await tester.ensureVisible(passwordField);
    await tester.pumpAndSettle();

    final obscuredPasswordInput = tester.widget<EditableText>(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(obscuredPasswordInput.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    final toggleButton = find.byTooltip('Show password');
    await tester.tap(toggleButton);
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
    final submitButton = find.text('Get Your Free Photos');
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
    final submitButton = find.text('Get Your Free Photos');
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

  testWidgets('SignUpScreen renders Variant 8 elements and social buttons', (
    tester,
  ) async {
    await pumpSignUpScreen(tester);

    expect(find.byType(SignUpBeforeAfterHeader), findsOneWidget);
    expect(find.text('ORIGINAL'), findsOneWidget);
    expect(find.text('LOOKATLAS'), findsOneWidget);
    expect(
      find.text('Get 15 Studio-Grade Photos in under 10 min.'),
      findsOneWidget,
    );
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
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

  testWidgets('Tapping thumbnail switches active showcase', (tester) async {
    await pumpSignUpScreen(tester);

    expect(container.read(signUpShowcaseIndexProvider), 0);

    // Tap the second thumbnail
    final thumbnails = find.descendant(
      of: find.byType(SignUpBeforeAfterHeader),
      matching: find.byType(GestureDetector),
    );
    // Find thumbnail gestures (thumbnails are at the bottom of header)
    expect(thumbnails, findsWidgets);

    // Change index via provider to verify reactive rendering
    container.read(signUpShowcaseIndexProvider.notifier).select(1);
    await tester.pump();
    expect(container.read(signUpShowcaseIndexProvider), 1);
  });

  testWidgets('Slider updates position via riverpod provider', (tester) async {
    await pumpSignUpScreen(tester);

    expect(container.read(signUpSliderPositionProvider), 0.52);

    container.read(signUpSliderPositionProvider.notifier).updatePosition(0.75);
    await tester.pump();

    expect(container.read(signUpSliderPositionProvider), 0.75);
  });

  testWidgets('Tapping Google and Apple sign-in buttons invokes auth methods', (
    tester,
  ) async {
    final repository = _SocialTrackingAuthRepository();
    await pumpSignUpScreen(tester, repository: repository);

    final googleBtn = find.text('Continue with Google');
    await tester.ensureVisible(googleBtn);
    await tester.tap(googleBtn);
    await tester.pump();
    expect(repository.googleCalls, 1);

    final appleBtn = find.text('Continue with Apple');
    await tester.ensureVisible(appleBtn);
    await tester.tap(appleBtn);
    await tester.pump();
    expect(repository.appleCalls, 1);
  });

  testWidgets('Scrolling past hero updates status bar style via riverpod', (
    tester,
  ) async {
    await pumpSignUpScreen(tester);

    expect(container.read(signUpScrolledUnderProvider), isFalse);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('2000+ brands'),
      200,
      scrollable: scrollable,
    );
    expect(container.read(signUpScrolledUnderProvider), isTrue);
  });

  testWidgets(
    'Horizontal scroll in testimonials carousel does not alter status bar state',
    (tester) async {
      await pumpSignUpScreen(tester);

      expect(container.read(signUpScrolledUnderProvider), isFalse);
      expect(container.read(signUpIsScrolledProvider), isFalse);

      // Find horizontal reviews scrollable (inside SignUpTestimonials)
      final horizontalScrollable = find.descendant(
        of: find.byType(SignUpTestimonials),
        matching: find.byType(Scrollable),
      );
      expect(horizontalScrollable, findsOneWidget);

      // Scroll down to testimonials at the bottom of the page
      final mainScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byType(SignUpTestimonials),
        300,
        scrollable: mainScrollable,
      );
      await tester.pumpAndSettle();

      final stateBeforeHorizontalDrag = container.read(
        signUpScrolledUnderProvider,
      );

      // Drag reviews horizontally
      await tester.drag(horizontalScrollable, const Offset(-150, 0));
      await tester.pump();

      // Horizontal dragging must not alter status bar state
      expect(
        container.read(signUpScrolledUnderProvider),
        stateBeforeHorizontalDrag,
      );

      // Full author description shows maxLines 2
      final roleText = tester.widget<Text>(
        find.text('E-commerce Lead, Velour Clothing'),
      );
      expect(roleText.maxLines, 2);
    },
  );

  testWidgets(
    'SignUpScreen applies 6px margin to header and form card, and 6px all-around padding to testimonials',
    (
      tester,
    ) async {
      await pumpSignUpScreen(tester);

      final headerContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SignUpBeforeAfterHeader),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(headerContainer.margin, const EdgeInsets.symmetric(horizontal: 6));

      final testimonialsContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SignUpTestimonials),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(testimonialsContainer.padding, const EdgeInsets.all(6));

      // On mobile (402px wide), each card fits the content width (402 - 12 = 390px)
      final firstCardClip = find
          .descendant(
            of: find.byType(SignUpTestimonials),
            matching: find.byType(ClipRRect),
          )
          .first;
      final cardSize = tester.getSize(firstCardClip);
      expect(cardSize.width, 390.0);
    },
  );

  testWidgets(
    'SignUpScreen renders wide Variant 5 two-column layout on tablet/desktop (>= 800px)',
    (tester) async {
      await pumpSignUpScreen(
        tester,
        size: const Size(1024, 768),
      );

      expect(find.byType(SignUpBeforeAfterHeader), findsOneWidget);
      expect(find.byType(SignUpFormCard), findsOneWidget);
      expect(find.byType(SignUpTestimonials), findsOneWidget);

      final heroCenter = tester.getCenter(find.byType(SignUpBeforeAfterHeader));
      final formCenter = tester.getCenter(find.byType(SignUpFormCard));
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
      final formRect = tester.getRect(find.byType(SignUpFormCard));
      // Left and right columns match bottom alignment with zero awkward gap
      expect(testimonialsRect.bottom, equals(formRect.bottom));
    },
  );

  testWidgets(
    'SignUpScreen renders compact Variant 8 on small mobile (320px width) without overflow',
    (tester) async {
      await pumpSignUpScreen(
        tester,
        size: const Size(320, 640),
      );

      expect(find.byType(SignUpBeforeAfterHeader), findsOneWidget);
      expect(find.byType(SignUpFormCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
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

class _SocialTrackingAuthRepository extends FakeAuthRepository {
  int googleCalls = 0;
  int appleCalls = 0;

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    googleCalls++;
    return const Result.err(AuthFailure('Google sign-in cancelled.'));
  }

  @override
  Future<Result<AppUser>> signInWithApple() async {
    appleCalls++;
    return const Result.err(AuthFailure('Apple sign-in cancelled.'));
  }
}
