import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';

/// Signs the user in with their Apple ID.
///
/// A single-purpose domain action over [AuthRepository] so the presentation
/// layer depends on one intent, not the whole repository surface.
class SignInWithAppleUseCase {
  const SignInWithAppleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call() => _repository.signInWithApple();
}
