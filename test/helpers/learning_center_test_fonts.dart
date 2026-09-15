import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'test_font_loader.dart';

Future<void> loadLearningCenterTestFonts() async {
  await loadTestFonts();
  await (FontLoader('InstrumentSerif')
        ..addFont(rootBundle.load('assets/fonts/InstrumentSerif-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/InstrumentSerif-Italic.ttf')))
      .load();
  const icon = LucideIcons.coins;
  await (FontLoader('packages/${icon.fontPackage}/${icon.fontFamily}')..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      ))
      .load();
}
