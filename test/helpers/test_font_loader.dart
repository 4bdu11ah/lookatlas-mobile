import 'package:flutter/services.dart';

Future<void> loadTestFonts() async {
  final fontLoader = FontLoader('Satoshi')
    ..addFont(rootBundle.load('assets/fonts/Satoshi-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Satoshi-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Satoshi-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Satoshi-Black.ttf'));
  await fontLoader.load();
  final serifLoader = FontLoader('InstrumentSerif')
    ..addFont(rootBundle.load('assets/fonts/InstrumentSerif-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/InstrumentSerif-Italic.ttf'));
  await serifLoader.load();
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await iconLoader.load();

  final brandFonts = [
    ('Sekuya', 'assets/fonts/Sekuya-Regular.ttf'),
    ('RethinkSans', 'assets/fonts/RethinkSans-Regular.ttf'),
    ('Qahiri', 'assets/fonts/Qahiri-Regular.ttf'),
    ('RedRose', 'assets/fonts/RedRose-Regular.ttf'),
  ];
  for (final (name, assetPath) in brandFonts) {
    final loader = FontLoader(name)..addFont(rootBundle.load(assetPath));
    await loader.load();
  }
}
