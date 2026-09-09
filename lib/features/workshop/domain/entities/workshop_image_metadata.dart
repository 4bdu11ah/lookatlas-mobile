import 'dart:typed_data';

import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';

WorkshopImageOrientation? readWorkshopImageOrientation(Uint8List bytes) {
  final dimensions = _readPngDimensions(bytes) ?? _readJpegDimensions(bytes);
  return dimensions == null
      ? null
      : WorkshopImageOrientation.fromDimensions(
          dimensions.width,
          dimensions.height,
        );
}

String workshopImageFileName(
  Uint8List bytes, {
  required String prefix,
  required String generationId,
}) {
  final extension = _isPng(bytes)
      ? 'png'
      : _isWebp(bytes)
      ? 'webp'
      : 'jpg';
  return '$prefix-$generationId.$extension';
}

bool _isPng(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x89 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x4E &&
    bytes[3] == 0x47;

bool _isWebp(Uint8List bytes) =>
    bytes.length >= 12 &&
    bytes[0] == 0x52 &&
    bytes[1] == 0x49 &&
    bytes[2] == 0x46 &&
    bytes[3] == 0x46 &&
    bytes[8] == 0x57 &&
    bytes[9] == 0x45 &&
    bytes[10] == 0x42 &&
    bytes[11] == 0x50;

({int width, int height})? _readPngDimensions(Uint8List bytes) {
  if (bytes.length < 24 || !_isPng(bytes)) {
    return null;
  }
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  return width == 0 || height == 0 ? null : (width: width, height: height);
}

({int width, int height})? _readJpegDimensions(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  var offset = 2;
  while (offset + 8 < bytes.length) {
    while (offset < bytes.length && bytes[offset] == 0xFF) {
      offset++;
    }
    if (offset >= bytes.length) return null;
    final marker = bytes[offset++];
    if (marker == 0xD9 || marker == 0xDA || offset + 1 >= bytes.length) {
      return null;
    }
    final segmentLength = (bytes[offset] << 8) | bytes[offset + 1];
    if (segmentLength < 2 || offset + segmentLength > bytes.length) return null;
    if (_isJpegStartOfFrame(marker)) {
      if (segmentLength < 7) return null;
      final height = (bytes[offset + 3] << 8) | bytes[offset + 4];
      final width = (bytes[offset + 5] << 8) | bytes[offset + 6];
      return width == 0 || height == 0 ? null : (width: width, height: height);
    }
    offset += segmentLength;
  }
  return null;
}

bool _isJpegStartOfFrame(int marker) {
  return switch (marker) {
    0xC0 ||
    0xC1 ||
    0xC2 ||
    0xC3 ||
    0xC5 ||
    0xC6 ||
    0xC7 ||
    0xC9 ||
    0xCA ||
    0xCB ||
    0xCD ||
    0xCE ||
    0xCF => true,
    _ => false,
  };
}
