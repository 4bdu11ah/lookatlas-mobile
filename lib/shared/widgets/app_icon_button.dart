import 'package:flutter/material.dart';

/// Accessible icon-only action using the app's theme colors and touch target.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.size = 20,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tooltip,
    child: Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: size, color: color),
      ),
    ),
  );
}
