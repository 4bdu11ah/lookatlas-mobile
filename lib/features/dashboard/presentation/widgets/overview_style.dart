import 'package:flutter/material.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class OverviewStyle {
  static const ink = Color(0xFF181816);
  static const paper = Color(0xFFFFFEFA);
  static const line = Color(0xFFD9D8D0);
  static const muted = Color(0xFF6F6F68);
  static const soft = Color(0xFFF2F1EB);
  static const live = Color(0xFF2E7D32);

  static TextStyle serif(
    double size, {
    double height = 1.05,
    double spacing = 0,
    Color color = ink,
    bool italic = false,
  }) => TextStyle(
    fontFamily: 'InstrumentSerif',
    fontSize: size,
    height: height,
    fontWeight: FontWeight.w400,
    letterSpacing: spacing,
    color: color,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );

  static TextStyle body(
    double size, {
    double height = 1.5,
    Color color = muted,
    bool bold = false,
  }) => TextStyle(
    fontFamily: 'Satoshi',
    fontSize: size,
    height: height,
    color: color,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
  );
}

class OverviewLabel extends StatelessWidget {
  const OverviewLabel(this.text, {this.color = OverviewStyle.muted, super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontFamily: 'Satoshi',
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      height: 1.2,
    ),
  );
}

class OverviewSectionHeading extends StatelessWidget {
  const OverviewSectionHeading({
    required this.index,
    required this.label,
    required this.title,
    this.action,
    super.key,
  });
  final String index;
  final String label;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 14),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: OverviewStyle.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Text(
            index,
            style: OverviewStyle.serif(
              18,
              height: 1,
              italic: true,
              color: OverviewStyle.muted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OverviewLabel(label),
              const SizedBox(height: 2),
              Text(title, style: OverviewStyle.serif(28, spacing: -.7)),
              if (action != null) ...[const SizedBox(height: 14), action!],
            ],
          ),
        ),
      ],
    ),
  );
}

class OverviewLink extends StatelessWidget {
  const OverviewLink(
    this.label, {
    required this.onTap,
    this.color = OverviewStyle.ink,
    this.size = 11,
    this.underline = false,
    super.key,
  });
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final bool underline;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: OverviewStyle.body(size, color: color, bold: true)
                  .copyWith(
                    decoration: underline ? TextDecoration.underline : null,
                    decorationColor: color.withValues(alpha: .4),
                  ),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.arrowRight, size: 13, color: color),
          ],
        ),
      ),
    ),
  );
}

class OverviewButton extends StatelessWidget {
  const OverviewButton(
    this.label, {
    required this.onPressed,
    this.icon,
    this.light = false,
    this.outlined = false,
    this.height = 44,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool light;
  final bool outlined;
  final double height;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? OverviewStyle.ink : OverviewStyle.paper;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const RoundedRectangleBorder(),
          backgroundColor: outlined
              ? Colors.transparent
              : light
              ? OverviewStyle.paper
              : OverviewStyle.ink,
          foregroundColor: foreground,
          disabledForegroundColor: foreground.withValues(alpha: .5),
          side: outlined ? const BorderSide(color: Color(0x66FFFFFA)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: OverviewStyle.body(
                  outlined ? 11 : 12,
                  color: foreground,
                  bold: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewImage extends StatelessWidget {
  const OverviewImage(this.source, {required this.label, super.key});
  final String source;
  final String label;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Semantics(
      image: true,
      label: label,
      child: source.isEmpty
          ? const ColoredBox(
              color: OverviewStyle.soft,
              child: Center(
                child: Icon(LucideIcons.image, color: OverviewStyle.muted),
              ),
            )
          : AppImage(
              source,
              width: constraints.maxWidth,
              fit: BoxFit.cover,
              placeholder: const ColoredBox(color: OverviewStyle.soft),
            ),
    ),
  );
}

class OverviewPanelState extends StatelessWidget {
  const OverviewPanelState({
    required this.title,
    required this.body,
    this.action,
    this.error = false,
    this.serif = false,
    super.key,
  });
  final String title;
  final String body;
  final Widget? action;
  final bool error;
  final bool serif;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    color: error
        ? OverviewStyle.soft.withValues(alpha: .55)
        : OverviewStyle.paper,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error) ...[
          const Icon(
            LucideIcons.circleAlert,
            size: 20,
            color: OverviewStyle.muted,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          title,
          style: serif
              ? OverviewStyle.serif(24)
              : OverviewStyle.body(13, color: OverviewStyle.ink, bold: true),
        ),
        const SizedBox(height: 6),
        Text(body, style: OverviewStyle.body(11.5)),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}
