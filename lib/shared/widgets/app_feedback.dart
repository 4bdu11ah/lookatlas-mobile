import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_text.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

enum AppAlertKind { info, warn, error }

class AppAlert extends StatelessWidget {
  const AppAlert({required this.kind, super.key, this.text, this.richText})
    : assert(
        (text == null) != (richText == null),
        'Provide either text or richText.',
      );

  final AppAlertKind kind;
  final String? text;
  final InlineSpan? richText;

  @override
  Widget build(BuildContext context) {
    final colors = switch (kind) {
      AppAlertKind.info => (
        AppColors.neutral100,
        AppColors.neutral200,
        AppColors.neutral500,
        Icons.info_outline,
      ),
      AppAlertKind.warn => (
        AppColors.warningLight,
        AppColors.warningBorder,
        AppColors.warningDark,
        Icons.warning_amber_outlined,
      ),
      AppAlertKind.error => (
        AppColors.dangerLight,
        AppColors.dangerBorder,
        AppColors.dangerDark,
        Icons.error_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.$1,
        border: Border.all(color: colors.$2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(colors.$4, size: 18, color: colors.$3),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              richText ?? TextSpan(text: text),
              style: TextStyle(fontSize: 13, height: 1.4, color: colors.$3),
            ),
          ),
        ],
      ),
    );
  }
}

enum AppBadgeKind { neutral, dark, success, warn }

class AppBadge extends StatelessWidget {
  const AppBadge(
    this.label, {super.key, 
    this.kind = AppBadgeKind.neutral,
    this.rounded = false,
  });

  final String label;
  final AppBadgeKind kind;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final colors = switch (kind) {
      AppBadgeKind.neutral => (
        AppColors.neutral100,
        AppColors.neutral200,
        AppColors.neutral500,
      ),
      AppBadgeKind.dark => (AppColors.black, AppColors.black, AppColors.white),
      AppBadgeKind.success => (
        AppColors.successLight,
        AppColors.successBorder,
        AppColors.successDark,
      ),
      AppBadgeKind.warn => (
        AppColors.warningLight,
        AppColors.warningBorder,
        AppColors.warningDark,
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$1,
        border: Border.all(color: colors.$2),
        borderRadius: rounded ? BorderRadius.circular(999) : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          height: 1.3,
          fontWeight: AppTypography.bold,
          color: colors.$3,
        ),
      ),
    );
  }
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      status[0].toUpperCase() + status.substring(1),
      rounded: true,
      kind: switch (status) {
        'completed' => AppBadgeKind.success,
        'processing' => AppBadgeKind.dark,
        _ => AppBadgeKind.warn,
      },
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({required this.title, required this.body, required this.buttonLabel, required this.onTap, super.key,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            color: AppColors.neutral100,
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 14),
          AppSectionTitle(title),
          const SizedBox(height: 8),
          AppBodyText(body, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          PrimaryButton(
            label: buttonLabel,
            fitToContent: true,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
