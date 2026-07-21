import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:look_atlas/features/onboarding/presentation/controllers/onboarding_submission_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';

void main() {
  test('submit_library_model_creates_product_angles_and_shoot', () async {
    final repository = _FakeOnboardingRepository();
    final container = ProviderContainer(
      overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(onboardingSubmissionControllerProvider.notifier)
        .submit(_wizardState());

    expect(success, isTrue);
    expect(repository.productDraft?.category, 'tops');
    expect(repository.angles, {0: 'front', 1: 'back'});
    expect(repository.startRequest?.modelId, 'library-model');
    expect(repository.startRequest?.modelSource, ShootModelSource.lookatlas);
    expect(repository.startRequest?.settings.aspectRatio, '3:4');
    expect(repository.startRequest?.settings.directorId, 'luxury-editorial');
  });

  test('submit_start_failure_preserves_backend_code_for_routing', () async {
    final repository = _FakeOnboardingRepository()
      ..startResult = const Result.err(
        NetworkFailure(
          'Free shoot is unavailable.',
          statusCode: 403,
          code: 'FREE_SHOOT_UNAVAILABLE',
        ),
      );
    final container = ProviderContainer(
      overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(onboardingSubmissionControllerProvider.notifier)
        .submit(_wizardState());
    final failure = container
        .read(onboardingSubmissionControllerProvider)
        .failure;

    expect(success, isFalse);
    expect(
      failure,
      isA<NetworkFailure>()
          .having(
            (value) => value.code,
            'code',
            'FREE_SHOOT_UNAVAILABLE',
          )
          .having(
            (value) => value.message,
            'message',
            'Free shoot is unavailable.',
          ),
    );
  });
}

WizardState _wizardState() => WizardState(
  step: WizardStep.review,
  category: ProductCategory.tops,
  photos: [
    WizardPhoto(bytes: Uint8List(2), angle: 'Front'),
    WizardPhoto(bytes: Uint8List(2), angle: 'Back'),
  ],
  selectedModel: const LookAtlasModel(
    id: 'library-model',
    name: 'Library model',
  ),
  selectedDirector: directors[1],
);

class _FakeOnboardingRepository implements OnboardingRepository {
  ProductDraft? productDraft;
  Map<int, String?>? angles;
  StartShootRequest? startRequest;
  Result<StartShootResponse> startResult = const Result.ok(
    StartShootResponse(
      id: 'job-1',
      status: 'pending',
      message: 'Started',
      shotCount: 3,
      variations: 5,
      totalImages: 15,
    ),
  );

  @override
  Future<Result<OnboardingAppConfig>> fetchAppConfig() async => const Result.ok(
    OnboardingAppConfig(
      imageProvider: 'gemini',
      supportedAspectRatios: ['3:4'],
      defaultAspectRatio: '3:4',
    ),
  );

  @override
  Future<Result<String>> createProduct(ProductDraft draft) async {
    productDraft = draft;
    return const Result.ok('product-1');
  }

  @override
  Future<Result<void>> updateProductAngles(
    String productId,
    Map<int, String?> angles,
  ) async {
    this.angles = angles;
    return const Result.ok(null);
  }

  @override
  Future<Result<StartShootResponse>> startShoot(
    StartShootRequest request,
  ) async {
    startRequest = request;
    return startResult;
  }

  @override
  Future<Result<void>> updateStatus(OnboardingTrackingStatus status) async =>
      const Result.ok(null);

  @override
  Future<Result<String>> createUserModel(UserModelDraft draft) async =>
      const Result.ok('user-model-1');

  @override
  Future<Result<List<LookAtlasModel>>> fetchModels() async =>
      const Result.ok([]);

  @override
  Future<Result<List<OnboardingProduct>>> fetchProducts() async =>
      const Result.ok([]);

  @override
  Future<Result<OnboardingStatus>> fetchStatus() async => const Result.ok(
    OnboardingStatus(
      freeShootUsed: false,
      onboardingImages: [],
      hasCalibration: false,
    ),
  );

  @override
  Future<Result<void>> updateProduct(
    String productId,
    ProductDraft draft,
  ) async => const Result.ok(null);
}
