import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/account_deletion/presentation/account_deletion_controller.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(accountDeletionControllerProvider, (_, _) {});
  });

  test('requires a reason and exact DELETE confirmation', () {
    container.read(accountDeletionControllerProvider.notifier)
      ..setReason('I no longer need it')
      ..setConfirmation('delete');

    expect(
      container.read(accountDeletionControllerProvider).canSubmit,
      isFalse,
    );

    container
        .read(accountDeletionControllerProvider.notifier)
        .setConfirmation('DELETE');
    expect(container.read(accountDeletionControllerProvider).canSubmit, isTrue);
  });

  test('submits only after server re-authentication succeeds', () async {
    when(
      () => repository.reauthenticateForAccountDeletion(
        provider: 'password',
        material: 'password',
      ),
    ).thenAnswer((_) async => const Result.ok('short-lived-proof'));
    when(
      () => repository.deleteAccount(
        email: 'jane@example.com',
        confirmation: 'DELETE',
        reason: 'I no longer need it',
        reauthenticationProof: 'short-lived-proof',
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));
    final controller = container.read(
      accountDeletionControllerProvider.notifier,
    );

    expect(
      await controller.reauthenticate(
        provider: 'password',
        material: 'password',
      ),
      isTrue,
    );
    controller
      ..setReason('I no longer need it')
      ..setConfirmation('DELETE');

    expect(await controller.delete(email: 'jane@example.com'), isTrue);
    verify(
      () => repository.deleteAccount(
        email: 'jane@example.com',
        confirmation: 'DELETE',
        reason: 'I no longer need it',
        reauthenticationProof: 'short-lived-proof',
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(1);
  });
}
