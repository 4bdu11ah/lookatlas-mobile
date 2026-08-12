import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';

sealed class StudioSchoolLoadState {
  const StudioSchoolLoadState();
}

final class SchoolLoading extends StudioSchoolLoadState {
  const SchoolLoading();
}

@immutable
final class SchoolReady extends StudioSchoolLoadState {
  const SchoolReady(this.welcome, {this.refreshing = false});

  final WelcomeState welcome;
  final bool refreshing;

  SchoolReady copyWith({WelcomeState? welcome, bool? refreshing}) =>
      SchoolReady(
        welcome ?? this.welcome,
        refreshing: refreshing ?? this.refreshing,
      );
}

final class SchoolReadOnly extends StudioSchoolLoadState {
  const SchoolReadOnly();
}

@immutable
final class SchoolOfflineCached extends StudioSchoolLoadState {
  const SchoolOfflineCached(this.welcome, {this.refreshing = false});

  final WelcomeState welcome;
  final bool refreshing;
}

@immutable
final class SchoolFailure extends StudioSchoolLoadState {
  const SchoolFailure(this.failure);

  final Failure failure;
}

enum LessonActionKind {
  completed,
  alreadyCompleted,
  tooFast,
  notStarted,
  failed,
}

@immutable
class LessonActionResult {
  const LessonActionResult(this.kind, {this.retryAfter, this.message});

  final LessonActionKind kind;
  final Duration? retryAfter;
  final String? message;
}

@immutable
class RewardActionResult {
  const RewardActionResult({
    required this.succeeded,
    required this.message,
  });

  final bool succeeded;
  final String message;
}
