import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';

/// TEMPORARY STUB — the real dashboard is parked in
/// `parked_features/lib/features/home/` (to be pushed separately).
/// Run `./restore_parked_features.sh` to bring it back; that overwrites this
/// file with the full implementation.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(toolbarHeight: 64, title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(
              'Dashboard is on its way.',
              style: TextStyle(
                fontSize: 18,
                height: 1.3,
                fontWeight: AppTypography.semiBold,
                color: scheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => unawaited(
                ref.read(authControllerProvider.notifier).signOut(),
              ),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
