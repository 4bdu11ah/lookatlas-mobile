import 'package:look_atlas/core/error/failure.dart';

/// A lightweight `Either`-style result type built on Dart 3 sealed classes.
///
/// Repositories return `Result<T>` instead of throwing, so callers must handle
/// the failure path explicitly. Use [fold] or pattern matching to consume it.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value if this is [Ok], otherwise null.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure if this is [Err], otherwise null.
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// Transforms the failure, leaving a success untouched — the error-side
  /// counterpart of [map].
  Result<T> mapErr(Failure Function(Failure failure) transform) =>
      switch (this) {
        Ok<T>() => this,
        Err<T>(:final failure) => Err<T>(transform(failure)),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
