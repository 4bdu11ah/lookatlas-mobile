import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/support/presentation/models/support_screen_state.dart';

class SupportController extends Notifier<SupportScreenState> {
  @override
  SupportScreenState build() {
    final user = ref.watch(authStateProvider).value;
    final displayName = user?.displayName?.trim();
    final companyName = user?.companyName?.trim();
    return supportInitialState(
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

  void setPriority(SupportPriority value) {
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
      submissionStatus: SupportSubmissionStatus.submitting,
      clearError: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(
      submissionStatus: SupportSubmissionStatus.success,
    );
    return true;
  }

  void acknowledgeSuccess() {
    state = state.copyWith(
      subject: '',
      message: '',
      submissionStatus: SupportSubmissionStatus.idle,
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

final NotifierProvider<SupportController, SupportScreenState>
supportControllerProvider =
    NotifierProvider.autoDispose<SupportController, SupportScreenState>(
      SupportController.new,
    );
