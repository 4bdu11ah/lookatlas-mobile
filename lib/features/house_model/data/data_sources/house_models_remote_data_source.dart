import 'package:dio/dio.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';

abstract interface class HouseModelsRemoteDataSource {
  Future<Result<List<HouseModelProfile>>> getUserModels();

  Future<Result<List<HouseModelProfile>>> getLibraryModels();

  Future<Result<void>> createModel(HouseModelDraft draft);

  Future<Result<void>> updateModel(String modelId, HouseModelDraft draft);

  Future<Result<void>> patchModel(String modelId, HouseModelDraft draft);

  Future<Result<void>> deleteModel(String modelId);

  Future<Result<void>> deletePhoto(String modelId, String photoId);

  Future<Result<HouseModelGeneration>> generateModel(AiHouseModelDraft draft);

  Future<Result<HouseModelGeneration>> getGeneration(String generationId);
}

class HouseModelsRemoteDataSourceImpl implements HouseModelsRemoteDataSource {
  const HouseModelsRemoteDataSourceImpl({required this._api});

  final ApiService _api;

  @override
  Future<Result<List<HouseModelProfile>>> getUserModels() =>
      _api.get<List<HouseModelProfile>>(
        ApiEndpoints.userModels,
        decoder: (data) => _decodeModels(data, HouseModelSource.user),
      );

  @override
  Future<Result<List<HouseModelProfile>>> getLibraryModels() =>
      _api.get<List<HouseModelProfile>>(
        ApiEndpoints.lookAtlasModels,
        decoder: (data) => _decodeModels(data, HouseModelSource.lookAtlas),
      );

  @override
  Future<Result<void>> createModel(HouseModelDraft draft) => _api.post<void>(
    ApiEndpoints.userModels,
    data: _formData(draft),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> updateModel(
    String modelId,
    HouseModelDraft draft,
  ) => _api.put<void>(
    ApiEndpoints.userModel(modelId),
    data: _formData(draft),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> patchModel(
    String modelId,
    HouseModelDraft draft,
  ) => _api.patch<void>(
    ApiEndpoints.userModel(modelId),
    data: {
      'name': draft.name,
      'gender': draft.gender,
      'height': '${draft.heightCm}cm',
      'heightEstimated': draft.heightEstimated,
    },
    decoder: (_) {},
  );

  @override
  Future<Result<void>> deleteModel(String modelId) => _api.delete<void>(
    ApiEndpoints.userModel(modelId),
    decoder: (_) {},
  );

  @override
  Future<Result<void>> deletePhoto(String modelId, String photoId) =>
      _api.delete<void>(
        ApiEndpoints.userModelPhoto(modelId, photoId),
        decoder: (_) {},
      );

  @override
  Future<Result<HouseModelGeneration>> generateModel(
    AiHouseModelDraft draft,
  ) => _api.post<HouseModelGeneration>(
    ApiEndpoints.generateModel,
    data: _generationPayload(draft),
    decoder: _decodeGeneration,
  );

  static Map<String, dynamic> _generationPayload(AiHouseModelDraft draft) {
    final payload = <String, dynamic>{
      'gender': draft.gender,
      'age': draft.age,
      'description': draft.description,
    };
    final name = draft.name;
    if (name != null) payload['name'] = name;
    return payload;
  }

  @override
  Future<Result<HouseModelGeneration>> getGeneration(String generationId) =>
      _api.get<HouseModelGeneration>(
        ApiEndpoints.modelGeneration(generationId),
        decoder: _decodeGeneration,
      );

  static FormData _formData(HouseModelDraft draft) {
    final data = FormData();
    data.fields
      ..add(MapEntry('name', draft.name))
      ..add(MapEntry('gender', draft.gender))
      ..add(MapEntry('height', '${draft.heightCm}'))
      ..add(MapEntry('heightEstimated', '${draft.heightEstimated}'));
    for (final photo in draft.photos) {
      data.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(
            photo.bytes,
            filename: photo.fileName,
            contentType: _photoMediaType(photo.fileName),
          ),
        ),
      );
    }
    return data;
  }

  static DioMediaType _photoMediaType(String fileName) =>
      fileName.toLowerCase().endsWith('.png')
      ? DioMediaType('image', 'png')
      : DioMediaType('image', 'jpeg');

  static List<HouseModelProfile> _decodeModels(
    dynamic data,
    HouseModelSource source,
  ) => [
    for (final item in _modelItems(data))
      if (item is Map<String, dynamic>) _decodeModel(item, source),
  ];

  static List<dynamic> _modelItems(dynamic data) {
    if (data is List) return data;
    final body = _map(data);
    final models = body['models'];
    if (models is List) return models;
    final nested = body['data'];
    if (nested is List) return nested;
    if (nested is Map<String, dynamic> && nested['models'] is List) {
      return nested['models'] as List;
    }
    return const [];
  }

  static HouseModelProfile _decodeModel(
    Map<String, dynamic> json,
    HouseModelSource source,
  ) {
    final photoEntries =
        json['photoRecords'] as List? ?? json['photos'] as List? ?? const [];
    final photos = <String>[];
    final photoIds = <String?>[];
    for (final photo in photoEntries) {
      final url = _photoUrl(photo);
      if (url == null) continue;
      photos.add(url);
      photoIds.add(_photoId(photo));
    }
    return HouseModelProfile(
      id: _string(json['id'] ?? json['_id']),
      name: _string(json['name'], fallback: 'Model'),
      gender: _string(json['gender'], fallback: 'unspecified'),
      source: source,
      bodyType: _nullableString(json['bodyType'] ?? json['body_type']),
      ethnicity: _nullableString(json['ethnicity']),
      ageRange: _nullableString(json['ageRange'] ?? json['age_range']),
      heightCm: _heightCm(json['heightCm'] ?? json['height']),
      heightEstimated:
          json['heightEstimated'] as bool? ??
          json['height_estimated'] as bool? ??
          false,
      photos: photos,
      photoIds: photoIds,
      coverThumbnail: _absoluteUrl(
        _nullableString(
          json['coverThumbnail'] ??
              json['cover_thumbnail'] ??
              json['thumbnail'],
        ),
      ),
    );
  }

  static HouseModelGeneration _decodeGeneration(dynamic data) {
    final body = _map(data);
    final nested = body['generation'];
    final json = nested is Map<String, dynamic> ? nested : body;
    final id = _string(json['id'] ?? json['generationId']);
    if (id.isEmpty) {
      throw const FormatException(
        'Model generation response did not include an id.',
      );
    }
    return HouseModelGeneration(
      id: id,
      status: _generationStatus(json['status']),
      creditCost: _integer(json['creditCost'] ?? json['credits']),
      message: _nullableString(json['message'] ?? json['error']),
      modelId: _nullableString(json['modelId'] ?? json['model_id']),
    );
  }

  static HouseModelGenerationStatus _generationStatus(Object? raw) =>
      switch (_string(raw).toLowerCase()) {
        'completed' ||
        'complete' ||
        'succeeded' => HouseModelGenerationStatus.completed,
        'failed' || 'error' => HouseModelGenerationStatus.failed,
        'processing' || 'running' => HouseModelGenerationStatus.processing,
        _ => HouseModelGenerationStatus.pending,
      };

  static String? _photoUrl(Object? photo) {
    if (photo is String) return _absoluteUrl(photo);
    if (photo is! Map<String, dynamic>) return null;
    return _absoluteUrl(
      _nullableString(
        photo['url'] ??
            photo['thumbnailUrl'] ??
            photo['thumbnail'] ??
            photo['path'],
      ),
    );
  }

  static String? _photoId(Object? photo) {
    if (photo is! Map<String, dynamic>) return null;
    return _nullableString(
      photo['id'] ?? photo['photoId'] ?? photo['photo_id'],
    );
  }

  static String? _absoluteUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme ?? false) return value;
    return Uri.parse(AppConfig.apiBaseUrl).resolve(value).toString();
  }

  static int? _integer(Object? value) {
    if (value is num) return value.round();
    if (value is! String) return null;
    return int.tryParse(RegExp(r'\d+').firstMatch(value)?.group(0) ?? '');
  }

  static int? _heightCm(Object? value) {
    if (value is num) return value.round();
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    final imperial = RegExp(
      r"(\d+)\s*(?:'|ft|feet)\s*(\d+)?",
    ).firstMatch(normalized);
    if (imperial != null) {
      final feet = int.parse(imperial.group(1)!);
      final inches = int.tryParse(imperial.group(2) ?? '') ?? 0;
      return (feet * 30.48 + inches * 2.54).round();
    }
    return _integer(normalized);
  }

  static String _string(Object? value, {String fallback = ''}) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  static String? _nullableString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static Map<String, dynamic> _map(dynamic data) =>
      data is Map<String, dynamic> ? data : const {};
}
