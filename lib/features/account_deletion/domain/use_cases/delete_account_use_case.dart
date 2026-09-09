import 'dart:math';

import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';

class DeleteAccountUseCase {
  DeleteAccountUseCase(
    this._repository, {
    String Function()? createIdempotencyKey,
  }) : _createIdempotencyKey = createIdempotencyKey ?? _secureKey;

  final AuthRepository _repository;
  final String Function() _createIdempotencyKey;

  Future<Result<void>> call({
    required String email,
    required String confirmation,
    required String reason,
    required String reauthenticationProof,
  }) {
    final normalizedReason = reason.trim();
    if (confirmation != 'DELETE' || normalizedReason.isEmpty) {
      return Future.value(
        const Err(AuthFailure('Confirm deletion and select a reason.')),
      );
    }
    if (reauthenticationProof.isEmpty) {
      return Future.value(
        const Err(AuthFailure('Verify your identity again to continue.')),
      );
    }
    return _repository.deleteAccount(
      email: email,
      confirmation: confirmation,
      reason: normalizedReason,
      reauthenticationProof: reauthenticationProof,
      idempotencyKey: _createIdempotencyKey(),
    );
  }

  static String _secureKey() {
    final random = Random.secure();
    String group(int length) => List.generate(
      length,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return '${group(8)}-${group(4)}-4${group(3)}-'
        '${8 + random.nextInt(4)}${group(3)}-${group(12)}';
  }
}
