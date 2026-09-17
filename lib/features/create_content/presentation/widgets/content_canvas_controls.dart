import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/create_content/presentation/widgets/content_widgets.dart';
import 'package:look_atlas/shared/widgets/app_icon_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ContentCanvasControls extends StatelessWidget {
  const ContentCanvasControls({
    required this.zoom,
    required this.onZoomOut,
    required this.onFit,
    required this.onZoomIn,
    super.key,
  });

  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          child: AppIconButton(
            icon: LucideIcons.minus,
            tooltip: 'Zoom out',
            color: AppColors.muted,
            size: 16,
            onPressed: onZoomOut,
          ),
        ),
        Text(
          '${(zoom * 100).round()}%',
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            fontWeight: AppTypography.bold,
          ),
        ),
        SizedBox(
          width: 40,
          child: AppIconButton(
            icon: LucideIcons.plus,
            tooltip: 'Zoom in',
            color: AppColors.muted,
            size: 16,
            onPressed: onZoomIn,
          ),
        ),
        contentSmallTextButton('Fit', onFit),
      ],
    );
  }
}

class ContentCanvasBar extends StatelessWidget {
  const ContentCanvasBar({
    required this.statusLabel,
    required this.zoom,
    required this.onZoomOut,
    required this.onFit,
    required this.onZoomIn,
    this.statusBackgroundColor = AppColors.soft,
    super.key,
  });

  final String statusLabel;
  final Color statusBackgroundColor;
  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBackgroundColor,
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ContentCanvasControls(
            zoom: zoom,
            onZoomOut: onZoomOut,
            onFit: onFit,
            onZoomIn: onZoomIn,
          ),
        ],
      ),
    );
  }
}
