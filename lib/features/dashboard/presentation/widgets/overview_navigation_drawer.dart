import 'package:flutter/material.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OverviewNavigationDrawer extends StatelessWidget {
  const OverviewNavigationDrawer({
    required this.focusScopeNode,
    required this.closeFocusNode,
    required this.onClose,
    required this.onNavigate,
    super.key,
  });
  final FocusScopeNode focusScopeNode;
  final FocusNode closeFocusNode;
  final VoidCallback onClose;
  final ValueChanged<String> onNavigate;
  static const _links = <({String keyName, String label, String? route})>[
    (keyName: 'dashboard', label: 'Overview', route: AppRoutes.home),
    (keyName: 'jobs', label: 'Shoots', route: AppRoutes.dashboardShoots),
    (
      keyName: 'products',
      label: 'Products',
      route: AppRoutes.dashboardProducts,
    ),
    (
      keyName: 'models',
      label: 'House Models',
      route: AppRoutes.dashboardModels,
    ),
    (keyName: 'brand-studio', label: 'Brand Studio', route: null),
    (
      keyName: 'learning',
      label: 'Learning Center',
      route: AppRoutes.studioSchool,
    ),
  ];
  @override
  Widget build(BuildContext context) => Drawer(
    shape: const RoundedRectangleBorder(),
    backgroundColor: const Color(0xFFF8F8F6),
    elevation: 0,
    child: FocusScope(
      node: focusScopeNode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E2DC))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Look Atlas',
                      style: OverviewStyle.serif(20, spacing: -.4),
                    ),
                  ),
                  SizedBox.square(
                    dimension: 32,
                    child: IconButton(
                      key: const ValueKey('dashboard-close-navigation'),
                      focusNode: closeFocusNode,
                      tooltip: 'Close navigation',
                      onPressed: onClose,
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD4D4CE)),
                        shape: const RoundedRectangleBorder(),
                      ),
                      icon: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: OverviewStyle.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                key: const ValueKey('dashboard-drawer-scroll'),
                padding: EdgeInsets.zero,
                itemCount: _links.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final link = _links[index];
                  return InkWell(
                    key: ValueKey('dashboard-drawer-${link.keyName}'),
                    onTap: link.route == null
                        ? null
                        : () => onNavigate(link.route!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: index == 0 ? const Color(0xFFE8E8E2) : null,
                        border: Border(
                          left: BorderSide(
                            width: index == 0 ? 2 : 0,
                            color: index == 0
                                ? OverviewStyle.ink
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              link.label,
                              style: OverviewStyle.body(
                                13,
                                bold: true,
                                color: const Color(0xFF383834),
                              ),
                            ),
                          ),
                          if (link.route == null)
                            Text(
                              'SOON',
                              style: OverviewStyle.body(9, bold: true),
                            )
                          else
                            const Icon(
                              LucideIcons.arrowRight,
                              size: 10,
                              color: OverviewStyle.muted,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
