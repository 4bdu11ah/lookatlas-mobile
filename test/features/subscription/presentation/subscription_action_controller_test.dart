import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/domain/subscription_repository.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_action.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_repositories.dart';

class _MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

void main() {
  final package = fakePackage();

  late _MockSubscriptionRepository repository;
  late ProviderContainer container;
  late List<SubscriptionAction> states;

  setUpAll(() => registerFallbackValue(fakePackage()));

  setUp(() {
    repository = _MockSubscriptionRepository();
    container = ProviderContainer(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    // Keeps the autoDispose controller alive and records every state change.
    states = [];
    container.listen<SubscriptionAction>(
      subscriptionActionProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  });

  SubscriptionActionController notifier() =>
      container.read(subscriptionActionProvider.notifier);

  group('purchase', () {
    test('goes busy then idle and returns true on success', () async {
      when(() => repository.purchase(any())).thenAnswer(
        (_) async => const Result.ok(FakeSubscriptionRepository.premiumStatus),
      );

      final succeeded = await notifier().purchase(package);

      expect(succeeded, isTrue);
      expect(states, [
        isA<SubscriptionIdle>(),
        isA<SubscriptionPurchasing>().having(
          (s) => s.packageId,
          'packageId',
          package.identifier,
        ),
        isA<SubscriptionIdle>().having((s) => s.failure, 'failure', isNull),
      ]);
    });

    test('user cancellation returns false and idles silently', () async {
      when(() => repository.purchase(any())).thenAnswer(
        (_) async => const Result.err(
          SubscriptionFailure('Purchase cancelled.', userCancelled: true),
        ),
      );

      final succeeded = await notifier().purchase(package);

      expect(succeeded, isFalse);
      expect(
        states.last,
        isA<SubscriptionIdle>().having((s) => s.failure, 'failure', isNull),
      );
    });

    test('failure returns false and surfaces the typed failure', () async {
      const failure = SubscriptionFailure(
        'We could not complete the purchase. Please try again.',
      );
      when(
        () => repository.purchase(any()),
      ).thenAnswer((_) async => const Result.err(failure));

      final succeeded = await notifier().purchase(package);

      expect(succeeded, isFalse);
      expect(
        states.last,
        isA<SubscriptionIdle>().having(
          (s) => s.failure,
          'failure',
          same(failure),
        ),
      );
    });

    test(
      'wraps a non-subscription failure into a SubscriptionFailure',
      () async {
        const failure = NetworkFailure('No connection.');
        when(
          () => repository.purchase(any()),
        ).thenAnswer((_) async => const Result.err(failure));

        await notifier().purchase(package);

        final surfaced = (states.last as SubscriptionIdle).failure;
        expect(surfaced, isA<SubscriptionFailure>());
        expect(surfaced?.cause, same(failure));
      },
    );
  });

  group('restore', () {
    test('goes busy then idle and returns true on success', () async {
      when(repository.restore).thenAnswer(
        (_) async => const Result.ok(FakeSubscriptionRepository.premiumStatus),
      );

      final succeeded = await notifier().restore();

      expect(succeeded, isTrue);
      expect(states, [
        isA<SubscriptionIdle>(),
        isA<SubscriptionRestoring>(),
        isA<SubscriptionIdle>().having((s) => s.failure, 'failure', isNull),
      ]);
    });
  });

  group('mutual exclusion', () {
    test('restore is a no-op while a purchase is in flight', () async {
      final purchaseCompleter = Completer<Result<SubscriptionStatus>>();
      when(
        () => repository.purchase(any()),
      ).thenAnswer((_) => purchaseCompleter.future);

      final purchaseFuture = notifier().purchase(package);
      final restored = await notifier().restore();

      expect(restored, isFalse);
      expect(
        container.read(subscriptionActionProvider),
        isA<SubscriptionPurchasing>(),
      );
      verifyNever(repository.restore);

      purchaseCompleter.complete(
        const Result.ok(FakeSubscriptionRepository.premiumStatus),
      );
      expect(await purchaseFuture, isTrue);
    });

    test('purchase is non-reentrant', () async {
      final purchaseCompleter = Completer<Result<SubscriptionStatus>>();
      when(
        () => repository.purchase(any()),
      ).thenAnswer((_) => purchaseCompleter.future);

      final firstPurchase = notifier().purchase(package);
      final reentrant = await notifier().purchase(package);

      expect(reentrant, isFalse);
      verify(() => repository.purchase(any())).called(1);

      purchaseCompleter.complete(
        const Result.ok(FakeSubscriptionRepository.premiumStatus),
      );
      expect(await firstPurchase, isTrue);
    });
  });
}
