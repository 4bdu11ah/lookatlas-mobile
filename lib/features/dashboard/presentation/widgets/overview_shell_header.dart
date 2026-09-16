import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_overview_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OverviewShellHeader extends StatelessWidget {
  const OverviewShellHeader({
    required this.menuFocusNode,
    required this.onOpenNavigation,
    required this.onOpenBilling,
    super.key,
  });

  final FocusNode menuFocusNode;
  final VoidCallback onOpenNavigation;
  final VoidCallback onOpenBilling;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.tightFor(height: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: OverviewStyle.paper,
        border: Border(bottom: BorderSide(color: Color(0xB3D9D8D0))),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Open navigation',
            child: SizedBox.square(
              dimension: 36,
              child: IconButton(
                key: const ValueKey('dashboard-open-navigation'),
                focusNode: menuFocusNode,
                tooltip: 'Open navigation',
                onPressed: onOpenNavigation,
                style: IconButton.styleFrom(
                  backgroundColor: OverviewStyle.paper,
                  foregroundColor: const Color(0xFF181816),
                  side: const BorderSide(color: Color(0xFFD9D8D0)),
                  shape: const RoundedRectangleBorder(),
                ),
                icon: const Icon(LucideIcons.menu, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Overview',
              style: TextStyle(
                color: OverviewStyle.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -.13,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final dashboard = ref.watch(
                dashboardOverviewControllerProvider.select(
                  (state) => state.value?.stats?.credits,
                ),
              );
              final label = dashboard == null
                  ? '… credits'
                  : '$dashboard credits';
              return Semantics(
                button: true,
                label: '$label, open billing and credits',
                child: InkWell(
                  key: const ValueKey('dashboard-header-credits'),
                  onTap: onOpenBilling,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: OverviewStyle.paper,
                      border: Border.all(color: const Color(0xFFD9D8D0)),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF181816),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
