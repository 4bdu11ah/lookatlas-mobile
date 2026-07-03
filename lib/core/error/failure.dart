/// Typed, sealed failures surfaced to the domain and presentation layers.
///
/// Data sources translate raw exceptions (Dio errors, platform exceptions,
/// SDK errors) into one of these. The UI never sees a raw exception, only a
/// `Failure` it can pattern-match on for a user-facing message.
library;

sealed class Failure implements Exception {
  const Failure(this.message, {this.cause, this.stackTrace});

  /// Human-readable, user-safe message. Never contains secrets.
  final String message;

  /// The original error, kept for logging and crash reporting only.
  final Object? cause;
  final StackTrace? stackTrace;
}

class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;
}

class AuthFailure extends Failure {
  const AuthFailure(
    super.message, {
    this.userCancelled = false,
    super.cause,
    super.stackTrace,
  });

  /// True when the user dismissed a sign-in flow themselves (e.g. closed the
  /// Apple/Google sheet). Mirrors [SubscriptionFailure.userCancelled]:
  /// callers treat it as a non-error and stay silent.
  final bool userCancelled;
}

class SubscriptionFailure extends Failure {
  const SubscriptionFailure(
    super.message, {
    this.userCancelled = false,
    super.cause,
    super.stackTrace,
  });

  final bool userCancelled;
}

class AiFailure extends Failure {
  const AiFailure(super.message, {super.cause, super.stackTrace});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.cause, super.stackTrace});
}

/// The operation was cancelled intentionally (e.g. via a `CancelToken` when
/// a screen is disposed). Not a real error — callers can pattern-match on
/// this and silently ignore it instead of surfacing an error state.
class CancelledFailure extends Failure {
  const CancelledFailure(super.message, {super.cause, super.stackTrace});
}

class UnknownFailure extends Failure {
  const UnknownFailure(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}
