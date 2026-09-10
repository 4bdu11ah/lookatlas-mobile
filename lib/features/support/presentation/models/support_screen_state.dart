enum SupportPriority {
  low('Low - General inquiry'),
  medium('Medium - Feature request'),
  high('High - Bug report'),
  highBilling('High - Billing/Refund'),
  urgent('Urgent - System down');

  const SupportPriority(this.label);

  final String label;
}

enum SupportSubmissionStatus { idle, submitting, success }

class SupportScreenState {
  const SupportScreenState({
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
  final SupportPriority priority;
  final String message;
  final SupportSubmissionStatus submissionStatus;
  final String? errorMessage;

  bool get isSubmitting =>
      submissionStatus == SupportSubmissionStatus.submitting;

  SupportScreenState copyWith({
    String? fullName,
    String? email,
    String? subject,
    SupportPriority? priority,
    String? message,
    SupportSubmissionStatus? submissionStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SupportScreenState(
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

SupportScreenState supportInitialState({
  required String fullName,
  required String email,
}) {
  return SupportScreenState(
    fullName: fullName,
    email: email,
    subject: '',
    priority: SupportPriority.medium,
    message: '',
    submissionStatus: SupportSubmissionStatus.idle,
  );
}
