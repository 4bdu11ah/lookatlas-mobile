import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_tap_icon_button.dart';

class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({
    required this.child,
    this.title,
    this.actions = const [],
    super.key,
  });

  final String? title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral250,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (title != null)
              Container(
                height: 68,
                padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.neutral200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: AppTypography.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    AppTapIconButton(
                      icon: Icons.close,
                      label: 'Close',
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                child: child,
              ),
            ),
            if (actions.isNotEmpty) AppSheetActionBar(actions: actions),
          ],
        ),
      ),
    );
  }
}

class AppSheetActionBar extends StatelessWidget {
  const AppSheetActionBar({required this.actions, super.key});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        13,
        16,
        MediaQuery.paddingOf(context).bottom + 13,
      ),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            Expanded(child: actions[index]),
            if (index != actions.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}
