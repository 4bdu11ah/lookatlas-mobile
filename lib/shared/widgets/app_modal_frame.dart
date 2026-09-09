import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_hairline.dart';
import 'package:look_atlas/shared/widgets/app_media_widgets.dart';
import 'package:look_atlas/shared/widgets/app_spaced_column.dart';
import 'package:look_atlas/shared/widgets/app_tap_icon_button.dart';
import 'package:look_atlas/shared/widgets/app_text.dart';

class AppModalFrame extends StatelessWidget {
  const AppModalFrame({
    required this.title,
    this.subtitle,
    this.leading,
    this.children = const [],
    this.actions = const [],
    this.actionFlexes = const [],
    super.key,
  }) : assert(
         actionFlexes.length == 0 || actionFlexes.length == actions.length,
         'actionFlexes must match actions length.',
       );

  final String title;
  final String? subtitle;
  final IconData? leading;
  final List<Widget> children;
  final List<Widget> actions;
  final List<int> actionFlexes;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 17, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                AppSquareIcon(leading!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      AppCaption(subtitle!),
                    ],
                  ],
                ),
              ),
              AppTapIconButton(
                icon: Icons.close,
                label: 'Close dialog',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const AppHairline(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(17),
            child: AppSpacedColumn(gap: 12, children: children),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const AppHairline(),
          Container(
            padding: const EdgeInsets.all(13),
            color: AppColors.neutral50,
            child: Row(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  Expanded(
                    flex: actionFlexes.isEmpty ? 1 : actionFlexes[index],
                    child: actions[index],
                  ),
                  if (index != actions.length - 1) const SizedBox(width: 9),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
