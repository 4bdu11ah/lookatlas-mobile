import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/network/dio_client.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';

abstract interface class WorkshopRemoteDataSource {
  Future<Result<WorkshopGeneration?>> getActive();
  Future<Result<List<WorkshopGeneration>>> getGenerations();
  Future<Result<WorkshopGeneration>> generate(
    WorkshopGenerateRequest request,
  );
  Future<Result<WorkshopGeneration>> getGeneration(String generationId);
  Future<Result<void>> deleteGeneration(String generationId);
  Future<Result<Uint8List>> downloadImage(String imageUrl);
}

class WorkshopRemoteDataSourceImpl implements WorkshopRemoteDataSource {
  const WorkshopRemoteDataSourceImpl({
    required this._api,
    required this._publicApi,
  });

  final ApiService _api;
  final ApiService _publicApi;

  @override
  Future<Result<WorkshopGeneration?>> getActive() async {
    final result = await _api.get<WorkshopGeneration?>(
      ApiEndpoints.workshopActive,
      decoder: _decodeOptionalGeneration,
    );
    if (result case Err(:final failure)) {
      if (failure is NetworkFailure && failure.statusCode == 404) {
        return const Ok(null);
      }
    }
    return result;
  }

  @override
  Future<Result<List<WorkshopGeneration>>> getGenerations() =>
      _api.get<List<WorkshopGeneration>>(
        ApiEndpoints.workshopGenerations,
        decoder: _decodeGenerations,
      );

  @override
  Future<Result<WorkshopGeneration>> generate(
    WorkshopGenerateRequest request,
  ) async {
    final result = await _api.post<WorkshopGeneration>(
      ApiEndpoints.workshopGenerate,
      data: _generateFormData(request),
      decoder: _decodeGeneration,
    );
    if (result case Err(:final failure)) {
      final activeJobId = _activeJobId(failure);
      if (activeJobId != null) return getGeneration(activeJobId);
    }
    return result;
  }

  @override
  Future<Result<WorkshopGeneration>> getGeneration(String generationId) =>
      _api.get<WorkshopGeneration>(
        ApiEndpoints.workshopGeneration(generationId),
        decoder: _decodeGeneration,
      );

  @override
  Future<Result<void>> deleteGeneration(String generationId) =>
      _api.delete<void>(
        ApiEndpoints.workshopGeneration(generationId),
        decoder: (_) {},
      );

  @override
  Future<Result<Uint8List>> downloadImage(String imageUrl) async {
    try {
      final response = await _publicApi.raw.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? const []);
      return bytes.isEmpty
          ? const Err(UnknownFailure('The downloaded image was empty.'))
          : Ok(bytes);
    } on DioException catch (error) {
      return Err(mapDioError(error));
    } on Object catch (error, stack) {
      return Err(
        UnknownFailure(
          'Could not download this image.',
          cause: error,
          stackTrace: stack,
        ),
      );
    }
  }

  static FormData _generateFormData(WorkshopGenerateRequest request) {
    final form = FormData();
    form.fields
      ..add(MapEntry('prompt', request.prompt))
      ..add(MapEntry('mode', request.mode.apiValue));
    form.files.add(
      MapEntry(
        'base',
        MultipartFile.fromBytes(
          request.base.bytes,
          filename: request.base.fileName,
          contentType: _imageMediaType(request.base.fileName),
        ),
      ),
    );
    for (final reference in request.references) {
      form.files.add(
        MapEntry(
          'refs',
          MultipartFile.fromBytes(
            reference.bytes,
            filename: reference.fileName,
            contentType: _imageMediaType(reference.fileName),
          ),
        ),
      );
    }
    return form;
  }

  static WorkshopGeneration? _decodeOptionalGeneration(dynamic data) {
    if (data == null) return null;
    final root = _map(data);
    if (root['active'] == false ||
        root.containsKey('activeGeneration') &&
            root['activeGeneration'] == null) {
      final nested = root['data'];
      if (nested == null || nested is Map && nested['active'] == false) {
        return null;
      }
    }
    final generation = _generationMap(data);
    if (generation == null || _identifier(generation).isEmpty) return null;
    return _decodeGeneration(generation);
  }

  static List<WorkshopGeneration> _decodeGenerations(dynamic data) {
    final values = _items(data);
    return [
      for (final value in values)
        if (value is Map<String, dynamic>) _decodeGeneration(value),
    ];
  }

  static WorkshopGeneration _decodeGeneration(dynamic data) {
    final json = _generationMap(data) ?? const <String, dynamic>{};
    final error = json['error'];
    final errorMap = error is Map<String, dynamic> ? error : null;
    final result = json['result'];
    final resultMap = result is Map<String, dynamic> ? result : null;
    return WorkshopGeneration(
      id: _identifier(json),
      status: WorkshopGenerationStatus.fromApi(
        json['status'] ?? json['state'],
      ),
      prompt: _string(json['prompt']),
      imageUrl: _absoluteUrl(
        _nullableString(
          json['imageUrl'] ??
              json['image_url'] ??
              json['outputUrl'] ??
              json['resultUrl'] ??
              resultMap?['imageUrl'] ??
              resultMap?['url'] ??
              result,
        ),
      ),
      createdAt: _date(json['createdAt'] ?? json['created_at']),
      creditCost: _integer(json['creditCost'] ?? json['credit_cost']),
      errorMessage: _nullableString(
        errorMap?['message'] ?? json['errorMessage'] ?? json['error_message'],
      ),
    );
  }

  static Map<String, dynamic>? _generationMap(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    for (final key in const [
      'generation',
      'activeGeneration',
      'active',
      'job',
      'data',
    ]) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) {
        final deeper = _generationMap(nested);
        return deeper ?? nested;
      }
    }
    return data;
  }

  static List<dynamic> _items(dynamic data) {
    if (data is List) return data;
    if (data is! Map<String, dynamic>) return const [];
    for (final key in const ['generations', 'history', 'items', 'data']) {
      final value = data[key];
      if (value is List) return value;
      if (value is Map<String, dynamic>) {
        final nested = _items(value);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  static String? _activeJobId(Failure failure) {
    if (failure is! NetworkFailure || failure.statusCode != 409) return null;
    final cause = failure.cause;
    if (cause is! DioException) return null;
    final response = cause.response?.data;
    if (response is! Map<String, dynamic>) return null;
    final error = response['error'];
    final details = error is Map<String, dynamic> ? error['details'] : null;
    final candidates = [
      response['activeJobId'],
      if (error is Map<String, dynamic>) error['activeJobId'],
      if (details is Map<String, dynamic>) details['activeJobId'],
    ];
    return candidates.map(_nullableString).nonNulls.firstOrNull;
  }

  static String _identifier(Map<String, dynamic> json) =>
      _string(json['id'] ?? json['_id'] ?? json['generationId']);

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static String _string(Object? value) => value?.toString() ?? '';

  static String? _nullableString(Object? value) {
    final string = value?.toString().trim();
    return string == null || string.isEmpty ? null : string;
  }

  static int? _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static DateTime? _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '');

  static String? _absoluteUrl(String? value) {
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme ?? false) return value;
    return Uri.parse(AppConfig.apiBaseUrl).resolve(value).toString();
  }

  static DioMediaType _imageMediaType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return DioMediaType.parse('image/png');
    if (lower.endsWith('.webp')) return DioMediaType.parse('image/webp');
    return DioMediaType.parse('image/jpeg');
  }
}
