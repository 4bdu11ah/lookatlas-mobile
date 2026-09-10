import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

const String productDisplayFontFamily = 'InstrumentSerif';

class CatalogEyebrow extends StatelessWidget {
  const CatalogEyebrow(
    this.text, {
    this.color = AppColors.neutral500,
    super.key,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    ),
  );
}

class ProductLoadFailure extends StatelessWidget {
  const ProductLoadFailure({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 90),
    child: Column(
      children: [
        const Icon(Icons.error_outline, size: 32),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Try again',
          onPressed: onRetry,
          fitToContent: true,
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
        ),
      ],
    ),
  );
}

class ProductPill extends StatelessWidget {
  const ProductPill.neutral(String label, {IconData? icon, Key? key})
    : this._(
        label: label,
        color: AppColors.white,
        borderColor: AppColors.neutral200,
        textColor: AppColors.neutral800,
        icon: icon,
        key: key,
      );

  const ProductPill._({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.textColor,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: borderColor),
    ),
    child: Row(
      children: [
        if (icon != null) ...[
          Transform.rotate(
            angle: -0.785398,
            child: Icon(icon, size: 10, color: textColor),
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1,
              fontWeight: AppTypography.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    ),
  );
}
