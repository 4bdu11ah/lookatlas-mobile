import 'package:flutter/material.dart';

/// Shared responsive rules. Layout changes at a few stable widths instead of
/// scaling every pixel with the device width.
abstract final class AppResponsive {
  static const double compactBreakpoint = 600;
  static const double wideBreakpoint = 800;
  static const double desktopBreakpoint = 1024;

  static const double formMaxWidth = 480;
  static const double tabletLayoutMaxWidth = 1140;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactBreakpoint && width < desktopBreakpoint;
  }

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
