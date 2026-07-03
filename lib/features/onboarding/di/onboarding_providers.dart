import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/onboarding/data/onboarding_repository.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(api: ref.watch(apiServiceProvider)),
);

/// The latest model library for the wizard's "Choose a model" step.
///
/// autoDispose so leaving the step drops the cache and coming back refetches
/// fresh data. In dev builds an unreachable backend falls back to the bundled
/// starter models (the web client's `DEV_PREVIEW` behavior); in prod the
/// failure surfaces so the screen can show a retry.
final FutureProvider<List<LookAtlasModel>> lookAtlasModelsProvider =
    FutureProvider.autoDispose<List<LookAtlasModel>>((ref) async {
  final result = await ref.watch(onboardingRepositoryProvider).fetchModels();
  return result.fold(
    (models) => models,
    (failure) {
      if (AppConfig.isDev) return fallbackLibraryModels;
      throw failure;
    },
  );
});
