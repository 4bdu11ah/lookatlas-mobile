import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/data/data_sources/onboarding_remote_data_source.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._remote);

  final OnboardingRemoteDataSource _remote;

  @override
  Future<Result<OnboardingAppConfig>> fetchAppConfig() async =>
      (await _remote.fetchAppConfig()).map((model) => model.toEntity());

  @override
  Future<Result<OnboardingStatus>> fetchStatus() async =>
      (await _remote.fetchStatus()).map((model) => model.toEntity());

  @override
  Future<Result<void>> updateStatus(OnboardingTrackingStatus status) =>
      _remote.updateStatus(status);

  @override
  Future<Result<void>> completeOnboarding() => _remote.completeOnboarding();

  @override
  Future<Result<String>> createProduct(ProductDraft draft) =>
      _remote.createProduct(draft);

  @override
  Future<Result<List<OnboardingProduct>>> fetchProducts() async =>
      (await _remote.fetchProducts()).map(
        (models) => [for (final model in models) model.toEntity()],
      );

  @override
  Future<Result<void>> updateProduct(String productId, ProductDraft draft) =>
      _remote.updateProduct(productId, draft);

  @override
  Future<Result<void>> updateProductAngles(
    String productId,
    Map<int, String?> angles,
  ) => _remote.updateProductAngles(productId, angles);

  @override
  Future<Result<List<LookAtlasModel>>> fetchModels() async =>
      (await _remote.fetchModels()).map((models) {
        final entities = [
          for (final model in models) model.toEntity(),
        ]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return entities;
      });

  @override
  Future<Result<List<OnboardingUserModel>>> fetchUserModels() async =>
      (await _remote.fetchUserModels()).map(
        (models) => [for (final model in models) model.toEntity()],
      );

  @override
  Future<Result<String>> createUserModel(UserModelDraft draft) =>
      _remote.createUserModel(draft);

  @override
  Future<Result<StartShootResponse>> startShoot(
    StartShootRequest request,
  ) async => (await _remote.startShoot(request)).map(
    (model) => model.toEntity(),
  );
}
