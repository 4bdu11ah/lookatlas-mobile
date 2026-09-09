import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';

class AppAssetImage extends StatelessWidget {
  const AppAssetImage(this.asset, {this.fit = BoxFit.cover, super.key});

  final String asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (asset.isEmpty) {
      return const ColoredBox(color: AppColors.neutral200);
    }
    return AppImage(
      asset,
      fit: fit,
      errorWidget: const ColoredBox(color: AppColors.neutral200),
    );
  }
}
