part of 'package:look_atlas/features/support/presentation/support_feature.dart';

_SupportScreenState _supportInitialState({
  required String fullName,
  required String email,
}) {
  return _SupportScreenState(
    fullName: fullName,
    email: email,
    subject: '',
    priority: _SupportPriority.medium,
    message: '',
    submissionStatus: _SupportSubmissionStatus.idle,
  );
}
