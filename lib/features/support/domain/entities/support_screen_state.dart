part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

enum _SupportPriority {
  low('Low - General inquiry'),
  medium('Medium - Feature request'),
  high('High - Bug report'),
  highBilling('High - Billing/Refund'),
  urgent('Urgent - System down');

  const _SupportPriority(this.label);

  final String label;
}

enum _SupportSubmissionStatus { idle, submitting, success }

class _SupportScreenState {
  const _SupportScreenState({
    required this.fullName,
    required this.email,
    required this.subject,
    required this.priority,
    required this.message,
    required this.submissionStatus,
    this.errorMessage,
  });

  final String fullName;
  final String email;
  final String subject;
  final _SupportPriority priority;
  final String message;
  final _SupportSubmissionStatus submissionStatus;
  final String? errorMessage;

  bool get isSubmitting =>
      submissionStatus == _SupportSubmissionStatus.submitting;

  _SupportScreenState copyWith({
    String? fullName,
    String? email,
    String? subject,
    _SupportPriority? priority,
    String? message,
    _SupportSubmissionStatus? submissionStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return _SupportScreenState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      priority: priority ?? this.priority,
      message: message ?? this.message,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
