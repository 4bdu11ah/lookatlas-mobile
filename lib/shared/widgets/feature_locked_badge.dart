import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FeatureLockedBadge extends StatelessWidget {
  const FeatureLockedBadge({this.label = 'Locked', super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label feature',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppColors.neutral100,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.lock, size: 12, color: AppColors.neutral500),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
        ],
      ),
    ),
  );
}
