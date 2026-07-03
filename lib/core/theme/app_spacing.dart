/// 4pt spacing scale. Use these constants instead of magic numbers so spacing
/// stays consistent across the app.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // The design system uses sharp, square corners everywhere (radius 0). The
  // `full` radius is reserved for genuinely circular elements (avatars, pills).
  static const double radius = 0;
  static const double radiusLg = 0;
  static const double radiusFull = 9999;
}
