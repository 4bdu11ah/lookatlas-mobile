import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/services/crash/crash_reporter.dart';
import 'package:look_atlas/services/service_providers.dart';

/// The current session: null when signed out. Drives routing redirects.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Handles auth actions and exposes their loading/error state to forms.
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Signs in with email + password. Returns whether it succeeded; failures
  /// are also exposed through the provider's [AsyncError] state.
  /// A Turnstile token is generated immediately before the API request.
  Future<bool> signIn(String email, String password) => _runWithCaptcha(
    (captchaToken) => ref.read(signInUseCaseProvider)(
      email: email,
      password: password,
      captchaToken: captchaToken,
    ),
    onOk: _syncIdentity,
  );

  /// Registers a new account. Returns whether it succeeded. [attribution]
  /// forwards any marketing params (UTM, click IDs, invite) to the register
  /// endpoint, matching the web client.
  Future<bool> signUp({
    required String email,
    required String password,
    required String companyName,
    RegisterAttribution? attribution,
  }) => _runWithCaptcha(
    (captchaToken) => ref.read(signUpUseCaseProvider)(
      email: email,
      password: password,
      companyName: companyName,
      attribution: attribution,
      captchaToken: captchaToken,
    ),
    onOk: _syncIdentity,
  );

  /// Signs in with Apple. Returns whether it succeeded; a dismissed Apple
  /// sheet returns false without surfacing an error (see [_run]).
  Future<bool> signInWithApple() => _run(
    () => ref.read(signInWithAppleUseCaseProvider)(),
    onOk: _syncIdentity,
  );

  /// Signs in with Google. Returns whether it succeeded; a dismissed Google
  /// sheet returns false without surfacing an error (see [_run]).
  Future<bool> signInWithGoogle() => _run(
    () => ref.read(signInWithGoogleUseCaseProvider)(),
    onOk: _syncIdentity,
  );

  /// Starts a password reset for [email]. Returns whether it succeeded.
  Future<bool> resetPassword(String email) =>
      _run(() => ref.read(resetPasswordUseCaseProvider)(email: email));

  Future<bool> _runWithCaptcha<T>(
    Future<Result<T>> Function(String? captchaToken) action, {
    void Function(T value)? onOk,
  }) async {
    state = const AsyncLoading();
    final captcha = await ref.read(turnstileServiceProvider).getToken();
    return captcha.fold(
      (captchaToken) => _run(
        () => action(captchaToken),
        onOk: onOk,
      ),
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  /// Ends the session. Returns whether it succeeded; runs through the same
  /// loading/error state as the other actions so the UI can show progress
  /// and surface failures.
  Future<bool> signOut() => _run(
    () => ref.read(signOutUseCaseProvider)(),
    onOk: (_) => _clearIdentity(),
  );

  /// Runs [action] under a shared loading/error lifecycle: `AsyncLoading`
  /// while in flight, then `AsyncData(null)` or `AsyncError` with the typed
  /// [Result] failure.
  ///
  /// A user-cancelled failure (dismissed Apple/Google sheet) returns to
  /// `AsyncData` instead of `AsyncError`: cancelling is not an error, so no
  /// snackbar — same as the paywall's cancel handling.
  Future<bool> _run<T>(
    Future<Result<T>> Function() action, {
    void Function(T value)? onOk,
  }) async {
    state = const AsyncLoading();
    late final Result<T> result;
    try {
      result = await action();
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
    state = result.fold(
      (value) {
        onOk?.call(value);
        return const AsyncData(null);
      },
      (failure) => switch (failure) {
        AuthFailure(userCancelled: true) => const AsyncData(null),
        _ => AsyncError(failure, StackTrace.current),
      },
    );
    return result.isOk;
  }

  /// Propagates the signed-in identity to analytics, crash reporting and
  /// RevenueCat. Fire-and-forget: a failing side effect (e.g. RevenueCat
  /// offline) must never fail the auth flow itself.
  void _syncIdentity(AppUser user) {
    final analytics = ref.read(analyticsServiceProvider);
    final subscriptions = ref.read(subscriptionRepositoryProvider);
    _fireAndForget(
      () => analytics.identify(user.id, traits: {'email': user.email}),
    );
    _fireAndForget(() => CrashReporter.setUser(user.id));
    // `logIn` transfers any anonymous purchase to this account (RevenueCat's
    // default transfer behavior) and pushes the merged CustomerInfo through
    // the repository's `statusChanges()` stream, so the subscription
    // controller refreshes itself — no manual invalidate here, which also
    // avoids a provider dependency cycle between auth and subscriptions.
    _fireAndForget(() => subscriptions.logIn(user.id));
  }

  /// Detaches the signed-out identity everywhere [_syncIdentity] attached it.
  void _clearIdentity() {
    final analytics = ref.read(analyticsServiceProvider);
    final subscriptions = ref.read(subscriptionRepositoryProvider);
    _fireAndForget(analytics.reset);
    _fireAndForget(() => CrashReporter.setUser(null));
    _fireAndForget(subscriptions.logOut);
  }

  void _fireAndForget(Future<void> Function() action) {
    unawaited(
      Future<void>(action).catchError((Object error, StackTrace stack) {
        unawaited(CrashReporter.recordError(error, stack));
      }),
    );
  }
}

/// autoDispose so a stale [AsyncError] from a previous attempt does not
/// persist app-wide once every auth screen has stopped listening.
final NotifierProvider<AuthController, AsyncValue<void>>
authControllerProvider =
    NotifierProvider.autoDispose<AuthController, AsyncValue<void>>(
      AuthController.new,
    );
