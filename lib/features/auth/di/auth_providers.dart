import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:look_atlas/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:look_atlas/features/auth/data/data_sources/social_auth_data_source.dart';
import 'package:look_atlas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:look_atlas/features/auth/data/services/turnstile_service.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/auth/domain/use_cases/reset_password_use_case.dart';
import 'package:look_atlas/features/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:look_atlas/features/auth/domain/use_cases/sign_in_with_apple_use_case.dart';
import 'package:look_atlas/features/auth/domain/use_cases/sign_in_with_google_use_case.dart';
import 'package:look_atlas/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:look_atlas/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:look_atlas/services/service_providers.dart';

/// Dependency injection for the auth feature: wires the data source, repository
/// and use cases together. Presentation code (controllers, screens) depends on
/// these providers, never on the concrete implementations directly.

// --- Data layer ----------------------------------------------------------
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSourceImpl(ref.watch(secureStorageProvider)),
);

final socialAuthDataSourceProvider = Provider<SocialAuthDataSource>(
  (ref) => SocialAuthDataSourceImpl(),
);

final turnstileServiceProvider = Provider<TurnstileService>(
  (ref) => TurnstileService(),
);

/// Bare API client (no bearer / token-refresh interceptors) for the public
/// `/auth/*` endpoints. `/auth/refresh` in particular runs INSIDE the shared
/// client's 401 interceptor, so it must not re-enter that same queued
/// interceptor chain.
final authPublicApiServiceProvider = Provider<ApiService>(
  (ref) => ref.watch(publicApiServiceProvider),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(
    api: ref.watch(apiServiceProvider),
    publicApi: ref.watch(authPublicApiServiceProvider),
    registrationContext: () async => ref
        .read(deviceTokenServiceProvider)
        .context()
        .then((value) => value.toRegistrationJson()),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
    ref.watch(authTokenCacheProvider),
    ref.watch(secureStorageProvider),
    ref.watch(socialAuthDataSourceProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

// --- Domain use cases (one intent each) ----------------------------------
final signInUseCaseProvider = Provider<SignInUseCase>(
  (ref) => SignInUseCase(ref.watch(authRepositoryProvider)),
);
final signUpUseCaseProvider = Provider<SignUpUseCase>(
  (ref) => SignUpUseCase(ref.watch(authRepositoryProvider)),
);
final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);
final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>(
  (ref) => ResetPasswordUseCase(ref.watch(authRepositoryProvider)),
);
final signInWithAppleUseCaseProvider = Provider<SignInWithAppleUseCase>(
  (ref) => SignInWithAppleUseCase(ref.watch(authRepositoryProvider)),
);
final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>(
  (ref) => SignInWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);
