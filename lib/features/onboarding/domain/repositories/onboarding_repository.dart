import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';

abstract interface class OnboardingRepository {
  Future<Result<OnboardingAppConfig>> fetchAppConfig();
  Future<Result<OnboardingStatus>> fetchStatus();
  Future<Result<void>> updateStatus(OnboardingTrackingStatus status);
  Future<Result<void>> completeOnboarding();
  Future<Result<String>> createProduct(ProductDraft draft);
  Future<Result<List<OnboardingProduct>>> fetchProducts();
  Future<Result<void>> updateProduct(String productId, ProductDraft draft);
  Future<Result<void>> updateProductAngles(
    String productId,
    Map<int, String?> angles,
  );
  Future<Result<List<LookAtlasModel>>> fetchModels();
  Future<Result<List<OnboardingUserModel>>> fetchUserModels();
  Future<Result<String>> createUserModel(UserModelDraft draft);
  Future<Result<StartShootResponse>> startShoot(StartShootRequest request);
}
