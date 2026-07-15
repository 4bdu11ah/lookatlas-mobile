import 'package:flutter/material.dart';

/// Design tokens for the Look Atlas monochrome palette, mirroring the mockup
/// design system (near-black on white, sharp corners, no accent hue). Colors
/// are defined explicitly rather than seed-derived so the app matches the
/// mockups exactly.
abstract final class AppColors {
  // --- Neutral ramp (the whole UI is built from these) --------------------
  static const Color black = Color(0xFF0A0A0A); // foreground / primary
  static const Color nearBlack = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF); // background / card
  static const Color transparent = Color(0x00000000);
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5); // secondary / muted
  static const Color neutral150 = Color(0xFFF7F7F7);
  static const Color neutral175 = Color(0xFFF8F8F8);
  static const Color neutral200 = Color(0xFFE5E5E5); // border / input
  static const Color neutral225 = Color(0xFFE9E9E9);
  static const Color neutral250 = Color(0xFFDCDCDC);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373); // muted-foreground
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  static const Color neutral925 = Color(0xFF17171A);
  static const Color neutral940 = Color(0xFF1D1D20);
  static const Color neutral945 = Color(0xFF2E2E31);
  static const Color neutral950 = Color(0xFF2A2A2C);
  static const Color neutral960 = Color(0xFF333336);
  static const Color neutralLight = Color(0xFFEFEFEF);
  static const Color neutralMedium = Color(0xFFC3C3C3);

  // --- Alpha tokens -------------------------------------------------------
  static const Color blackAlpha07 = Color(0x11000000);
  static const Color blackAlpha10 = Color(0x1A000000);
  static const Color blackAlpha15 = Color(0x26000000);
  static const Color blackAlpha20 = Color(0x33000000);
  static const Color blackAlpha25 = Color(0x40000000);
  static const Color blackAlpha40 = Color(0x66000000);
  static const Color blackAlpha50 = Color(0x80000000);
  static const Color blackAlpha60 = Color(0x99000000);
  static const Color blackAlpha70 = Color(0xB3000000);
  static const Color blackAlpha80 = Color(0xCC000000);
  static const Color blackAlpha86 = Color(0xDB000000);
  static const Color blackAlpha90 = Color(0xE6000000);

  static const Color inkAlpha04 = Color(0x0A0A0A0A);
  static const Color inkAlpha05 = Color(0x0D0A0A0A);
  static const Color inkAlpha08 = Color(0x140A0A0A);
  static const Color inkAlpha12 = Color(0x1F0A0A0A);
  static const Color inkAlpha18 = Color(0x2E0A0A0A);
  static const Color inkAlpha20 = Color(0x330A0A0A);
  static const Color inkAlpha68 = Color(0xAD0A0A0A);
  static const Color inkAlpha70 = Color(0xB30A0A0A);
  static const Color inkAlpha80 = Color(0xCC0A0A0A);
  static const Color inkAlpha82 = Color(0xD10A0A0A);

  static const Color darkAlpha04 = Color(0x090D0D0D);
  static const Color darkAlpha11 = Color(0x1C0D0D0D);

  static const Color whiteAlpha03 = Color(0x08FFFFFF);
  static const Color whiteAlpha04 = Color(0x0AFFFFFF);
  static const Color whiteAlpha05 = Color(0x0DFFFFFF);
  static const Color whiteAlpha06 = Color(0x0FFFFFFF);
  static const Color whiteAlpha09 = Color(0x17FFFFFF);
  static const Color whiteAlpha10 = Color(0x1AFFFFFF);
  static const Color whiteAlpha13 = Color(0x21FFFFFF);
  static const Color whiteAlpha15 = Color(0x26FFFFFF);
  static const Color whiteAlpha20 = Color(0x33FFFFFF);
  static const Color whiteAlpha22 = Color(0x38FFFFFF);
  static const Color whiteAlpha25 = Color(0x40FFFFFF);
  static const Color whiteAlpha30 = Color(0x4DFFFFFF);
  static const Color whiteAlpha40 = Color(0x66FFFFFF);
  static const Color whiteAlpha48 = Color(0x7AFFFFFF);
  static const Color whiteAlpha50 = Color(0x80FFFFFF);
  static const Color whiteAlpha60 = Color(0x99FFFFFF);
  static const Color whiteAlpha65 = Color(0xA6FFFFFF);
  static const Color whiteAlpha70 = Color(0xB3FFFFFF);
  static const Color whiteAlpha80 = Color(0xCCFFFFFF);
  static const Color whiteAlpha82 = Color(0xD1FFFFFF);
  static const Color whiteAlpha85 = Color(0xD9FFFFFF);
  static const Color whiteAlpha90 = Color(0xE6FFFFFF);

  static const Color neutral100Alpha30 = Color(0x4DF5F5F5);
  static const Color neutral100Alpha68 = Color(0xADF5F5F5);
  static const Color neutral100Alpha72 = Color(0xB8F5F5F5);
  static const Color neutral200Alpha40 = Color(0x66E5E5E5);

  // --- Semantic scales (from the mockup Tailwind config) ------------------
  static const Color success = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF15803D);
  static const Color successDarker = Color(0xFF047857);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color danger = Color(0xFFEF4444); // destructive / error
  static const Color dangerDark = Color(0xFFB91C1C);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF1D4ED8);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);
  static const Color orange = Color(0xFFFB923C);
}
