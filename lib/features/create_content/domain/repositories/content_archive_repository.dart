import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_archive.dart';

typedef ContentArchiveDownload = Future<ContentArchive> Function(
  String generationId, {
  RequestCancellation? cancellation,
  void Function(int, int)? onProgress,
});
