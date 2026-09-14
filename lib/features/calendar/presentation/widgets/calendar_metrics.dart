import 'package:flutter/material.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget calendarMetric(
  String label,
  String value,
  String help,
  double width, {
  VoidCallback? onTap,
}) {
  final highlighted = label == 'Needs approval';
  return InkWell(
    onTap: onTap,
    child: Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 106),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xff6a3940) : Colors.white,
        border: Border.all(color: CALENDAR_LINE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted)
            calendarBody(label.toUpperCase(), size: 11, color: Colors.white70)
          else
            calendarKicker(label),
          const SizedBox(height: 8),
          calendarDisplay(
            value,
            29,
            color: highlighted ? Colors.white : CALENDAR_INK,
          ),
          const SizedBox(height: 5),
          calendarBody(
            help,
            size: 10,
            color: highlighted ? Colors.white70 : CALENDAR_MUTED,
          ),
        ],
      ),
    ),
  );
}

Widget calendarNoteWithAction(
  String text,
  String label,
  VoidCallback? action,
) => Container(
  margin: const EdgeInsets.only(top: 14),
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: CALENDAR_FIELD,
    border: Border.all(color: CALENDAR_LINE),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Icon(LucideIcons.calendarDays, size: 17),
          const SizedBox(width: 9),
          Expanded(child: calendarBody(text)),
        ],
      ),
      const SizedBox(height: 12),
      calendarButton(label, action, compact: true),
    ],
  ),
);
