import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/data/models/look_atlas_model_dto.dart';
import 'package:look_atlas/features/onboarding/data/models/onboarding_config_model.dart';
import 'package:look_atlas/features/onboarding/data/models/onboarding_product_model.dart';
import 'package:look_atlas/features/onboarding/data/models/onboarding_status_model.dart';
import 'package:look_atlas/features/onboarding/data/models/onboarding_user_model_dto.dart';
import 'package:look_atlas/features/onboarding/data/models/start_shoot_response_model.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';

abstract interface class OnboardingRemoteDataSource {
  Future<Result<OnboardingAppConfigModel>> fetchAppConfig();
  Future<Result<OnboardingStatusModel>> fetchStatus();
  Future<Result<void>> updateStatus(OnboardingTrackingStatus status);
  Future<Result<void>> completeOnboarding();
  Future<Result<String>> createProduct(ProductDraft draft);
  Future<Result<List<OnboardingProductModel>>> fetchProducts();
  Future<Result<void>> updateProduct(String productId, ProductDraft draft);
  Future<Result<void>> updateProductAngles(
    String productId,
    Map<int, String?> angles,
  );
  Future<Result<List<LookAtlasModelDto>>> fetchModels();
  Future<Result<List<OnboardingUserModelDto>>> fetchUserModels();
  Future<Result<String>> createUserModel(UserModelDraft draft);
  Future<Result<StartShootResponseModel>> startShoot(StartShootRequest request);
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  const OnboardingRemoteDataSourceImpl({required ApiService api}) : _api = api;

  final ApiService _api;

  @override
  Future<Result<OnboardingAppConfigModel>> fetchAppConfig() =>
      _api.get<OnboardingAppConfigModel>(
        ApiEndpoints.appConfig,
        decoder: (data) => OnboardingAppConfigModel.fromJson(_map(data)),
      );

  @override
  Future<Result<OnboardingStatusModel>> fetchStatus() =>
      _api.get<OnboardingStatusModel>(
        ApiEndpoints.onboardingStatus,
        decoder: (data) => OnboardingStatusModel.fromJson(_map(data)),
      );

  @override
  Future<Result<void>> updateStatus(OnboardingTrackingStatus status) =>
      _api.post<void>(
        ApiEndpoints.onboardingUpdateStatus,
        data: {'status': status.name},
        decoder: (_) {},
      );

  @override
  Future<Result<void>> completeOnboarding() => _api.post<void>(
    ApiEndpoints.onboardingComplete,
    data: const <String, Object?>{},
    decoder: (_) {},
  );

  @override
  Future<Result<String>> createProduct(ProductDraft draft) => _api.post<String>(
    ApiEndpoints.products,
    data: _productFormData(draft),
    decoder: _requiredId,
  );

  @override
  Future<Result<List<OnboardingProductModel>>> fetchProducts() =>
      _api.get<List<OnboardingProductModel>>(
        ApiEndpoints.products,
        queryParameters: const {'includePhotos': true},
        decoder: (data) => [
          for (final item in _map(data)['products'] as List? ?? const [])
            if (item is Map<String, dynamic>)
              OnboardingProductModel.fromJson(item),
        ],
      );

  @override
  Future<Result<void>> updateProduct(
    String productId,
    ProductDraft draft,
  ) => _api.put<void>(
    ApiEndpoints.product(productId),
    data: _productFormData(draft),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> updateProductAngles(
    String productId,
    Map<int, String?> angles,
  ) => _api.patch<void>(
    ApiEndpoints.productPhotoAngles(productId),
    data: {
      'angles': {
        for (final entry in angles.entries) '${entry.key}': entry.value,
      },
    },
    decoder: (_) {},
  );

  @override
  Future<Result<List<LookAtlasModelDto>>> fetchModels() =>
      _api.get<List<LookAtlasModelDto>>(
        ApiEndpoints.lookAtlasModels,
        decoder: (data) => [
          for (final item in _map(data)['models'] as List? ?? const [])
            if (item is Map<String, dynamic>)
              LookAtlasModelDto.fromJson(
                item,
                baseUrl: AppConfig.apiBaseUrl,
              ),
        ],
      );

  @override
  Future<Result<List<OnboardingUserModelDto>>> fetchUserModels() =>
      _api.get<List<OnboardingUserModelDto>>(
        ApiEndpoints.userModels,
        decoder: (data) {
          final items = data is List ? data : _map(data)['models'] as List?;
          return [
            for (final item in items ?? const [])
              if (item is Map<String, dynamic>)
                OnboardingUserModelDto.fromJson(
                  item,
                  baseUrl: AppConfig.apiBaseUrl,
                ),
          ];
        },
      );

  @override
  Future<Result<String>> createUserModel(UserModelDraft draft) =>
      _api.post<String>(
        ApiEndpoints.userModels,
        data: _userModelFormData(draft),
        decoder: _requiredId,
      );

  @override
  Future<Result<StartShootResponseModel>> startShoot(
    StartShootRequest request,
  ) => _api.post<StartShootResponseModel>(
    ApiEndpoints.onboardingStartShoot,
    data: {
      'productId': request.productId,
      'modelId': request.modelId,
      'modelSource': request.modelSource.name,
      'settings': {
        'useCase': request.settings.useCase,
        'directorId': request.settings.directorId,
        'background': request.settings.background,
        'aspectRatio': request.settings.aspectRatio,
      },
      'deviceFingerprint': ?request.deviceFingerprint,
      'deviceToken': ?request.deviceToken,
      'uaFamily': ?request.uaFamily,
      'screenHash': ?request.screenHash,
      'tzOffset': ?request.tzOffset,
    },
    decoder: (data) => StartShootResponseModel.fromJson(_map(data)),
  );

  static FormData _productFormData(ProductDraft draft) {
    final data = FormData();
    data.fields
      ..add(MapEntry('name', draft.name))
      ..add(MapEntry('sku', draft.sku))
      ..add(
        MapEntry(
          'photo_keys',
          jsonEncode([for (final upload in draft.photos) _photoKey(upload)]),
        ),
      );
    if (draft.category.trim().isNotEmpty) {
      data.fields.add(MapEntry('category', draft.category.trim()));
    }
    if (draft.description.trim().isNotEmpty) {
      data.fields.add(MapEntry('description', draft.description.trim()));
    }
    if (draft.subCategory.trim().isNotEmpty) {
      data.fields.add(MapEntry('sub_category', draft.subCategory.trim()));
    }
    if (draft.viewAngles.isNotEmpty) {
      data.fields.add(MapEntry('view_angles', jsonEncode(draft.viewAngles)));
    }
    _addUploads(data, draft.photos);
    return data;
  }

  static FormData _userModelFormData(UserModelDraft draft) {
    final data = FormData();
    data.fields
      ..add(MapEntry('name', draft.name))
      ..add(MapEntry('gender', draft.gender.wireValue))
      ..add(MapEntry('height', draft.height))
      ..add(MapEntry('heightEstimated', '${draft.heightEstimated}'));
    _addUploads(data, draft.photos);
    return data;
  }

  static void _addUploads(FormData data, List<OnboardingUpload> uploads) {
    for (final upload in uploads) {
      data.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(
            upload.bytes,
            filename: upload.fileName,
            contentType: DioMediaType(
              'image',
              upload.fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpeg',
            ),
          ),
        ),
      );
    }
  }

  static String _photoKey(OnboardingUpload upload) {
    var hash = 0xcbf29ce484222325;
    for (final byte in upload.bytes) {
      hash = ((hash ^ byte) * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return '${upload.fileName}:$hash';
  }

  static Map<String, dynamic> _map(dynamic data) =>
      data is Map<String, dynamic> ? data : const {};

  static String _requiredId(dynamic data) {
    final id = _map(data)['id'];
    if (id is String && id.isNotEmpty) return id;
    throw const FormatException('API response did not include an id.');
  }
}
