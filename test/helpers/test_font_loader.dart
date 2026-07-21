import 'package:flutter/services.dart';

Future<void> loadTestFonts() async {
  final fontLoader = FontLoader('Satoshi')
    ..addFont(rootBundle.load('assets/fonts/Satoshi-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Satoshi-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Satoshi-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Satoshi-Black.ttf'));
  await fontLoader.load();
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await iconLoader.load();
}
