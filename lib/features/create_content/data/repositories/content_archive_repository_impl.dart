import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/dio_cancellation.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_archive.dart';
import 'package:look_atlas/features/create_content/domain/repositories/content_repository.dart';

class ContentArchiveRepositoryImpl {
  const ContentArchiveRepositoryImpl(this._contentRepository);

  final ContentRepository _contentRepository;

  Future<ContentArchive> download(
    String generationId, {
    RequestCancellation? cancellation,
    void Function(int, int)? onProgress,
  }) async {
    final ticket = await _contentRepository.export(
      generationId,
      cancellation: cancellation,
    );
    final binding = DioCancellation(cancellation);
    final client = Dio();
    try {
      final response = await client.get<List<int>>(
        ticket.url.toString(),
        cancelToken: binding.token,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress,
      );
      final bytes = Uint8List.fromList(response.data ?? []);
      if (bytes.isEmpty) throw const FormatException('Empty archive');
      return ContentArchive(bytes: bytes, name: ticket.fileName);
    } finally {
      binding.dispose();
      client.close();
    }
  }
}
