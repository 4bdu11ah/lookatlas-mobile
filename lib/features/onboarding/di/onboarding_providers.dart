import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/onboarding/data/data_sources/onboarding_remote_data_source.dart';
import 'package:look_atlas/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:look_atlas/features/onboarding/domain/use_cases/onboarding_use_cases.dart';

final onboardingRemoteDataSourceProvider = Provider<OnboardingRemoteDataSource>(
  (ref) => OnboardingRemoteDataSourceImpl(api: ref.watch(apiServiceProvider)),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepositoryImpl(
    ref.watch(onboardingRemoteDataSourceProvider),
  ),
);

final getOnboardingConfigUseCaseProvider = Provider<GetOnboardingConfigUseCase>(
  (ref) => GetOnboardingConfigUseCase(ref.watch(onboardingRepositoryProvider)),
);
final getOnboardingStatusUseCaseProvider = Provider<GetOnboardingStatusUseCase>(
  (ref) => GetOnboardingStatusUseCase(ref.watch(onboardingRepositoryProvider)),
);
final updateOnboardingStatusUseCaseProvider =
    Provider<UpdateOnboardingStatusUseCase>(
      (ref) => UpdateOnboardingStatusUseCase(
        ref.watch(onboardingRepositoryProvider),
      ),
    );
final completeOnboardingUseCaseProvider = Provider<CompleteOnboardingUseCase>(
  (ref) => CompleteOnboardingUseCase(ref.watch(onboardingRepositoryProvider)),
);
final createOnboardingProductUseCaseProvider =
    Provider<CreateOnboardingProductUseCase>(
      (ref) => CreateOnboardingProductUseCase(
        ref.watch(onboardingRepositoryProvider),
      ),
    );
final getOnboardingProductsUseCaseProvider =
    Provider<GetOnboardingProductsUseCase>(
      (ref) => GetOnboardingProductsUseCase(
        ref.watch(onboardingRepositoryProvider),
      ),
    );
final updateOnboardingProductUseCaseProvider =
    Provider<UpdateOnboardingProductUseCase>(
      (ref) => UpdateOnboardingProductUseCase(
        ref.watch(onboardingRepositoryProvider),
      ),
    );
final updateProductAnglesUseCaseProvider = Provider<UpdateProductAnglesUseCase>(
  (ref) => UpdateProductAnglesUseCase(ref.watch(onboardingRepositoryProvider)),
);
final getLookAtlasModelsUseCaseProvider = Provider<GetLookAtlasModelsUseCase>(
  (ref) => GetLookAtlasModelsUseCase(ref.watch(onboardingRepositoryProvider)),
);
final getOnboardingUserModelsUseCaseProvider =
    Provider<GetOnboardingUserModelsUseCase>(
      (ref) => GetOnboardingUserModelsUseCase(
        ref.watch(onboardingRepositoryProvider),
      ),
    );
final createUserModelUseCaseProvider = Provider<CreateUserModelUseCase>(
  (ref) => CreateUserModelUseCase(ref.watch(onboardingRepositoryProvider)),
);
final startFreeShootUseCaseProvider = Provider<StartFreeShootUseCase>(
  (ref) => StartFreeShootUseCase(ref.watch(onboardingRepositoryProvider)),
);

final onboardingAppConfigProvider = FutureProvider<OnboardingAppConfig>((
  ref,
) async {
  final result = await ref.watch(getOnboardingConfigUseCaseProvider)();
  return result.fold(
    (config) => config,
    (_) => OnboardingAppConfig.fallback,
  );
});

final FutureProvider<OnboardingStatus> onboardingStatusProvider =
    FutureProvider.autoDispose<OnboardingStatus>((ref) async {
      final result = await ref.watch(getOnboardingStatusUseCaseProvider)();
      return result.fold((status) => status, (failure) => throw failure);
    });

final FutureProvider<List<OnboardingProduct>> onboardingProductsProvider =
    FutureProvider.autoDispose<List<OnboardingProduct>>((ref) async {
      final result = await ref.watch(getOnboardingProductsUseCaseProvider)();
      return result.fold((products) => products, (failure) => throw failure);
    });

final FutureProvider<List<LookAtlasModel>> lookAtlasModelsProvider =
    FutureProvider.autoDispose<List<LookAtlasModel>>((ref) async {
      final result = await ref.watch(getLookAtlasModelsUseCaseProvider)();
      return result.fold(
        (models) => models,
        (failure) {
          if (AppConfig.isDev) return fallbackLibraryModels;
          throw failure;
        },
      );
    });

final FutureProvider<List<OnboardingUserModel>> onboardingUserModelsProvider =
    FutureProvider.autoDispose<List<OnboardingUserModel>>((ref) async {
      final result = await ref.watch(getOnboardingUserModelsUseCaseProvider)();
      return result.fold((models) => models, (failure) => throw failure);
    });
