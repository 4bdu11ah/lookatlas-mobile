import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/storage/auth_token_cache.dart';
import 'package:look_atlas/core/storage/secure_storage.dart';
import 'package:look_atlas/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:look_atlas/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:look_atlas/features/auth/data/data_sources/social_auth_data_source.dart';
import 'package:look_atlas/features/auth/data/models/app_user_model.dart';
import 'package:look_atlas/features/auth/data/models/auth_session_model.dart';
import 'package:look_atlas/features/auth/data/models/social_credential.dart';
import 'package:look_atlas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/social_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockAuthTokenCache extends Mock implements AuthTokenCache {}

class _MockSocialAuthDataSource extends Mock implements SocialAuthDataSource {}

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late _MockSecureStorage storage;
  late _MockAuthTokenCache tokenCache;
  late _MockSocialAuthDataSource socialAuth;
  late _MockAuthRemoteDataSource remote;
  late AuthRepositoryImpl repository;

  const session = AuthSessionModel(
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    user: AppUserModel(
      id: 'user-1',
      email: 'jane@example.com',
      companyName: 'Acme Studios',
    ),
  );

  setUp(() {
    storage = _MockSecureStorage();
    tokenCache = _MockAuthTokenCache();
    socialAuth = _MockSocialAuthDataSource();
    remote = _MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(
      remote,
      AuthLocalDataSourceImpl(storage),
      tokenCache,
      storage,
      socialAuth,
    );

    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(storage.clearTokens).thenAnswer((_) async {});
    when(() => storage.setRefreshToken(any())).thenAnswer((_) async {});
    when(() => tokenCache.set(any())).thenAnswer((_) async {});
  });

  tearDown(() => repository.dispose());

  group('signInWithEmail', () {
    test('persists the session returned by POST /auth/login', () async {
      when(
        () => remote.login(email: 'jane@example.com', password: 'secret123'),
      ).thenAnswer((_) async => const Result.ok(session));

      final result = await repository.signInWithEmail(
        email: 'jane@example.com',
        password: 'secret123',
      );

      expect(result.valueOrNull?.email, 'jane@example.com');
      expect(repository.currentUser, isNotNull);
      verify(() => tokenCache.set('access-1')).called(1);
      verify(() => storage.setRefreshToken('refresh-1')).called(1);
    });

    test(
      'propagates a credentials failure without touching the session',
      () async {
        when(
          () => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const Result.err(
            AuthFailure('Incorrect email or password.'),
          ),
        );

        final result = await repository.signInWithEmail(
          email: 'jane@example.com',
          password: 'wrong-password',
        );

        expect(result.failureOrNull?.message, 'Incorrect email or password.');
        expect(repository.currentUser, isNull);
        verifyNever(() => tokenCache.set(any()));
      },
    );

    test('rejects an invalid email before calling the backend', () async {
      final result = await repository.signInWithEmail(
        email: 'not-an-email',
        password: 'secret123',
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      verifyZeroInteractions(remote);
    });

    test('rejects a password shorter than 8 characters', () async {
      final result = await repository.signInWithEmail(
        email: 'jane@example.com',
        password: '1234567',
      );

      expect(
        result.failureOrNull?.message,
        'Password must be at least 8 characters.',
      );
      verifyZeroInteractions(remote);
    });
  });

  group('signUpWithEmail', () {
    test('registers via POST /auth/register with the company name', () async {
      when(
        () => remote.register(
          companyName: 'Acme Studios',
          email: 'jane@example.com',
          password: 'secret123',
        ),
      ).thenAnswer((_) async => const Result.ok(session));

      final result = await repository.signUpWithEmail(
        email: 'jane@example.com',
        password: 'secret123',
        companyName: 'Acme Studios',
      );

      expect(result.valueOrNull?.companyName, 'Acme Studios');
      verify(() => tokenCache.set('access-1')).called(1);
    });

    test('rejects a blank company name before calling the backend', () async {
      final result = await repository.signUpWithEmail(
        email: 'jane@example.com',
        password: 'secret123',
        companyName: '   ',
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      verifyZeroInteractions(remote);
    });
  });

  group('social sign-in', () {
    const credential = SocialCredential(
      provider: SocialProvider.apple,
      id: 'apple-user-1',
      email: 'jane@icloud.com',
      displayName: 'Jane Doe',
      idToken: 'apple-identity-token',
    );

    test('persists the session and emits on success', () async {
      when(
        socialAuth.signInWithApple,
      ).thenAnswer((_) async => const Result.ok(credential));

      final emitted = <AppUser?>[];
      final subscription = repository.authStateChanges().listen(emitted.add);
      addTearDown(subscription.cancel);
      // Let the async* stream yield the initial state before acting.
      await Future<void>.delayed(Duration.zero);

      final result = await repository.signInWithApple();

      expect(result.isOk, isTrue);
      final user = result.valueOrNull;
      expect(user?.id, 'apple-apple-user-1');
      expect(user?.email, 'jane@icloud.com');
      expect(user?.displayName, 'Jane Doe');
      expect(repository.currentUser, user);
      // Session persisted like the email flow: cached user + primed token.
      verify(() => storage.write(any(), any())).called(1);
      verify(() => tokenCache.set('apple-identity-token')).called(1);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [null, user]);
    });

    test('propagates cancellation without touching the session', () async {
      when(socialAuth.signInWithApple).thenAnswer(
        (_) async => const Result.err(
          AuthFailure('Sign-in was cancelled.', userCancelled: true),
        ),
      );

      final result = await repository.signInWithApple();

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (f) => f.userCancelled,
          'userCancelled',
          isTrue,
        ),
      );
      expect(repository.currentUser, isNull);
      verifyNever(() => tokenCache.set(any()));
      verifyNever(() => storage.write(any(), any()));
    });
  });

  group('SocialAuthDataSourceImpl (unconfigured)', () {
    test('Google returns a friendly failure before touching the SDK', () async {
      // No GOOGLE_WEB_CLIENT_ID dart-define in tests -> hasGoogleAuth false.
      final result = await SocialAuthDataSourceImpl().signInWithGoogle();

      expect(
        result.failureOrNull,
        isA<AuthFailure>()
            .having(
              (f) => f.message,
              'message',
              'Google sign-in is not configured yet.',
            )
            .having((f) => f.userCancelled, 'userCancelled', isFalse),
      );
    });

    test('Apple fails friendly on non-Apple platforms', () async {
      // flutter_test pins defaultTargetPlatform to android by default.
      final result = await SocialAuthDataSourceImpl().signInWithApple();

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (f) => f.message,
          'message',
          'Sign in with Apple is only available on Apple devices.',
        ),
      );
    });
  });

  group('resetPassword', () {
    test('delegates to POST /auth/forgot-password', () async {
      when(
        () => remote.forgotPassword('jane@example.com'),
      ).thenAnswer((_) async => const Result.ok(null));

      final result = await repository.resetPassword(email: 'jane@example.com');

      expect(result.isOk, isTrue);
      verify(() => remote.forgotPassword('jane@example.com')).called(1);
    });

    test('rejects an invalid email before calling the backend', () async {
      final result = await repository.resetPassword(email: 'nope');

      expect(result.failureOrNull, isA<AuthFailure>());
      verifyZeroInteractions(remote);
    });
  });

  group('refreshSession', () {
    test('exchanges the stored refresh token and primes the cache', () async {
      when(() => storage.refreshToken).thenAnswer((_) async => 'refresh-1');
      when(
        () => remote.refresh('refresh-1'),
      ).thenAnswer((_) async => const Result.ok('access-2'));

      final token = await repository.refreshSession();

      expect(token, 'access-2');
      verify(() => tokenCache.set('access-2')).called(1);
    });

    test('returns null without a stored refresh token', () async {
      when(() => storage.refreshToken).thenAnswer((_) async => null);

      expect(await repository.refreshSession(), isNull);
      verifyZeroInteractions(remote);
    });

    test('returns null when the backend rejects the refresh token', () async {
      when(() => storage.refreshToken).thenAnswer((_) async => 'refresh-1');
      when(() => remote.refresh('refresh-1')).thenAnswer(
        (_) async => const Result.err(AuthFailure('Your session has expired.')),
      );

      expect(await repository.refreshSession(), isNull);
      verifyNever(() => tokenCache.set(any()));
    });
  });

  test(
    'handleSessionExpired clears the session without calling logout',
    () async {
      when(
        () => remote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Result.ok(session));
      await repository.signInWithEmail(
        email: 'jane@example.com',
        password: 'secret123',
      );

      await repository.handleSessionExpired();

      expect(repository.currentUser, isNull);
      verifyNever(remote.logout);
      verify(storage.clearTokens).called(1);
    },
  );

  test('restore loads the persisted session', () async {
    when(() => storage.read(any())).thenAnswer(
      (_) async => '{"id":"local-1","email":"jane@example.com"}',
    );

    await repository.restore();

    expect(repository.currentUser?.email, 'jane@example.com');
  });

  test('signOut calls the backend and clears the session', () async {
    when(
      () => remote.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Result.ok(session));
    when(tokenCache.get).thenAnswer((_) async => 'access-1');
    when(remote.logout).thenAnswer((_) async => const Result.ok(null));
    await repository.signInWithEmail(
      email: 'jane@example.com',
      password: 'secret123',
    );

    final result = await repository.signOut();

    expect(result.isOk, isTrue);
    expect(repository.currentUser, isNull);
    verify(remote.logout).called(1);
    verify(storage.clearTokens).called(1);
    verify(() => tokenCache.set(null)).called(1);
    verify(tokenCache.invalidate).called(1);
  });

  test(
    'signOut skips the backend call when there is no access token',
    () async {
      when(tokenCache.get).thenAnswer((_) async => null);

      final result = await repository.signOut();

      expect(result.isOk, isTrue);
      verifyNever(remote.logout);
      verify(storage.clearTokens).called(1);
    },
  );

  test('signOut still clears the session when the logout call fails', () async {
    when(tokenCache.get).thenAnswer((_) async => 'access-1');
    when(remote.logout).thenAnswer(
      (_) async => const Result.err(NetworkFailure('offline')),
    );

    final result = await repository.signOut();

    expect(result.isOk, isTrue);
    verify(storage.clearTokens).called(1);
  });
}
