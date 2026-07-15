import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

class AppDialogConfig {
  const AppDialogConfig({
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 18,
    ),
    this.maxWidth = 358,
    this.maxHeightOffset = 36,
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.neutral200,
    this.borderRadius = BorderRadius.zero,
    this.barrierColor = AppColors.blackAlpha60,
    this.shadowColor = AppColors.blackAlpha25,
    this.shadowBlurRadius = 80,
    this.shadowOffset = const Offset(0, 24),
  });

  static const AppDialogConfig standard = AppDialogConfig();

  final EdgeInsets insetPadding;
  final double maxWidth;
  final double maxHeightOffset;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final Color barrierColor;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  AppDialogConfig copyWith({
    EdgeInsets? insetPadding,
    double? maxWidth,
    double? maxHeightOffset,
    Color? backgroundColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    Color? barrierColor,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
  }) {
    return AppDialogConfig(
      insetPadding: insetPadding ?? this.insetPadding,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeightOffset: maxHeightOffset ?? this.maxHeightOffset,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      barrierColor: barrierColor ?? this.barrierColor,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  AppDialogConfig config = AppDialogConfig.standard,
  bool barrierDismissible = true,
  String? barrierLabel,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: config.barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    builder: (context) => AppDialog(config: config, child: builder(context)),
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.child,
    this.config = AppDialogConfig.standard,
    super.key,
  });

  final Widget child;
  final AppDialogConfig config;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: config.insetPadding,
      backgroundColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: config.maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height - config.maxHeightOffset,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: config.backgroundColor,
            border: Border.all(color: config.borderColor),
            borderRadius: config.borderRadius,
            boxShadow: [
              BoxShadow(
                color: config.shadowColor,
                blurRadius: config.shadowBlurRadius,
                offset: config.shadowOffset,
              ),
            ],
          ),
          child: ClipRRect(borderRadius: config.borderRadius, child: child),
        ),
      ),
    );
  }
}
