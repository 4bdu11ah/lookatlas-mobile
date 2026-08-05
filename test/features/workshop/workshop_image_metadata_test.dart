import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/workshop/domain/workshop_image_metadata.dart';

void main() {
  test('workshopImageFileName_pngBytes_usesPngExtension', () {
    final bytes = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
    ]);

    final fileName = workshopImageFileName(
      bytes,
      prefix: 'look-atlas',
      generationId: 'generation-1',
    );

    expect(fileName, 'look-atlas-generation-1.png');
  });

  test('workshopImageFileName_webpBytes_usesWebpExtension', () {
    final bytes = Uint8List.fromList([
      0x52,
      0x49,
      0x46,
      0x46,
      0,
      0,
      0,
      0,
      0x57,
      0x45,
      0x42,
      0x50,
    ]);

    final fileName = workshopImageFileName(
      bytes,
      prefix: 'workshop',
      generationId: 'generation-2',
    );

    expect(fileName, 'workshop-generation-2.webp');
  });

  test('workshopImageFileName_unknownBytes_defaultsToJpegExtension', () {
    final fileName = workshopImageFileName(
      Uint8List.fromList([1, 2, 3]),
      prefix: 'look-atlas',
      generationId: 'generation-3',
    );

    expect(fileName, 'look-atlas-generation-3.jpg');
  });
}
