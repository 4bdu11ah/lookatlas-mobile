import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/auth/domain/use_cases/reset_password_use_case.dart';
import 'package:look_atlas/features/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:look_atlas/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('signIn_invalidEmail_rejectsBeforeRepositoryCall', () async {
    final repository = _MockAuthRepository();

    final result = await SignInUseCase(repository)(
      email: 'not-an-email',
      password: 'secret123',
    );

    expect(result.failureOrNull, isA<AuthFailure>());
    verifyZeroInteractions(repository);
  });

  test('signIn_shortPassword_rejectsBeforeRepositoryCall', () async {
    final repository = _MockAuthRepository();

    final result = await SignInUseCase(repository)(
      email: 'jane@example.com',
      password: '1234567',
    );

    expect(
      result.failureOrNull?.message,
      'Password must be at least 8 characters.',
    );
    verifyZeroInteractions(repository);
  });

  test('signUp_blankCompany_rejectsBeforeRepositoryCall', () async {
    final repository = _MockAuthRepository();

    final result = await SignUpUseCase(repository)(
      email: 'jane@example.com',
      password: 'secret123',
      companyName: '   ',
    );

    expect(result.failureOrNull, isA<AuthFailure>());
    verifyZeroInteractions(repository);
  });

  test('resetPassword_invalidEmail_rejectsBeforeRepositoryCall', () async {
    final repository = _MockAuthRepository();

    final result = await ResetPasswordUseCase(repository)(email: 'nope');

    expect(result.failureOrNull, isA<AuthFailure>());
    verifyZeroInteractions(repository);
  });

  test('signUp_validInput_normalizesEmailAndCompany', () async {
    final repository = _MockAuthRepository();
    when(
      () => repository.signUpWithEmail(
        email: 'jane@example.com',
        password: 'secret123',
        companyName: 'Acme',
      ),
    ).thenAnswer(
      (_) async => const Ok(
        AppUser(
          id: 'user-1',
          email: 'jane@example.com',
          companyName: 'Acme',
        ),
      ),
    );

    await SignUpUseCase(repository)(
      email: '  jane@example.com  ',
      password: 'secret123',
      companyName: '  Acme  ',
    );

    verify(
      () => repository.signUpWithEmail(
        email: 'jane@example.com',
        password: 'secret123',
        companyName: 'Acme',
      ),
    ).called(1);
  });
}
