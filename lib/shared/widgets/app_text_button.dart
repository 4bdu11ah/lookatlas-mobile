import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

/// App-wide bordered text action with a leading icon.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.fitToContent = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool fitToContent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buttonLabel = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: AppTypography.bold,
        color: scheme.onSurface,
      ),
    );
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: fitToContent ? null : double.infinity,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          mainAxisSize: fitToContent ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(icon, size: 17, color: scheme.onSurface),
            const SizedBox(width: 7),
            if (fitToContent)
              buttonLabel
            else
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: buttonLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
