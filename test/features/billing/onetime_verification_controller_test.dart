import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/billing/di/billing_api_providers.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';
import 'package:look_atlas/features/billing/domain/use_cases/billing_api_use_cases.dart';
import 'package:look_atlas/features/billing/presentation/controllers/onetime_verification_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockVerifyOnetimeUseCase extends Mock implements VerifyOnetimeUseCase {}

void main() {
  test('verify_paid_session_stops_after_first_poll', () async {
    final useCase = _MockVerifyOnetimeUseCase();
    when(() => useCase('cs_123')).thenAnswer(
      (_) async => const Result.ok(
        OnetimeVerification(
          status: OnetimePaymentStatus.paid,
          jobId: 'job-1',
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [verifyOnetimeUseCaseProvider.overrideWithValue(useCase)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      onetimeVerificationControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    container
        .read(onetimeVerificationControllerProvider.notifier)
        .start('cs_123');
    await Future<void>.delayed(Duration.zero);

    final state = container.read(onetimeVerificationControllerProvider);
    expect(state.status, OnetimePaymentStatus.paid);
    expect(state.isPolling, isFalse);
    expect(state.pollCount, 1);
    verify(() => useCase('cs_123')).called(1);
  });
}
