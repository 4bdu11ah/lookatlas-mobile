import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_bottom_sheet.dart';

export 'package:image_picker/image_picker.dart' show ImageSource;

/// Shows the app's image-source chooser: a branded bottom sheet with
/// "Take a photo" and "Choose from gallery". Returns the picked
/// [ImageSource], or null when dismissed.
///
/// Use this everywhere the app needs an image, so picking feels the same on
/// every screen:
///
/// ```dart
/// final source = await showImageSourceSheet(context);
/// if (source == null) return;
/// await ref.read(someControllerProvider.notifier).addPhotosFrom(source);
/// ```
Future<ImageSource?> showImageSourceSheet(
  BuildContext context, {
  String title = 'Add a photo',
}) {
  final scheme = Theme.of(context).colorScheme;
  return showAppBottomSheet<ImageSource>(
    context,
    backgroundColor: scheme.surface,
    builder: (context) => _ImageSourceSheet(title: title),
  );
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: AppTypography.bold,
                color: scheme.onSurface,
              ),
            ),
          ),
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            label: 'Take a photo',
            subtitle: 'Use your camera',
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          Divider(height: 1, color: scheme.outline),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            subtitle: 'Pick from your photos',
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          Divider(height: 1, color: scheme.outline),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Cancel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: AppTypography.medium,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          spacing: 14,
          children: [
            Container(
              width: 40,
              height: 40,
              color: scheme.onSurface,
              child: Icon(icon, size: 20, color: scheme.surface),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.43,
                      fontWeight: AppTypography.semiBold,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.33,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
