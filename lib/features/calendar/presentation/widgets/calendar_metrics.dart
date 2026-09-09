import 'package:flutter/material.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';

Widget calendarMetric(
  String label,
  String value,
  String help,
  double width, {
  VoidCallback? onTap,
}) => InkWell(
  onTap: onTap,
  child: Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 116),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: label == 'Needs approval' ? const Color(0xff6a3940) : Colors.white,
      border: Border.all(color: CALENDAR_LINE),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        calendarBody(
          label.toUpperCase(),
          size: 11,
          color: label == 'Needs approval' ? Colors.white70 : CALENDAR_MUTED,
        ),
        const SizedBox(height: 7),
        calendarDisplay(
          value,
          31,
          color: label == 'Needs approval' ? Colors.white : CALENDAR_INK,
        ),
        const SizedBox(height: 7),
        calendarBody(
          help,
          size: 10,
          color: label == 'Needs approval' ? Colors.white70 : CALENDAR_MUTED,
        ),
      ],
    ),
  ),
);
Widget calendarNoteWithAction(
  String text,
  String label,
  VoidCallback? action,
) => Column(children: [calendarNote(text), calendarButton(label, action)]);
