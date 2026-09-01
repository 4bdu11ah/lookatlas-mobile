import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoadingIconButton extends StatefulWidget {
  const LoadingIconButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon = LucideIcons.arrowRight,
    this.height = 46,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;
  final double height;

  @override
  State<LoadingIconButton> createState() => _LoadingIconButtonState();
}

class _LoadingIconButtonState extends State<LoadingIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    if (widget.isLoading) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant LoadingIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading == widget.isLoading) return;
    if (widget.isLoading) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      onPressed: widget.isLoading ? null : widget.onPressed,
      icon: widget.isLoading
          ? RotationTransition(
              turns: _controller,
              child: const Icon(LucideIcons.loader2, size: 18),
            )
          : Icon(widget.icon, size: 18),
      label: Text(widget.label),
    ),
  );
}
