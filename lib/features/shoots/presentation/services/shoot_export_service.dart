import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShootExportService {
  const ShootExportService();

  Future<Failure?> exportApprovedImages({
    required ShootJob job,
    required Future<Result<Uint8List>> Function(ShootImage image) download,
  }) async {
    final images = job.shots.isEmpty
        ? job.images
        : [for (final shot in job.shots) ...shot.images];
    final approvedImages = images.where((image) => image.approved).toList();
    if (approvedImages.isEmpty) {
      return const UnknownFailure(
        'Approve at least one image before exporting.',
      );
    }

    try {
      final folderName = _safeName(job.name);
      final archive = Archive();
      for (final image in approvedImages) {
        final result = await download(image);
        final bytes = result.valueOrNull;
        if (bytes == null || bytes.isEmpty) continue;
        final fileName =
            'shot_${image.shotIndex + 1}_variation_'
            '${image.variationIndex + 1}_${image.id}.${_extension(image.url)}';
        archive.addFile(
          ArchiveFile('$folderName/$fileName', bytes.length, bytes),
        );
      }

      final csv = buildCsv(job, approvedImages);
      final csvBytes = Uint8List.fromList(utf8.encode(csv));
      archive.addFile(
        ArchiveFile('$folderName/export.csv', csvBytes.length, csvBytes),
      );
      final archiveBytes = ZipEncoder().encodeBytes(archive);
      final cacheDirectory = await getTemporaryDirectory();
      final output = File('${cacheDirectory.path}/$folderName-export.zip');
      await output.writeAsBytes(archiveBytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(output.path, mimeType: 'application/zip')],
          fileNameOverrides: ['$folderName-export.zip'],
          text: 'LOOK ATLAS export for ${job.name}',
        ),
      );
      return null;
    } on Object catch (error, stackTrace) {
      return UnknownFailure(
        'Could not create this export.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  String buildCsv(ShootJob job, List<ShootImage> images) {
    final rows = <List<String>>[
      const [
        'sku',
        'model',
        'preset',
        'shot',
        'aspect_ratio',
        'variation',
        'url',
      ],
      for (final image in images)
        [
          job.productSku ?? '',
          job.modelName ?? '',
          job.preset ?? '',
          '${image.shotIndex + 1}',
          job.aspectRatio ?? '',
          '${image.variationIndex + 1}',
          image.url,
        ],
    ];
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
  }

  String _escapeCsv(String value) => '"${value.replaceAll('"', '""')}"';

  String _safeName(String value) {
    final normalized = value.toLowerCase().replaceAll(
      RegExp('[^a-z0-9]+'),
      '-',
    );
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '').isEmpty
        ? 'look-atlas-export'
        : normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _extension(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final match = RegExp(r'\.([A-Za-z0-9]{2,5})$').firstMatch(path);
    return match?.group(1)?.toLowerCase() ?? 'jpg';
  }
}
