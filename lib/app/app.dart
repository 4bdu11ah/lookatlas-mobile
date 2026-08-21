import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/router/app_router.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/settings/presentation/theme_controller.dart';
import 'package:look_atlas/shared/widgets/connectivity_banner.dart';

/// Root widget. Wires routing, theming, and the persisted theme mode.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.isDev,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      builder: (context, child) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
