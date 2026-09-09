import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/shared/widgets/app_asset_image.dart';

class AppSquareIcon extends StatelessWidget {
  const AppSquareIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      color: AppColors.black,
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: AppColors.white),
    );
  }
}

class AppAssetBox extends StatelessWidget {
  const AppAssetBox(this.asset, {required this.height, super.key, this.width});

  final String asset;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: AppAssetImage(asset),
    );
  }
}
