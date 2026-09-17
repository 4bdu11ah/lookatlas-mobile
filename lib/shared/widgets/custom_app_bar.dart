import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_hairline.dart';
import 'package:look_atlas/shared/widgets/app_icon_button.dart';

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
          ? AppIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onPressed: onBack ?? () => context.pop(),
              size: 17,
              color: AppColors.black,
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
              child: AppHairline(),
            )
          : null,
    );
  }
}
