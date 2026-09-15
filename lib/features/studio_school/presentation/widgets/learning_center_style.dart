import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class LearningCenterStyle {
  static const ink = Color(0xFF181816);
  static const muted = Color(0xFF6F6F68);
  static const line = Color(0xFFD9D8D0);
  static const soft = Color(0xFFF2F1EB);
  static const paper = Color(0xFFFFFEFA);

  static TextStyle serif(
    double size, {
    double height = 1,
    double tracking = -0.035,
    Color color = ink,
  }) => TextStyle(
    fontFamily: 'InstrumentSerif',
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: FontWeight.w400,
    fontSize: size,
    height: height,
    letterSpacing: size * tracking,
    color: color,
  );
  static TextStyle body(
    double size, {
    double height = 1.6,
    Color color = muted,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: 'Satoshi',
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
    fontSize: size,
    height: height,
    color: color,
    fontWeight: weight,
  );
}

class LearningKicker extends StatelessWidget {
  const LearningKicker(
    this.text, {
    this.icon,
    this.size = 11,
    this.height = 1.2,
    this.color = LearningCenterStyle.muted,
    super.key,
  });
  final String text;
  final double size;
  final double height;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 7),
      ],
      Flexible(
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: size,
            fontWeight: FontWeight.w700,
            letterSpacing: size * 0.16,
            height: height,
            color: color,
          ),
        ),
      ),
    ],
  );
}

class LearningAction extends StatelessWidget {
  const LearningAction(
    this.label, {
    required this.onPressed,
    this.outlined = false,
    this.inverted = false,
    this.height = 44,
    this.icon = LucideIcons.arrowRight,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool inverted;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = inverted || outlined
        ? LearningCenterStyle.ink
        : LearningCenterStyle.paper;
    return SizedBox(
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: label.isEmpty
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: outlined
              ? Colors.transparent
              : inverted
              ? LearningCenterStyle.paper
              : LearningCenterStyle.ink,
          foregroundColor: foreground,
          shape: const RoundedRectangleBorder(),
          side: BorderSide(
            color: inverted
                ? LearningCenterStyle.paper
                : LearningCenterStyle.ink,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == LucideIcons.chevronLeft && label.isNotEmpty) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 9),
            ],
            if (label.isNotEmpty)
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: LearningCenterStyle.body(
                    12,
                    weight: FontWeight.w800,
                    color: onPressed == null
                        ? LearningCenterStyle.muted
                        : foreground,
                  ),
                ),
              ),
            if (icon != null &&
                (icon != LucideIcons.chevronLeft || label.isEmpty)) ...[
              if (label.isNotEmpty) const SizedBox(width: 9),
              Icon(icon, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class LearningSectionHeading extends StatelessWidget {
  const LearningSectionHeading({
    required this.kicker,
    required this.title,
    required this.body,
    super.key,
  });
  final String kicker;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 50, bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LearningKicker(kicker, size: 12, height: 1.55),
        const SizedBox(height: 8),
        Text(title, style: LearningCenterStyle.serif(36)),
        const SizedBox(height: 8),
        Text(body, style: LearningCenterStyle.body(12, height: 1.55)),
      ],
    ),
  );
}
