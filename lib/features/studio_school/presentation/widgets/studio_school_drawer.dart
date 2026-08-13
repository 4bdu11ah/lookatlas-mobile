import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';

class StudioSchoolDrawer extends StatelessWidget {
  const StudioSchoolDrawer({super.key});

  static const _items = <({String label, IconData icon, String route})>[
    (label: 'Dashboard', icon: Icons.dashboard_outlined, route: AppRoutes.home),
    (
      label: 'Workshop',
      icon: Icons.auto_fix_high_outlined,
      route: AppRoutes.workshop,
    ),
    (
      label: 'House Models',
      icon: Icons.groups_outlined,
      route: AppRoutes.dashboardModels,
    ),
    (
      label: 'Products',
      icon: Icons.inventory_2_outlined,
      route: AppRoutes.dashboardProducts,
    ),
    (
      label: 'Shoots',
      icon: Icons.play_arrow_outlined,
      route: AppRoutes.dashboardShoots,
    ),
    (
      label: 'Billing',
      icon: Icons.credit_card_outlined,
      route: AppRoutes.dashboardBilling,
    ),
    (
      label: 'Support',
      icon: Icons.help_outline,
      route: AppRoutes.dashboardSupport,
    ),
    (
      label: 'Studio School',
      icon: Icons.school_outlined,
      route: AppRoutes.studioSchool,
    ),
    (
      label: 'Assistant',
      icon: Icons.auto_awesome_outlined,
      route: AppRoutes.assistant,
    ),
    (
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: AppRoutes.dashboardAccount,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 256,
      shape: const RoundedRectangleBorder(),
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.neutral200)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: const AppImage('assets/images/logo.png'),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Look Atlas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close navigation',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final active = item.route == AppRoutes.studioSchool;
                  return Material(
                    color: active ? AppColors.black : AppColors.white,
                    child: InkWell(
                      key: ValueKey('school-drawer-${item.route}'),
                      onTap: () {
                        final router = GoRouter.of(context);
                        Navigator.pop(context);
                        if (active) return;
                        final location = item.route == AppRoutes.studioSchool
                            ? '${item.route}?source=drawer'
                            : item.route;
                        unawaited(router.push<void>(location));
                      },
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(
                              item.icon,
                              size: 20,
                              color: active
                                  ? AppColors.white
                                  : AppColors.neutral500,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: active
                                    ? AppColors.white
                                    : AppColors.neutral500,
                                fontWeight: active
                                    ? AppTypography.bold
                                    : AppTypography.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
