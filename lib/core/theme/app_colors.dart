import 'package:flutter/material.dart';

/// Design tokens for the Look Atlas monochrome palette, mirroring the mockup
/// design system (near-black on white, sharp corners, no accent hue). Colors
/// are defined explicitly rather than seed-derived so the app matches the
/// mockups exactly.
abstract final class AppColors {
  // --- Neutral ramp (the whole UI is built from these) --------------------
  static const Color black = Color(0xFF0A0A0A); // foreground / primary
  static const Color white = Color(0xFFFFFFFF); // background / card
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5); // secondary / muted
  static const Color neutral200 = Color(0xFFE5E5E5); // border / input
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373); // muted-foreground
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  // --- Semantic scales (from the mockup Tailwind config) ------------------
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444); // destructive / error
  static const Color info = Color(0xFF3B82F6);
}
