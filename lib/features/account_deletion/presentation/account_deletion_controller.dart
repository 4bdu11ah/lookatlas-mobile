import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';

enum AccountDeletionStep {
  explain,
  reauthenticate,
  confirm,
  submitting,
  failed,
}

class AccountDeletionState {
  const AccountDeletionState({
    this.step = AccountDeletionStep.explain,
    this.reason = '',
    this.confirmation = '',
    this.failure,
  });

  final AccountDeletionStep step;
  final String reason;
  final String confirmation;
  final Failure? failure;

  bool get canSubmit => confirmation == 'DELETE' && reason.trim().isNotEmpty;

  AccountDeletionState copyWith({
    AccountDeletionStep? step,
    String? reason,
    String? confirmation,
    Failure? failure,
    bool clearFailure = false,
  }) => AccountDeletionState(
    step: step ?? this.step,
    reason: reason ?? this.reason,
    confirmation: confirmation ?? this.confirmation,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class AccountDeletionController extends Notifier<AccountDeletionState> {
  String? _reauthenticationProof;
  @override
  AccountDeletionState build() => const AccountDeletionState();

  void continueToReauthentication() => state = state.copyWith(
    step: AccountDeletionStep.reauthenticate,
    clearFailure: true,
  );

  void setReason(String value) => state = state.copyWith(reason: value);

  void setConfirmation(String value) => state = state.copyWith(
    confirmation: value,
  );

  void backToExplain() => state = state.copyWith(
    step: AccountDeletionStep.explain,
    clearFailure: true,
  );

  Future<bool> reauthenticate({
    required String provider,
    required String material,
  }) async {
    if (provider == 'password' && material.isEmpty) {
      state = state.copyWith(
        failure: const AuthFailure('Verify your identity before continuing.'),
      );
      return false;
    }
    final result = await ref
        .read(authRepositoryProvider)
        .reauthenticateForAccountDeletion(
          provider: provider,
          material: material,
        );
    final proof = result.valueOrNull;
    if (proof == null) {
      state = state.copyWith(failure: result.failureOrNull);
      return false;
    }
    // This field is intentionally in-memory only, never part of state.
    _reauthenticationProof = proof;
    state = state.copyWith(
      step: AccountDeletionStep.confirm,
      clearFailure: true,
    );
    return true;
  }

  Future<bool> delete({
    required String email,
  }) async {
    if (!state.canSubmit || state.step == AccountDeletionStep.submitting) {
      return false;
    }
    final proof = _reauthenticationProof;
    if (proof == null) {
      state = state.copyWith(
        step: AccountDeletionStep.reauthenticate,
        failure: const AuthFailure('Verify your identity again to continue.'),
      );
      return false;
    }
    state = state.copyWith(
      step: AccountDeletionStep.submitting,
      clearFailure: true,
    );
    final result = await ref
        .read(authRepositoryProvider)
        .deleteAccount(
          email: email,
          confirmation: state.confirmation,
          reason: state.reason.trim(),
          reauthenticationProof: proof,
          idempotencyKey: _idempotencyKey(),
        );
    if (result.isOk) return true;
    state = state.copyWith(
      step: AccountDeletionStep.failed,
      failure: result.failureOrNull,
    );
    return false;
  }

  String _idempotencyKey() {
    final random = Random.secure();
    String group(int length) => List.generate(
      length,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return '${group(8)}-${group(4)}-4${group(3)}-'
        '${8 + random.nextInt(4)}${group(3)}-${group(12)}';
  }
}

final NotifierProvider<AccountDeletionController, AccountDeletionState>
accountDeletionControllerProvider =
    NotifierProvider.autoDispose<
      AccountDeletionController,
      AccountDeletionState
    >(AccountDeletionController.new);
