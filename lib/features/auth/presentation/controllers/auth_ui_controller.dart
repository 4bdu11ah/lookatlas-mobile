import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toggles a boolean flag (e.g. password visibility).
class PasswordVisibilityController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

/// Manages Turnstile token state (`null` when pending or cleared).
class TurnstileTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setToken(String? token) {
    if (state != token) {
      state = token;
    }
  }

  void clear() {
    if (state != null) {
      state = null;
    }
  }
}

/// Tracks Turnstile challenge generation counter to force challenge re-rendering.
class CaptchaGenerationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
  }
}

/// Tracks scroll state (e.g. isScrolled > 0, isScrolledUnder).
class AuthScrollNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setScrolled({required bool isScrolled}) {
    if (state != isScrolled) {
      state = isScrolled;
    }
  }
}

/// Tracks showcase item index for Before/After comparison.
class ShowcaseIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (state != index) {
      state = index;
    }
  }
}

/// Tracks split slider position (0.0 to 1.0, default 0.52).
class SliderPositionNotifier extends Notifier<double> {
  @override
  double build() => 0.52;

  void updatePosition(double fraction) {
    state = fraction.clamp(0.0, 1.0);
  }
}

// --- Backward-Compatible Type Aliases ----------------------------------------

typedef SignInTurnstileTokenNotifier = TurnstileTokenNotifier;
typedef SignUpTurnstileTokenNotifier = TurnstileTokenNotifier;
typedef SignInCaptchaGenerationNotifier = CaptchaGenerationNotifier;
typedef SignUpCaptchaGenerationNotifier = CaptchaGenerationNotifier;
typedef SignInIsScrolledNotifier = AuthScrollNotifier;
typedef SignUpIsScrolledNotifier = AuthScrollNotifier;
typedef SignInScrolledUnderNotifier = AuthScrollNotifier;
typedef SignUpScrolledUnderNotifier = AuthScrollNotifier;
typedef SignInShowcaseIndexNotifier = ShowcaseIndexNotifier;
typedef SignUpShowcaseIndexNotifier = ShowcaseIndexNotifier;
typedef SignInSliderPositionNotifier = SliderPositionNotifier;
typedef SignUpSliderPositionNotifier = SliderPositionNotifier;

// --- Sign In Providers -----------------------------------------------------

final NotifierProvider<PasswordVisibilityController, bool>
signInPasswordVisibilityProvider =
    NotifierProvider.autoDispose<PasswordVisibilityController, bool>(
      PasswordVisibilityController.new,
    );

final NotifierProvider<TurnstileTokenNotifier, String?>
signInTurnstileTokenProvider =
    NotifierProvider<TurnstileTokenNotifier, String?>(
      TurnstileTokenNotifier.new,
    );

final NotifierProvider<CaptchaGenerationNotifier, int>
signInCaptchaGenerationProvider =
    NotifierProvider<CaptchaGenerationNotifier, int>(
      CaptchaGenerationNotifier.new,
    );

final NotifierProvider<AuthScrollNotifier, bool> signInIsScrolledProvider =
    NotifierProvider<AuthScrollNotifier, bool>(
      AuthScrollNotifier.new,
    );

final NotifierProvider<AuthScrollNotifier, bool> signInScrolledUnderProvider =
    NotifierProvider<AuthScrollNotifier, bool>(
      AuthScrollNotifier.new,
    );

final NotifierProvider<ShowcaseIndexNotifier, int> signInShowcaseIndexProvider =
    NotifierProvider<ShowcaseIndexNotifier, int>(
      ShowcaseIndexNotifier.new,
    );

final NotifierProvider<SliderPositionNotifier, double>
signInSliderPositionProvider = NotifierProvider<SliderPositionNotifier, double>(
  SliderPositionNotifier.new,
);

// --- Sign Up Providers -----------------------------------------------------

final NotifierProvider<PasswordVisibilityController, bool>
signUpPasswordVisibilityProvider =
    NotifierProvider.autoDispose<PasswordVisibilityController, bool>(
      PasswordVisibilityController.new,
    );

final NotifierProvider<TurnstileTokenNotifier, String?>
signUpTurnstileTokenProvider =
    NotifierProvider<TurnstileTokenNotifier, String?>(
      TurnstileTokenNotifier.new,
    );

final NotifierProvider<CaptchaGenerationNotifier, int>
signUpCaptchaGenerationProvider =
    NotifierProvider<CaptchaGenerationNotifier, int>(
      CaptchaGenerationNotifier.new,
    );

final NotifierProvider<AuthScrollNotifier, bool> signUpIsScrolledProvider =
    NotifierProvider<AuthScrollNotifier, bool>(
      AuthScrollNotifier.new,
    );

final NotifierProvider<AuthScrollNotifier, bool> signUpScrolledUnderProvider =
    NotifierProvider<AuthScrollNotifier, bool>(
      AuthScrollNotifier.new,
    );

final NotifierProvider<ShowcaseIndexNotifier, int> signUpShowcaseIndexProvider =
    NotifierProvider<ShowcaseIndexNotifier, int>(
      ShowcaseIndexNotifier.new,
    );

final NotifierProvider<SliderPositionNotifier, double>
signUpSliderPositionProvider = NotifierProvider<SliderPositionNotifier, double>(
  SliderPositionNotifier.new,
);
