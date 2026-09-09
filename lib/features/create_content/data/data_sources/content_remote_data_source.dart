import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/network/dio_cancellation.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';

class ContentRemoteDataSource {
  const ContentRemoteDataSource(this._api);

  final ApiService _api;

  String _id(String value) => Uri.encodeComponent(value);

  Future<ContentJson> _request(
    String method,
    String path, {
    Object? data,
    ContentJson? query,
    RequestCancellation? cancellation,
  }) async {
    final binding = DioCancellation(cancellation);
    try {
      final response = await _api.raw.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        cancelToken: binding.token,
        options: Options(
          method: method,
          contentType: data is FormData
              ? 'multipart/form-data'
              : Headers.jsonContentType,
        ),
      );
      return contentObject(response.data);
    } finally {
      binding.dispose();
    }
  }

  Future<ContentJson> drafts({RequestCancellation? cancellation}) => _request(
    'GET',
    '/content/drafts',
    cancellation: cancellation,
  );

  Future<ContentJson> history({RequestCancellation? cancellation}) => _request(
    'GET',
    '/content',
    query: {'status': 'completed'},
    cancellation: cancellation,
  );

  Future<ContentJson> latest(
    ContentFormat format, {
    RequestCancellation? cancellation,
  }) => _request(
    'GET',
    '/content/drafts/latest',
    query: {'format': format.name},
    cancellation: cancellation,
  );

  Future<ContentJson> active({RequestCancellation? cancellation}) => _request(
    'GET',
    '/content/generations/active',
    cancellation: cancellation,
  );

  Future<ContentJson> save(
    ContentFormat format,
    String? draftId,
    ContentJson patch,
  ) => _request(
    draftId == null ? 'POST' : 'PATCH',
    draftId == null ? '/content/drafts' : '/content/drafts/${_id(draftId)}',
    data: {if (draftId == null) 'format': format.name, ...patch},
  );

  Future<void> deleteDraft(
    String draftId, {
    RequestCancellation? cancellation,
  }) async {
    await _request(
      'DELETE',
      '/content/drafts/${_id(draftId)}',
      cancellation: cancellation,
    );
  }

  Future<ContentJson> quote(
    ContentFormat format,
    ContentJson settings, {
    RequestCancellation? cancellation,
  }) => _request(
    'GET',
    '/content/quote',
    query: {
      'format': format.name,
      if (format == ContentFormat.slideshow)
        'frameCount': settings['frameCount'],
      if (format == ContentFormat.video)
        'durationSeconds': settings['durationSeconds'],
    },
    cancellation: cancellation,
  );

  Future<ContentJson> start(String draftId) =>
      _request('POST', '/content/generations', data: {'draftId': draftId});

  Future<ContentJson> generation(
    String generationId, {
    RequestCancellation? cancellation,
  }) => _request(
    'GET',
    '/content/generations/${_id(generationId)}',
    cancellation: cancellation,
  );

  Future<ContentJson> retry(String generationId) => _request(
    'POST',
    '/content/generations/${_id(generationId)}/retry',
    data: <String, dynamic>{},
  );

  Future<ContentJson> frame(
    String generationId,
    String frameId,
    ContentJson patch,
  ) => _request(
    'PATCH',
    '/content/${_id(generationId)}/frames/${_id(frameId)}',
    data: patch,
  );

  Future<ContentJson> edit(
    String generationId,
    String frameId, {
    String? prompt,
  }) => _request(
    'POST',
    '/content/${_id(generationId)}/frames/${_id(frameId)}/${prompt == null ? 'regenerate' : 'retouch'}',
    data: {'prompt': ?prompt},
  );

  Future<ContentJson> editStatus(
    String editJobId, {
    RequestCancellation? cancellation,
  }) => _request(
    'GET',
    '/content/frame-edits/${_id(editJobId)}',
    cancellation: cancellation,
  );

  Future<ContentJson> publishing(
    String generationId,
    ContentJson patch, {
    RequestCancellation? cancellation,
  }) => _request(
    'PATCH',
    '/content/${_id(generationId)}/publishing-kit',
    data: patch,
    cancellation: cancellation,
  );

  Future<ContentJson> export(
    String generationId, {
    RequestCancellation? cancellation,
  }) => _request(
    'POST',
    '/content/${_id(generationId)}/export',
    data: <String, dynamic>{},
    cancellation: cancellation,
  );

  Future<ContentJson> upload(Uint8List bytes, String fileName) => _request(
    'POST',
    '/content/sources',
    data: FormData.fromMap({
      'source': MultipartFile.fromBytes(bytes, filename: fileName),
    }),
  );

  Future<ContentJson> products({
    String? search,
    RequestCancellation? cancellation,
  }) => _request(
    'GET',
    '/products',
    query: {
      'includePhotos': true,
      if (search != null) ...{'page': 1, 'limit': 12, 'search': search.trim()},
    },
    cancellation: cancellation,
  );

  Future<ContentJson> subscription({RequestCancellation? cancellation}) =>
      _request('GET', '/billing/subscription', cancellation: cancellation);
}
