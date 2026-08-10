part of '../screens/dashboard_screen.dart';

class _SquareIcon extends StatelessWidget {
  const _SquareIcon(this.icon);

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

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: child,
    );
  }
}

class _AssetBox extends StatelessWidget {
  const _AssetBox(this.asset, {required this.height, this.width});

  final String asset;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: _AssetImage(asset),
    );
  }
}

class _AssetImage extends StatelessWidget {
  const _AssetImage(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    if (asset.isEmpty) {
      return const ColoredBox(color: AppColors.neutral200);
    }
    return AppImage(
      asset,
      fit: BoxFit.cover,
      errorWidget: const ColoredBox(color: AppColors.neutral200),
    );
  }
}
