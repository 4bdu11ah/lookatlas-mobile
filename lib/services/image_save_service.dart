import 'package:flutter/services.dart';

class ImageSaveService {
  const ImageSaveService({
    this._channel = const MethodChannel('com.lookatlas/image_save'),
  });

  final MethodChannel _channel;

  Future<void> save(Uint8List bytes, {required String fileName}) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'Image cannot be empty.');
    }
    final safeName = _safeFileName(fileName);
    await _channel.invokeMethod<void>('save', {
      'bytes': bytes,
      'fileName': safeName,
      'mimeType': _mimeType(safeName),
    });
  }

  String _safeFileName(String value) {
    final sanitized = value
        .replaceAll(RegExp('[^a-zA-Z0-9._-]'), '-')
        .replaceAll(RegExp('-+'), '-');
    return sanitized.isEmpty ? 'look-atlas-image.jpg' : sanitized;
  }

  String _mimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
