import 'package:look_atlas/features/support/domain/entities/support_ticket.dart';

enum SupportPriority {
  low('Low - General inquiry', 'low'),
  medium('Medium - Feature request', 'medium'),
  high('High - Bug report', 'high'),
  highBilling('High - Billing/Refund', 'high'),
  urgent('Urgent - System down', 'urgent');

  const SupportPriority(this.label, this.apiValue);
  final String label;
  final String apiValue;
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
    this.category = SupportCategory.technical,
    this.errorMessage,
    this.receipt,
    this.retryAt,
  });
  final String fullName;
  final String email;
  final String subject;
  final SupportPriority priority;
  final String message;
  final SupportSubmissionStatus submissionStatus;
  final SupportCategory category;
  final String? errorMessage;
  final SupportTicketReceipt? receipt;
  final DateTime? retryAt;
  bool get isSubmitting =>
      submissionStatus == SupportSubmissionStatus.submitting;

  SupportScreenState copyWith({
    String? fullName,
    String? email,
    String? subject,
    SupportPriority? priority,
    String? message,
    SupportSubmissionStatus? submissionStatus,
    SupportCategory? category,
    String? errorMessage,
    SupportTicketReceipt? receipt,
    DateTime? retryAt,
    bool clearError = false,
    bool clearReceipt = false,
  }) => SupportScreenState(
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    subject: subject ?? this.subject,
    priority: priority ?? this.priority,
    message: message ?? this.message,
    submissionStatus: submissionStatus ?? this.submissionStatus,
    category: category ?? this.category,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    receipt: clearReceipt ? null : receipt ?? this.receipt,
    retryAt: retryAt ?? this.retryAt,
  );
}

SupportScreenState supportInitialState({
  required String fullName,
  required String email,
}) => SupportScreenState(
  fullName: fullName,
  email: email,
  subject: '',
  priority: SupportPriority.high,
  message: '',
  submissionStatus: SupportSubmissionStatus.idle,
);
