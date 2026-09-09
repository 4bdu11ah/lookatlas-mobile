import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/create_content/data/data_sources/content_remote_data_source.dart';
import 'package:look_atlas/features/create_content/data/models/content_response_models.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_archive.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/errors/content_api_exception.dart';
import 'package:look_atlas/features/create_content/domain/repositories/content_repository.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';

class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl(ApiService api)
    : _remote = ContentRemoteDataSource(api);

  final ContentRemoteDataSource _remote;

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      final body = error.response?.data;
      final detail = body is Map ? body['error'] : null;
      final status = error.response?.statusCode;
      throw ContentApiException(
        switch (status) {
          401 => 'Your session expired. Please sign in again.',
          402 => 'You need more credits for this action.',
          403 => 'Your plan does not include this feature.',
          409 => 'Another generation is already running.',
          _ => 'Could not complete the request. Check your connection and try again.',
        },
        status: status,
        code: detail is Map ? detail['code'] as String? : null,
        activeJobId: detail is Map ? detail['activeJobId'] as String? : null,
        cancelled: CancelToken.isCancel(error),
      );
    } on FormatException {
      throw const ContentApiException(
        'The server returned an invalid or empty response.',
      );
    }
  }

  @override
  Future<List<ContentDraft>> drafts({RequestCancellation? cancellation}) =>
      _guard(() async {
        final json = await _remote.drafts(cancellation: cancellation);
        return (json['drafts'] as List)
            .map((value) => ContentDraftModel.fromJson(value).toEntity())
            .toList();
      });

  @override
  Future<List<ContentGeneration>> history({
    RequestCancellation? cancellation,
  }) => _guard(() async {
    final json = await _remote.history(cancellation: cancellation);
    return (json['items'] as List)
        .map((value) => ContentGenerationModel.fromJson(value).toEntity())
        .take(8)
        .toList();
  });

  @override
  Future<ContentDraft?> latest(
    ContentFormat format, {
    RequestCancellation? cancellation,
  }) => _guard(() async {
    final json = await _remote.latest(format, cancellation: cancellation);
    return json['draft'] == null
        ? null
        : ContentDraftModel.fromJson(json['draft']).toEntity();
  });

  @override
  Future<ContentGeneration?> active({RequestCancellation? cancellation}) =>
      _guard(() async {
        final json = await _remote.active(cancellation: cancellation);
        return json['active'] == null
            ? null
            : ContentGenerationModel.fromJson(json['active']).toEntity();
      });

  @override
  Future<ContentDraft> save(
    ContentFormat format,
    String? draftId,
    ContentJson patch,
  ) => _guard(() async {
    final json = await _remote.save(format, draftId, patch);
    return ContentDraftModel.fromJson(json['draft']).toEntity();
  });

  @override
  Future<void> deleteDraft(
    String draftId, {
    RequestCancellation? cancellation,
  }) => _guard(() => _remote.deleteDraft(draftId, cancellation: cancellation));

  @override
  Future<ContentQuote> quote(
    ContentFormat format,
    ContentJson settings, {
    RequestCancellation? cancellation,
  }) => _guard(
    () async => ContentQuoteModel.fromJson(
      await _remote.quote(format, settings, cancellation: cancellation),
    ).toEntity(),
  );

  @override
  Future<ContentJson> start(String draftId) =>
      _guard(() => _remote.start(draftId));

  @override
  Future<ContentGeneration> generation(
    String generationId, {
    RequestCancellation? cancellation,
  }) => _guard(
    () async => ContentGenerationModel.fromJson(
      await _remote.generation(generationId, cancellation: cancellation),
    ).toEntity(),
  );

  @override
  Future<ContentJson> retry(String generationId) =>
      _guard(() => _remote.retry(generationId));

  @override
  Future<ContentFrame> frame(
    String generationId,
    String frameId,
    ContentJson patch,
  ) => _guard(() async {
    final json = await _remote.frame(generationId, frameId, patch);
    return ContentFrameModel.fromJson(json['frame']).toEntity();
  });

  @override
  Future<ContentJson> edit(
    String generationId,
    String frameId, {
    String? prompt,
  }) => _guard(() => _remote.edit(generationId, frameId, prompt: prompt));

  @override
  Future<ContentJson> editStatus(
    String editJobId, {
    RequestCancellation? cancellation,
  }) => _guard(() => _remote.editStatus(editJobId, cancellation: cancellation));

  @override
  Future<ContentJson> publishing(
    String generationId,
    ContentJson patch, {
    RequestCancellation? cancellation,
  }) => _guard(
    () => _remote.publishing(generationId, patch, cancellation: cancellation),
  );

  @override
  Future<ContentExportTicket> export(
    String generationId, {
    RequestCancellation? cancellation,
  }) => _guard(() async {
    final json = await _remote.export(generationId, cancellation: cancellation);
    return ContentExportTicketModel.fromJson(json).toEntity();
  });

  @override
  Future<ContentJson> upload(Uint8List bytes, String fileName) =>
      _guard(() => _remote.upload(bytes, fileName));

  @override
  Future<List<ProductCatalogItem>> products({
    String? search,
    RequestCancellation? cancellation,
  }) => _guard(() async {
    final json = await _remote.products(
      search: search,
      cancellation: cancellation,
    );
    return (json['products'] as List)
        .map((value) => ContentProductModel.fromJson(value).toEntity())
        .toList();
  });

  @override
  Future<bool> isVideoEligible({RequestCancellation? cancellation}) =>
      _guard(() async {
        final json = await _remote.subscription(cancellation: cancellation);
        return const {'pro', 'enterprise', 'business'}.contains(json['plan']);
      });
}
