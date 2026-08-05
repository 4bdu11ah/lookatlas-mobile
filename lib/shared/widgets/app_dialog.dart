import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

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
    this.title,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.icon,
    this.iconColor = AppColors.white,
    this.iconBackgroundColor = AppColors.black,
    this.iconSize = 24,
    this.iconBoxSize = 44,
    this.showCloseButton = true,
    this.closeButtonColor = AppColors.neutral500,
  });

  static const AppDialogConfig standard = AppDialogConfig();

  // --- Layout ---
  final EdgeInsets insetPadding;
  final double maxWidth;
  final double maxHeightOffset;

  // --- Appearance ---
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final Color barrierColor;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  // --- Header ---
  final String? title;
  final TextStyle? titleStyle;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final double iconSize;
  final double iconBoxSize;
  final bool showCloseButton;
  final Color closeButtonColor;

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
    String? title,
    TextStyle? titleStyle,
    String? subtitle,
    TextStyle? subtitleStyle,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    double? iconSize,
    double? iconBoxSize,
    bool? showCloseButton,
    Color? closeButtonColor,
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
      title: title ?? this.title,
      titleStyle: titleStyle ?? this.titleStyle,
      subtitle: subtitle ?? this.subtitle,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      iconSize: iconSize ?? this.iconSize,
      iconBoxSize: iconBoxSize ?? this.iconBoxSize,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      closeButtonColor: closeButtonColor ?? this.closeButtonColor,
    );
  }
}

/// Shows a standardized app dialog.
///
/// [builder] supplies the center body content.
///
/// Header fields ([title], [subtitle], [icon], etc.) override matching
/// [AppDialogConfig] values for convenience so callers don't need to construct
/// a config object for simple cases.
///
/// [footer] is rendered below the body in a tinted container. Pass any widget
/// (typically a `Row` of buttons).
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  AppDialogConfig config = AppDialogConfig.standard,
  bool barrierDismissible = true,
  String? barrierLabel,
  // --- header overrides ---
  String? title,
  TextStyle? titleStyle,
  String? subtitle,
  TextStyle? subtitleStyle,
  IconData? icon,
  Color? iconColor,
  Color? iconBackgroundColor,
  double? iconSize,
  double? iconBoxSize,
  bool? showCloseButton,
  Color? closeButtonColor,
  // --- footer ---
  Widget? footer,
}) {
  final hasHeaderOverrides =
      title != null ||
      titleStyle != null ||
      subtitle != null ||
      subtitleStyle != null ||
      icon != null ||
      iconColor != null ||
      iconBackgroundColor != null ||
      iconSize != null ||
      iconBoxSize != null ||
      showCloseButton != null ||
      closeButtonColor != null;
  final merged = hasHeaderOverrides
      ? config.copyWith(
          title: title,
          titleStyle: titleStyle,
          subtitle: subtitle,
          subtitleStyle: subtitleStyle,
          icon: icon,
          iconColor: iconColor,
          iconBackgroundColor: iconBackgroundColor,
          iconSize: iconSize,
          iconBoxSize: iconBoxSize,
          showCloseButton: showCloseButton,
          closeButtonColor: closeButtonColor,
        )
      : config;

  return showDialog<T>(
    context: context,
    barrierColor: merged.barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    builder: (context) => AppDialog(
      config: merged,
      footer: footer,
      child: builder(context),
    ),
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.child,
    this.config = AppDialogConfig.standard,
    this.footer,
    super.key,
  });

  final Widget child;
  final AppDialogConfig config;
  final Widget? footer;

  bool get _hasHeader => config.title != null;

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
          child: ClipRRect(
            borderRadius: config.borderRadius,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasHeader) _AppDialogHeader(config: config),
                Flexible(child: child),
                if (footer != null) _AppDialogFooter(child: footer!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized header row: [icon box] [title + subtitle] [close button].
class _AppDialogHeader extends StatelessWidget {
  const _AppDialogHeader({required this.config});

  final AppDialogConfig config;

  @override
  Widget build(BuildContext context) {
    const defaultTitleStyle = TextStyle(
      fontSize: 18,
      height: 1.06,
      fontWeight: AppTypography.bold,
      color: AppColors.black,
    );

    const defaultSubtitleStyle = TextStyle(
      fontSize: 12,
      height: 1.3,
      color: AppColors.neutral500,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          if (config.icon != null) ...[
            Container(
              width: config.iconBoxSize,
              height: config.iconBoxSize,
              alignment: Alignment.center,
              color: config.iconBackgroundColor,
              child: Icon(
                config.icon,
                size: config.iconSize,
                color: config.iconColor,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title!,
                  style: config.titleStyle ?? defaultTitleStyle,
                ),
                if (config.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    config.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: config.subtitleStyle ?? defaultSubtitleStyle,
                  ),
                ],
              ],
            ),
          ),
          if (config.showCloseButton)
            Semantics(
              label: 'Close',
              button: true,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: config.closeButtonColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standardized footer container with tinted background and top border.
class _AppDialogFooter extends StatelessWidget {
  const _AppDialogFooter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: child,
    );
  }
}

class AppDialogActionFooter extends StatelessWidget {
  const AppDialogActionFooter({
    required this.primaryLabel,
    required this.onCancel,
    required this.onPrimary,
    this.primaryIcon,
    this.primaryButtonKey,
    this.cancelLabel = 'Cancel',
    this.primaryDisabled = false,
    this.primaryOpacity,
    this.isLoading = false,
    this.danger = false,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onPrimary;
  final IconData? primaryIcon;
  final Key? primaryButtonKey;
  final String cancelLabel;
  final bool primaryDisabled;
  final double? primaryOpacity;
  final bool isLoading;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final primaryEnabled = !primaryDisabled && !isLoading;
    return Column(
      children: [
        AppOutlinedButton(
          label: cancelLabel,
          onPressed: isLoading ? null : onCancel,
          borderColor: AppColors.black,
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: primaryOpacity ?? (primaryEnabled ? 1 : 0.48),
          child: PrimaryButton(
            key: primaryButtonKey,
            label: primaryLabel,
            icon: primaryIcon,
            isLoading: isLoading,
            onPressed: primaryEnabled ? onPrimary : null,
            backgroundColor: danger ? AppColors.dangerDark : AppColors.black,
            foregroundColor: AppColors.white,
            iconSize: 16,
          ),
        ),
      ],
    );
  }
}
