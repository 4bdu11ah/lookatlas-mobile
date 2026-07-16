part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _SupportController extends Notifier<_SupportScreenState> {
  @override
  _SupportScreenState build() {
    final user = ref.watch(authStateProvider).value;
    final displayName = user?.displayName?.trim();
    final companyName = user?.companyName?.trim();
    return _supportInitialState(
      fullName: displayName != null && displayName.isNotEmpty
          ? displayName
          : companyName ?? '',
      email: user?.email.trim() ?? '',
    );
  }

  void setFullName(String value) {
    state = state.copyWith(fullName: value, clearError: true);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  void setSubject(String value) {
    state = state.copyWith(subject: value, clearError: true);
  }

  void setPriority(_SupportPriority value) {
    state = state.copyWith(priority: value, clearError: true);
  }

  void setMessage(String value) {
    state = state.copyWith(message: value, clearError: true);
  }

  Future<bool> submit() async {
    if (state.isSubmitting) return false;
    final error = _validationError();
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return false;
    }

    state = state.copyWith(
      submissionStatus: _SupportSubmissionStatus.submitting,
      clearError: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(
      submissionStatus: _SupportSubmissionStatus.success,
    );
    return true;
  }

  void acknowledgeSuccess() {
    state = state.copyWith(
      subject: '',
      message: '',
      submissionStatus: _SupportSubmissionStatus.idle,
      clearError: true,
    );
  }

  String? _validationError() {
    if (state.fullName.trim().isEmpty ||
        state.email.trim().isEmpty ||
        state.subject.trim().isEmpty ||
        state.message.trim().isEmpty) {
      return 'Please complete all required fields.';
    }
    final email = state.email.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }
}

final NotifierProvider<_SupportController, _SupportScreenState>
_supportControllerProvider =
    NotifierProvider.autoDispose<_SupportController, _SupportScreenState>(
      _SupportController.new,
    );
