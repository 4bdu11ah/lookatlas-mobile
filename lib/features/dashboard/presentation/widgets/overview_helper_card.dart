import 'package:flutter/material.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OverviewHelperCard extends StatelessWidget {
  const OverviewHelperCard({
    required this.content,
    required this.onDismiss,
    required this.onOpen,
    required this.dismissTooltip,
    super.key,
  });
  final ({String label, String title, String body, String photo, String action})
  content;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;
  final String dismissTooltip;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(border: Border.all(color: OverviewStyle.line)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 140,
          child: OverviewImage(content.photo, label: content.label),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: OverviewLabel(content.label)),
                  SizedBox.square(
                    dimension: 18,
                    child: IconButton(
                      onPressed: onDismiss,
                      tooltip: dismissTooltip,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: OverviewStyle.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(content.title, style: OverviewStyle.serif(22, height: 1.1)),
              const SizedBox(height: 8),
              Text(content.body, style: OverviewStyle.body(11.5)),
              const SizedBox(height: 14),
              OverviewButton(content.action, height: 36, onPressed: onOpen),
            ],
          ),
        ),
      ],
    ),
  );
}
