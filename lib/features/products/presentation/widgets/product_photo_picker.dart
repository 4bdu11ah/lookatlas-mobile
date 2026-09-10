import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';

Future<ProductUpload?> pickProductPhoto(
  BuildContext context,
  WidgetRef ref, {
  required String title,
}) async {
  final photos = await pickProductPhotos(
    context,
    ref,
    remaining: 1,
    title: title,
  );
  return photos.firstOrNull;
}

Future<List<ProductUpload>> pickProductPhotos(
  BuildContext context,
  WidgetRef ref, {
  required int remaining,
  required String title,
}) async {
  if (remaining <= 0) {
    AppSnackBar.show(
      context,
      'You can upload up to $PRODUCT_PHOTO_UPLOAD_MAX_COUNT photos.',
    );
    return const [];
  }
  final source = await showImageSourceSheet(context, title: title);
  if (source == null || !context.mounted) return const [];
  try {
    final picker = ref.read(imagePickerProvider);
    final files = source == ImageSource.camera || remaining == 1
        ? [
            ?await picker.pickImage(
              source: source,
              maxWidth: 1600,
              imageQuality: 85,
            ),
          ]
        : await picker.pickMultiImage(
            maxWidth: 1600,
            imageQuality: 85,
            limit: remaining,
          );
    final uploads = <ProductUpload>[];
    for (final file in files.take(remaining)) {
      final extension = file.name.split('.').last.toLowerCase();
      if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            '${file.name} must be a JPG, PNG, or WebP image.',
          );
        }
        continue;
      }
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > PRODUCT_PHOTO_UPLOAD_MAX_BYTES) {
        if (context.mounted) {
          AppSnackBar.showError(context, '${file.name} is larger than 20MB.');
        }
        continue;
      }
      uploads.add(
        ProductUpload(
          bytes: bytes,
          fileName: file.name,
          path: file.path,
          localKey:
              '${DateTime.now().microsecondsSinceEpoch}-${uploads.length}-${file.name}',
        ),
      );
    }
    return uploads;
  } on Exception {
    if (context.mounted) {
      AppSnackBar.showError(
        context,
        'Could not open your camera or photo library.',
      );
    }
    return const [];
  }
}
