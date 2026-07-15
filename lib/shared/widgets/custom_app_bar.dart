import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    required this.title,
    super.key,
    this.showBackButton = false,
    this.onBack,
    this.actions = const [],
    this.showBottomLine = true,
    this.height = 44,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool showBottomLine;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      // leadingWidth: showBackButton ? 60 : 20,
      leading: showBackButton
          ? _CustomAppBarIconButton(
              icon: Icons.arrow_back,
              label: 'Back',
              onTap: onBack ?? () => Navigator.maybePop(context),
            )
          : const SizedBox.shrink(),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            height: 1.2,
            fontWeight: AppTypography.bold,
            color: AppColors.black,
          ),
        ),
      ),
      actions: actions.isEmpty
          ? const [SizedBox(width: 20)]
          : [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: actions),
              ),
            ],
      bottom: showBottomLine
          ? const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.neutral200),
            )
          : null,
    );
  }
}

class _CustomAppBarIconButton extends StatelessWidget {
  const _CustomAppBarIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 17,
          color: AppColors.black,
        ),
      ),
    );
  }
}
