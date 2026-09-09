import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/account_deletion/domain/use_cases/delete_account_use_case.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('call_normalizesReasonAndCreatesIdempotencyKey', () async {
    final repository = _MockAuthRepository();
    when(
      () => repository.deleteAccount(
        email: any(named: 'email'),
        confirmation: any(named: 'confirmation'),
        reason: any(named: 'reason'),
        reauthenticationProof: any(named: 'reauthenticationProof'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => const Ok(null));
    final useCase = DeleteAccountUseCase(
      repository,
      createIdempotencyKey: () => 'fixed-key',
    );

    await useCase(
      email: 'owner@example.com',
      confirmation: 'DELETE',
      reason: '  No longer needed  ',
      reauthenticationProof: 'proof',
    );

    verify(
      () => repository.deleteAccount(
        email: 'owner@example.com',
        confirmation: 'DELETE',
        reason: 'No longer needed',
        reauthenticationProof: 'proof',
        idempotencyKey: 'fixed-key',
      ),
    ).called(1);
  });

  test('call_missingProof_rejectsWithoutDeletingAccount', () async {
    final repository = _MockAuthRepository();

    final result = await DeleteAccountUseCase(repository)(
      email: 'owner@example.com',
      confirmation: 'DELETE',
      reason: 'No longer needed',
      reauthenticationProof: '',
    );

    expect(result.failureOrNull, isA<AuthFailure>());
    verifyNever(
      () => repository.deleteAccount(
        email: any(named: 'email'),
        confirmation: any(named: 'confirmation'),
        reason: any(named: 'reason'),
        reauthenticationProof: any(named: 'reauthenticationProof'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    );
  });

  test('call_missingConfirmation_rejectsWithoutDeletingAccount', () async {
    final repository = _MockAuthRepository();

    final result = await DeleteAccountUseCase(repository)(
      email: 'owner@example.com',
      confirmation: '',
      reason: 'No longer needed',
      reauthenticationProof: 'proof',
    );

    expect(result.failureOrNull, isA<AuthFailure>());
    verifyNever(
      () => repository.deleteAccount(
        email: any(named: 'email'),
        confirmation: any(named: 'confirmation'),
        reason: any(named: 'reason'),
        reauthenticationProof: any(named: 'reauthenticationProof'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    );
  });
}
