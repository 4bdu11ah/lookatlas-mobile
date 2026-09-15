import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/support/di/support_providers.dart';
import 'package:look_atlas/features/support/domain/entities/support_ticket.dart';
import 'package:look_atlas/features/support/presentation/controllers/support_controller.dart';
import 'package:look_atlas/features/support/presentation/models/support_screen_state.dart';

import '../../helpers/fake_support_repository.dart';

void main() {
  final now = DateTime.utc(2026, 9, 15);
  ProviderContainer containerFor(
    FakeSupportRepository repository, {
    AppUser? user = const AppUser(
      id: 'user-1',
      email: 'a@example.com',
      companyName: 'Acme Studios',
    ),
  }) {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWithValue(AsyncData(user)),
        supportRepositoryProvider.overrideWithValue(repository),
        supportClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportControllerProvider, (_, _) {});
    return container;
  }

  void fill(SupportController controller) {
    controller
      ..setSubject('  Credit rollover  ')
      ..setMessage(
        '  Can I pause my subscription and keep my credits?  ',
      );
  }

  test('support_howToUse_sendsCategoryTitleAndLowPriority', () async {
    final repository = FakeSupportRepository();
    final container = containerFor(repository);
    final controller = container.read(supportControllerProvider.notifier);
    fill(controller);
    controller.setCategory(SupportCategory.usingLookAtlas);
    expect(await controller.submit(), isTrue);
    final request = repository.requests.single;
    expect(request.title, '[How to use Look Atlas] Credit rollover');
    expect(request.name, 'Acme Studios');
    expect(request.priority, 'low');
    expect(request.message, 'Can I pause my subscription and keep my credits?');
    expect(container.read(supportControllerProvider).receipt?.id, 'LA-1042');
  });
  test('support_emptyFields_rejectsWithoutRequest', () async {
    final repository = FakeSupportRepository();
    final container = containerFor(repository);
    expect(
      await container.read(supportControllerProvider.notifier).submit(),
      isFalse,
    );
    expect(repository.requests, isEmpty);
  });
  test('support_signedOut_rejectsWithoutRequest', () async {
    final repository = FakeSupportRepository();
    final container = containerFor(repository, user: null);
    final controller = container.read(supportControllerProvider.notifier);
    fill(controller);
    expect(await controller.submit(), isFalse);
    expect(repository.requests, isEmpty);
    expect(
      container.read(supportControllerProvider).errorMessage,
      'Sign in to send a support request.',
    );
  });
  test('support_shortMessage_rejectsWithoutRequest', () async {
    final repository = FakeSupportRepository();
    final container = containerFor(repository);
    final controller = container.read(supportControllerProvider.notifier);
    fill(controller);
    controller.setMessage('short');
    expect(await controller.submit(), isFalse);
    expect(repository.requests, isEmpty);
  });
  test('support_concurrentSubmission_sendsOneRequest', () async {
    final repository = FakeSupportRepository();
    final pending = Completer<Result<SupportTicketReceipt>>();
    repository.pending = pending.future;
    final container = containerFor(repository);
    final controller = container.read(supportControllerProvider.notifier);
    fill(controller);
    final first = controller.submit();
    expect(await controller.submit(), isFalse);
    expect(repository.requests.length, 1);
    pending.complete(repository.result);
    expect(await first, isTrue);
  });
  test('support_rateLimited_honorsRetryAfter', () async {
    final repository = FakeSupportRepository(
      result: const Err(
        NetworkFailure(
          'Too many support requests.',
          code: 'RATE_LIMIT_EXCEEDED',
          statusCode: 429,
          details: {'retryAfterSeconds': 45},
        ),
      ),
    );
    final container = containerFor(repository);
    final controller = container.read(supportControllerProvider.notifier);
    fill(controller);
    expect(await controller.submit(), isFalse);
    expect(
      container.read(supportControllerProvider).retryAt,
      now.add(const Duration(seconds: 45)),
    );
    expect(await controller.submit(), isFalse);
    expect(repository.requests.length, 1);
  });
  test('support_serverFailure_preservesDraft', () async {
    final repository = FakeSupportRepository(
      result: const Err(
        NetworkFailure('Failed to send support ticket', statusCode: 500),
      ),
    );
    final container = containerFor(repository);
    final controller = container.read(supportControllerProvider.notifier);
    fill(controller);
    expect(await controller.submit(), isFalse);
    final state = container.read(supportControllerProvider);
    expect(state.subject.trim(), 'Credit rollover');
    expect(state.errorMessage, 'Failed to send support ticket');
    expect(state.submissionStatus, SupportSubmissionStatus.idle);
  });
  test('support_acknowledge_clearsCompletedDraft', () async {
    final container = containerFor(FakeSupportRepository());
    final controller = container.read(supportControllerProvider.notifier);
    fill(controller);
    await controller.submit();
    controller.acknowledgeSuccess();
    final state = container.read(supportControllerProvider);
    expect(state.subject, '');
    expect(state.message, '');
    expect(state.receipt, isNull);
  });
}
