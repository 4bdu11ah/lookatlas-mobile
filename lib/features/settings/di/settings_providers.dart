import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/settings/presentation/controllers/theme_controller.dart';

final appThemeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeModeProvider),
);
