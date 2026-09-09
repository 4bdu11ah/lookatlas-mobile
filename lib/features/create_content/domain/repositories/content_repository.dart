import 'dart:typed_data';

import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_archive.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';

abstract interface class ContentRepository {
  Future<List<ContentDraft>> drafts({RequestCancellation? cancellation});
  Future<List<ContentGeneration>> history({RequestCancellation? cancellation});
  Future<ContentDraft?> latest(
    ContentFormat format, {
    RequestCancellation? cancellation,
  });
  Future<ContentGeneration?> active({RequestCancellation? cancellation});
  Future<ContentDraft> save(
    ContentFormat format,
    String? draftId,
    ContentJson patch,
  );
  Future<void> deleteDraft(
    String draftId, {
    RequestCancellation? cancellation,
  });
  Future<ContentQuote> quote(
    ContentFormat format,
    ContentJson settings, {
    RequestCancellation? cancellation,
  });
  Future<ContentJson> start(String draftId);
  Future<ContentGeneration> generation(
    String generationId, {
    RequestCancellation? cancellation,
  });
  Future<ContentJson> retry(String generationId);
  Future<ContentFrame> frame(
    String generationId,
    String frameId,
    ContentJson patch,
  );
  Future<ContentJson> edit(
    String generationId,
    String frameId, {
    String? prompt,
  });
  Future<ContentJson> editStatus(
    String editJobId, {
    RequestCancellation? cancellation,
  });
  Future<ContentJson> publishing(
    String generationId,
    ContentJson patch, {
    RequestCancellation? cancellation,
  });
  Future<ContentExportTicket> export(
    String generationId, {
    RequestCancellation? cancellation,
  });
  Future<ContentJson> upload(Uint8List bytes, String fileName);
  Future<List<ProductCatalogItem>> products({
    String? search,
    RequestCancellation? cancellation,
  });
  Future<bool> isVideoEligible({RequestCancellation? cancellation});
}
