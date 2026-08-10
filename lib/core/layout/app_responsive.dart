import 'package:flutter/material.dart';

/// Shared responsive rules. Layout changes at a few stable widths instead of
/// scaling every pixel with the device width.
abstract final class AppResponsive {
  static const double compactBreakpoint = 600;
  static double contentMaxWidthFor(double width) {
    if (width < compactBreakpoint) return 430;
    return 720;
  }

  static int gridColumnsFor(
    double width, {
    double minItemWidth = 220,
    int maxColumns = 3,
  }) => (width / minItemWidth).floor().clamp(1, maxColumns);
}

/// Centers page content while allowing more space on tablets.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    this.maxWidth,
    super.key,
  });

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                maxWidth ??
                AppResponsive.contentMaxWidthFor(constraints.maxWidth),
          ),
          child: child,
        ),
      ),
    );
  }
}
