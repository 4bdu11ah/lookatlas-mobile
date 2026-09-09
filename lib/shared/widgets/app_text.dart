import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({required this.title, required this.body, super.key,
    this.small = false,
  });

  final String title;
  final String body;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          softWrap: true,
          style:
              (small
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.headlineMedium)
                  ?.copyWith(
                    height: small ? 1.1 : 1.05,
                    letterSpacing: -0.6,
                    color: AppColors.black,
                  ),
        ),
        const SizedBox(height: 6),
        AppBodyText(body),
      ],
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: true,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        height: 1.2,
        letterSpacing: -0.2,
        color: AppColors.black,
      ),
    );
  }
}

class AppCardTitle extends StatelessWidget {
  const AppCardTitle(
    this.text, {super.key, 
    this.fontSize,
    this.color,
  });

  final String text;
  final double? fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        height: 1.2,
        fontSize: fontSize,
        color: color ?? AppColors.black,
      ),
    );
  }
}

class AppBodyText extends StatelessWidget {
  const AppBodyText(this.text, {super.key, this.textAlign});

  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      softWrap: true,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        height: 1.55,
        color: AppColors.neutral500,
      ),
    );
  }
}

class AppCaption extends StatelessWidget {
  const AppCaption(
    this.text, {super.key, 
    this.fontSize,
    this.color,
  });

  final String text;
  final double? fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: true,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        height: 1.45,
        fontSize: fontSize,
        color: color ?? AppColors.neutral500,
      ),
    );
  }
}

class AppEyebrow extends StatelessWidget {
  const AppEyebrow(this.text, {super.key, this.maxLines = 1});

  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: maxLines,
      overflow: maxLines == 1 ? TextOverflow.ellipsis : TextOverflow.visible,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        height: 1.3,
        letterSpacing: 1.1,
        fontWeight: AppTypography.bold,
        color: AppColors.neutral500,
      ),
    );
  }
}

class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: AppTypography.bold,
        color: AppColors.black,
      ),
    );
  }
}
