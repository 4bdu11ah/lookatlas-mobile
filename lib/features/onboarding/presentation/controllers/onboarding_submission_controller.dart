import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/services/service_providers.dart';

@immutable
class OnboardingSubmissionState {
  const OnboardingSubmissionState({
    this.isSubmitting = false,
    this.isSavingProduct = false,
    this.isSavingModel = false,
    this.productId,
    this.modelId,
    this.shoot,
    this.failure,
  });

  final bool isSubmitting;
  final bool isSavingProduct;
  final bool isSavingModel;
  final String? productId;
  final String? modelId;
  final StartShootResponse? shoot;
  final Failure? failure;
}

class OnboardingSubmissionController
    extends Notifier<OnboardingSubmissionState> {
  static const int _maxUploadBytes = 10 * 1024 * 1024;
  String? _productName;
  String? _productSku;

  @override
  OnboardingSubmissionState build() => const OnboardingSubmissionState();

  void restoreProductId(String productId) {
    if (state.productId != null) return;
    state = OnboardingSubmissionState(
      productId: productId,
      modelId: state.modelId,
      shoot: state.shoot,
    );
  }

  Future<bool> saveProductPhotos(WizardState wizard) async {
    if (state.isSavingProduct || state.isSubmitting) return false;
    final previous = state;
    state = OnboardingSubmissionState(
      isSavingProduct: true,
      productId: previous.productId,
      modelId: previous.modelId,
      shoot: previous.shoot,
    );
    final result = await _saveProduct(wizard, previous.productId);
    final productId = result.valueOrNull;
    if (productId == null) {
      return _fail(
        result.failureOrNull,
        productId: previous.productId,
        modelId: previous.modelId,
      );
    }
    state = OnboardingSubmissionState(
      productId: productId,
      modelId: previous.modelId,
      shoot: previous.shoot,
    );
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            'wizard.product_uploaded',
            properties: {'photo_count': wizard.photos.length},
          ),
    );
    return true;
  }

  Future<bool> saveProductAngles(WizardState wizard) async {
    if (state.isSavingProduct || state.isSubmitting) return false;
    if (!wizard.allAnglesTagged) {
      return _fail(
        const ValidationFailure('Tag every product photo with an angle.'),
        productId: state.productId,
        modelId: state.modelId,
      );
    }
    if (state.productId == null && !(await saveProductPhotos(wizard))) {
      return false;
    }
    final productId = state.productId;
    if (productId == null) return false;
    state = OnboardingSubmissionState(
      isSavingProduct: true,
      productId: productId,
      modelId: state.modelId,
      shoot: state.shoot,
    );
    final result = await ref.read(updateProductAnglesUseCaseProvider)(
      productId,
      _photoAngles(wizard),
    );
    if (result case Err(:final failure)) {
      return _fail(failure, productId: productId, modelId: state.modelId);
    }
    state = OnboardingSubmissionState(
      productId: productId,
      modelId: state.modelId,
      shoot: state.shoot,
    );
    return true;
  }

  Future<bool> saveUserModelPhotos(List<Uint8List> photos) async {
    if (state.isSavingModel || state.isSubmitting) return false;
    if (photos.any((photo) => photo.length > _maxUploadBytes)) {
      return _fail(
        const ValidationFailure('Each model photo must be 10MB or smaller.'),
        productId: state.productId,
        modelId: state.modelId,
      );
    }
    final previous = state;
    state = OnboardingSubmissionState(
      isSavingModel: true,
      productId: previous.productId,
      modelId: previous.modelId,
      shoot: previous.shoot,
    );
    final result = await ref.read(createUserModelUseCaseProvider)(
      UserModelDraft(
        name: 'Model - ${DateTime.now().toIso8601String().split('T').first}',
        gender: UserModelGender.unspecified,
        photos: [
          for (final entry in photos.indexed)
            OnboardingUpload(
              bytes: entry.$2,
              fileName: 'model-${entry.$1 + 1}.jpg',
            ),
        ],
      ),
    );
    final modelId = result.valueOrNull;
    if (modelId == null) {
      return _fail(
        result.failureOrNull,
        productId: previous.productId,
        modelId: previous.modelId,
      );
    }
    state = OnboardingSubmissionState(
      productId: previous.productId,
      modelId: modelId,
      shoot: previous.shoot,
    );
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            'wizard.model_selected',
            properties: {'model_id': modelId, 'model_source': 'user'},
          ),
    );
    return true;
  }

  Future<bool> submit(WizardState wizard) async {
    if (state.isSubmitting) return false;
    final previous = state;
    state = OnboardingSubmissionState(
      isSubmitting: true,
      productId: previous.productId,
      modelId: previous.modelId,
    );
    final config = await _loadConfig();
    final productResult = previous.productId == null
        ? await _saveProduct(wizard, null)
        : Ok(previous.productId!);
    final productId = productResult.valueOrNull;
    if (productId == null) {
      return _fail(productResult.failureOrNull, modelId: previous.modelId);
    }

    final anglesResult = await ref.read(updateProductAnglesUseCaseProvider)(
      productId,
      _photoAngles(wizard),
    );
    if (anglesResult case Err(:final failure)) {
      return _fail(failure, productId: productId, modelId: previous.modelId);
    }

    final modelResult = await _resolveModel(wizard, previous.modelId);
    final modelId = modelResult.valueOrNull;
    if (modelId == null) {
      return _fail(modelResult.failureOrNull, productId: productId);
    }

    String? deviceFingerprint;
    String? deviceToken;
    String? uaFamily;
    String? screenHash;
    int? tzOffset;
    try {
      final device = await ref.read(deviceTokenServiceProvider).context();
      deviceFingerprint = device.fingerprint;
      deviceToken = device.deviceToken;
      uaFamily = device.uaFamily;
      screenHash = device.screenHash;
      tzOffset = device.tzOffset;
    } on Object {
      // Abuse-detection signals are optional. Native channel or bootstrap
      // failure must not block an otherwise valid shoot request.
    }
    final shootResult = await ref.read(startFreeShootUseCaseProvider)(
      StartShootRequest(
        productId: productId,
        modelId: modelId,
        modelSource: wizard.usingUploadedModel
            ? ShootModelSource.user
            : ShootModelSource.lookatlas,
        settings: ShootSettings(
          directorId: wizard.selectedDirector?.apiId ?? 'clean-pro',
          aspectRatio: config.defaultAspectRatio,
        ),
        deviceFingerprint: deviceFingerprint,
        deviceToken: deviceToken,
        uaFamily: uaFamily,
        screenHash: screenHash,
        tzOffset: tzOffset,
      ),
    );
    final shoot = shootResult.valueOrNull;
    if (shoot == null) {
      return _fail(
        shootResult.failureOrNull,
        productId: productId,
        modelId: modelId,
      );
    }

    state = OnboardingSubmissionState(
      productId: productId,
      modelId: modelId,
      shoot: shoot,
    );
    unawaited(ref.read(analyticsServiceProvider).track('wizard.shoot_started'));
    unawaited(
      ref.read(updateOnboardingStatusUseCaseProvider)(
        OnboardingTrackingStatus.generating,
      ),
    );
    return true;
  }

  Future<OnboardingAppConfig> _loadConfig() async {
    final result = await ref.read(getOnboardingConfigUseCaseProvider)();
    return result.valueOrNull ?? OnboardingAppConfig.fallback;
  }

  Future<Result<String>> _saveProduct(
    WizardState wizard,
    String? existingId,
  ) async {
    if (wizard.photos.any((photo) => photo.bytes.length > _maxUploadBytes)) {
      return const Err(
        ValidationFailure('Each product photo must be 10MB or smaller.'),
      );
    }
    final draft = _productDraft(wizard);
    if (existingId == null) {
      return ref.read(createOnboardingProductUseCaseProvider)(draft);
    }
    final result = await ref.read(updateOnboardingProductUseCaseProvider)(
      existingId,
      draft,
    );
    return result.map((_) => existingId);
  }

  ProductDraft _productDraft(WizardState wizard) {
    final now = DateTime.now();
    final productName = _productName ??=
        'Product - ${now.toIso8601String().split('T').first}';
    final productSku = _productSku ??=
        'onboarding-${now.millisecondsSinceEpoch}';
    return ProductDraft(
      name: productName,
      sku: productSku,
      category: wizard.category?.name ?? 'other',
      photos: [
        for (final entry in wizard.photos.indexed)
          OnboardingUpload(
            bytes: entry.$2.bytes,
            fileName: 'product-${entry.$1 + 1}.jpg',
          ),
      ],
    );
  }

  Map<int, String?> _photoAngles(WizardState wizard) => {
    for (final entry in wizard.photos.indexed)
      entry.$1: entry.$2.angle?.toLowerCase(),
  };

  Future<Result<String>> _resolveModel(
    WizardState wizard,
    String? existingId,
  ) {
    if (!wizard.usingUploadedModel) {
      final id = wizard.selectedModel?.id;
      return Future.value(
        id == null || id.isEmpty
            ? const Err(ValidationFailure('Select a model to continue.'))
            : Ok(id),
      );
    }
    final selectedUserModelId = wizard.selectedUserModel?.id;
    if (selectedUserModelId != null && selectedUserModelId.isNotEmpty) {
      return Future.value(Ok(selectedUserModelId));
    }
    if (existingId != null) return Future.value(Ok(existingId));
    if (wizard.uploadedModelPhotos.any(
      (photo) => photo.length > _maxUploadBytes,
    )) {
      return Future.value(
        const Err(
          ValidationFailure('Each model photo must be 10MB or smaller.'),
        ),
      );
    }
    return ref.read(createUserModelUseCaseProvider)(
      UserModelDraft(
        name: 'Model - ${DateTime.now().toIso8601String().split('T').first}',
        gender: UserModelGender.unspecified,
        photos: [
          for (final entry in wizard.uploadedModelPhotos.indexed)
            OnboardingUpload(
              bytes: entry.$2,
              fileName: 'model-${entry.$1 + 1}.jpg',
            ),
        ],
      ),
    );
  }

  bool _fail(
    Failure? failure, {
    String? productId,
    String? modelId,
  }) {
    state = OnboardingSubmissionState(
      productId: productId,
      modelId: modelId,
      failure: failure ?? const UnknownFailure('Could not start the shoot.'),
    );
    return false;
  }
}

final onboardingSubmissionControllerProvider =
    NotifierProvider<OnboardingSubmissionController, OnboardingSubmissionState>(
      OnboardingSubmissionController.new,
    );
