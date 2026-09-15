import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/support/di/support_providers.dart';
import 'package:look_atlas/features/support/domain/entities/support_ticket.dart';
import 'package:look_atlas/features/support/presentation/models/support_screen_state.dart';

class SupportController extends Notifier<SupportScreenState> {
  @override
  SupportScreenState build() {
    ref.watch(supportRepositoryProvider);
    final user = ref.watch(authStateProvider).value;
    final company = user?.companyName?.trim() ?? '';
    return supportInitialState(
      fullName: company.isEmpty ? 'Look Atlas customer' : company,
      email: user?.email.trim() ?? '',
    );
  }

  void setFullName(String value) =>
      state = state.copyWith(fullName: value, clearError: true);
  void setEmail(String value) =>
      state = state.copyWith(email: value, clearError: true);
  void setSubject(String value) =>
      state = state.copyWith(subject: value, clearError: true);
  void setPriority(SupportPriority value) =>
      state = state.copyWith(priority: value, clearError: true);
  void setMessage(String value) =>
      state = state.copyWith(message: value, clearError: true);

  void setCategory(SupportCategory value) {
    final priority = switch (value) {
      SupportCategory.technical ||
      SupportCategory.billing => SupportPriority.high,
      SupportCategory.account => SupportPriority.medium,
      _ => SupportPriority.low,
    };
    state = state.copyWith(
      category: value,
      priority: priority,
      clearError: true,
    );
  }

  Future<bool> submit() async {
    if (state.isSubmitting) return false;
    if (state.retryAt != null &&
        ref.read(supportClockProvider)().isBefore(state.retryAt!)) {
      return false;
    }
    final error = _validationError();
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return false;
    }
    final userId = ref.read(authStateProvider).value!.id;
    final request = SupportTicketRequest(
      title: '[${state.category.ticketLabel}] ${state.subject.trim()}',
      name: state.fullName.trim().isEmpty
          ? 'Look Atlas customer'
          : state.fullName.trim(),
      priority: state.priority.apiValue,
      message: state.message.trim(),
    );
    state = state.copyWith(
      submissionStatus: SupportSubmissionStatus.submitting,
      clearError: true,
    );
    final result = await ref
        .read(supportRepositoryProvider)
        .submitTicket(request);
    if (!ref.mounted || ref.read(authStateProvider).value?.id != userId) {
      return false;
    }
    return result.fold(
      (receipt) {
        state = state.copyWith(
          submissionStatus: SupportSubmissionStatus.success,
          receipt: receipt,
        );
        return true;
      },
      (failure) {
        DateTime? retryAt;
        if (failure case NetworkFailure(
          code: 'RATE_LIMIT_EXCEEDED',
          :final details,
        )) {
          final seconds = switch (details['retryAfterSeconds']) {
            final num value => value.toInt(),
            _ => 60,
          };
          retryAt = ref
              .read(supportClockProvider)()
              .add(Duration(seconds: seconds.clamp(1, 3600)));
        }
        state = state.copyWith(
          submissionStatus: SupportSubmissionStatus.idle,
          errorMessage: failure.message,
          retryAt: retryAt,
        );
        return false;
      },
    );
  }

  void acknowledgeSuccess() => state = state.copyWith(
    subject: '',
    message: '',
    submissionStatus: SupportSubmissionStatus.idle,
    clearError: true,
    clearReceipt: true,
  );

  String? _validationError() {
    if (ref.read(authStateProvider).value == null) {
      return 'Sign in to send a support request.';
    }
    if (state.subject.trim().isEmpty || state.message.trim().isEmpty) {
      return 'Please complete all required fields.';
    }
    if (state.message.trim().length < 20) {
      return 'Tell us a little more. Use at least 20 characters.';
    }
    return null;
  }
}

final NotifierProvider<SupportController, SupportScreenState>
supportControllerProvider =
    NotifierProvider.autoDispose<SupportController, SupportScreenState>(
      SupportController.new,
    );
final StreamProvider<Duration> supportRetryRemainingProvider =
    StreamProvider.autoDispose<Duration>((
      ref,
    ) {
      final retryAt = ref.watch(
        supportControllerProvider.select((state) => state.retryAt),
      );
      final now = ref.watch(supportClockProvider);
      Duration remaining() {
        if (retryAt == null) return Duration.zero;
        final left = retryAt.difference(now());
        return left.isNegative ? Duration.zero : left;
      }

      return Stream<Duration>.multi((controller) {
        controller.add(remaining());
        final timer = Timer.periodic(
          const Duration(seconds: 1),
          (_) => controller.add(remaining()),
        );
        controller.onCancel = timer.cancel;
      });
    });
