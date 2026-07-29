import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/domain/subscription_repository.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  const user = AppUser(id: 'user-1', email: 'jane@example.com');
  const failure = AuthFailure('Invalid credentials.');

  late _MockAuthRepository authRepository;
  late _MockSubscriptionRepository subscriptions;
  late _MockAnalyticsService analytics;
  late ProviderContainer container;
  late List<AsyncValue<void>> states;

  setUp(() {
    authRepository = _MockAuthRepository();
    subscriptions = _MockSubscriptionRepository();
    analytics = _MockAnalyticsService();

    when(() => subscriptions.logIn(any())).thenAnswer((_) async {});
    when(subscriptions.logOut).thenAnswer((_) async {});
    when(
      () => analytics.identify(any(), traits: any(named: 'traits')),
    ).thenAnswer((_) async {});
    when(analytics.reset).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        subscriptionRepositoryProvider.overrideWithValue(subscriptions),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);

    // Keeps the autoDispose controller alive and records every state change.
    states = [];
    container.listen<AsyncValue<void>>(
      authControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  });

  /// Lets the controller's fire-and-forget side effects run to completion.
  Future<void> flushSideEffects() => Future<void>.delayed(Duration.zero);

  group('signIn', () {
    test('emits loading then data and returns true on success', () async {
      when(
        () => authRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Result.ok(user));

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signIn('jane@example.com', 'secret123');

      expect(succeeded, isTrue);
      expect(states, const [
        AsyncData<void>(null),
        AsyncLoading<void>(),
        AsyncData<void>(null),
      ]);
    });

    test('identifies the user with subscriptions and analytics', () async {
      when(
        () => authRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Result.ok(user));

      await container
          .read(authControllerProvider.notifier)
          .signIn('jane@example.com', 'secret123');
      await flushSideEffects();

      verify(() => subscriptions.logIn('user-1')).called(1);
      verify(
        () => analytics.identify(
          'user-1',
          traits: {'email': 'jane@example.com'},
        ),
      ).called(1);
    });

    test('emits the typed failure and returns false on error', () async {
      when(
        () => authRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Result.err(failure));

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signIn('jane@example.com', 'wrong-password');
      await flushSideEffects();

      expect(succeeded, isFalse);
      expect(states[1], const AsyncLoading<void>());
      expect(
        states.last,
        isA<AsyncError<void>>().having((s) => s.error, 'error', same(failure)),
      );
      verifyNever(() => subscriptions.logIn(any()));
      verifyNever(
        () => analytics.identify(any(), traits: any(named: 'traits')),
      );
    });
  });

  group('signUp', () {
    test('returns true and identifies the new user on success', () async {
      when(
        () => authRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          companyName: any(named: 'companyName'),
        ),
      ).thenAnswer((_) async => const Result.ok(user));

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signUp(
            email: 'jane@example.com',
            password: 'secret123',
            companyName: 'Acme Inc.',
          );
      await flushSideEffects();

      expect(succeeded, isTrue);
      verify(() => subscriptions.logIn('user-1')).called(1);
    });
  });

  group('social sign-in', () {
    test('signInWithApple identifies the user on success', () async {
      when(
        authRepository.signInWithApple,
      ).thenAnswer((_) async => const Result.ok(user));

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signInWithApple();
      await flushSideEffects();

      expect(succeeded, isTrue);
      expect(states, const [
        AsyncData<void>(null),
        AsyncLoading<void>(),
        AsyncData<void>(null),
      ]);
      // Same _syncIdentity path as email sign-in, so the RevenueCat
      // purchase-transfer flow keeps working for social sign-ins.
      verify(() => subscriptions.logIn('user-1')).called(1);
      verify(
        () => analytics.identify(
          'user-1',
          traits: {'email': 'jane@example.com'},
        ),
      ).called(1);
    });

    test('signInWithGoogle identifies the user on success', () async {
      when(
        authRepository.signInWithGoogle,
      ).thenAnswer((_) async => const Result.ok(user));

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();
      await flushSideEffects();

      expect(succeeded, isTrue);
      verify(() => subscriptions.logIn('user-1')).called(1);
    });

    test('signInWithGoogle stops loading when the SDK throws', () async {
      when(authRepository.signInWithGoogle).thenThrow(
        StateError('Google SDK failed.'),
      );

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(succeeded, isFalse);
      expect(states.last, isA<AsyncError<void>>());
    });

    test('a cancelled sheet returns false without an error state', () async {
      when(authRepository.signInWithGoogle).thenAnswer(
        (_) async => const Result.err(
          AuthFailure('Sign-in was cancelled.', userCancelled: true),
        ),
      );

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();
      await flushSideEffects();

      expect(succeeded, isFalse);
      // Cancelling is not an error: the state settles back to AsyncData so
      // the screens never show a snackbar for it.
      expect(states, const [
        AsyncData<void>(null),
        AsyncLoading<void>(),
        AsyncData<void>(null),
      ]);
      verifyNever(() => subscriptions.logIn(any()));
      verifyNever(
        () => analytics.identify(any(), traits: any(named: 'traits')),
      );
    });

    test('a real social failure surfaces as AsyncError', () async {
      const socialFailure = AuthFailure(
        'Google sign-in is not configured yet.',
      );
      when(
        authRepository.signInWithGoogle,
      ).thenAnswer((_) async => const Result.err(socialFailure));

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();
      await flushSideEffects();

      expect(succeeded, isFalse);
      expect(
        states.last,
        isA<AsyncError<void>>().having(
          (s) => s.error,
          'error',
          same(socialFailure),
        ),
      );
      verifyNever(() => subscriptions.logIn(any()));
    });
  });

  group('resetPassword', () {
    test('returns true on success without touching identity', () async {
      when(
        () => authRepository.resetPassword(email: any(named: 'email')),
      ).thenAnswer((_) async => const Result.ok(null));

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .resetPassword('jane@example.com');
      await flushSideEffects();

      expect(succeeded, isTrue);
      expect(states.last, const AsyncData<void>(null));
      verifyNever(() => subscriptions.logIn(any()));
    });
  });

  group('signOut', () {
    test('goes through loading and clears the identity', () async {
      when(
        authRepository.signOut,
      ).thenAnswer((_) async => const Result.ok(null));

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signOut();
      await flushSideEffects();

      expect(succeeded, isTrue);
      expect(states, const [
        AsyncData<void>(null),
        AsyncLoading<void>(),
        AsyncData<void>(null),
      ]);
      verify(subscriptions.logOut).called(1);
      verify(analytics.reset).called(1);
    });

    test('surfaces a sign-out failure and keeps the identity', () async {
      when(
        authRepository.signOut,
      ).thenAnswer((_) async => const Result.err(failure));

      final succeeded = await container
          .read(authControllerProvider.notifier)
          .signOut();
      await flushSideEffects();

      expect(succeeded, isFalse);
      expect(
        states.last,
        isA<AsyncError<void>>().having((s) => s.error, 'error', same(failure)),
      );
      verifyNever(subscriptions.logOut);
      verifyNever(analytics.reset);
    });
  });
}
