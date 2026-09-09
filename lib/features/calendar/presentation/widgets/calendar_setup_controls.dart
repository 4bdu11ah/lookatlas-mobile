import 'package:flutter/material.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';

Widget calendarStep(
  String? number,
  String? kicker,
  String? title,
  List<Widget> children,
) => Container(
  padding: const EdgeInsets.fromLTRB(19, 22, 19, 24),
  decoration: const BoxDecoration(
    border: Border(bottom: BorderSide(color: CALENDAR_LINE)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (number != null) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 31,
              height: 31,
              color: CALENDAR_INK,
              alignment: Alignment.center,
              child: calendarDisplay(
                number,
                14,
                color: Colors.white,
                italic: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  calendarKicker(kicker!),
                  const SizedBox(height: 5),
                  calendarDisplay(title!, 24),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 21),
      ],
      ...children,
    ],
  ),
);
Widget calendarChoice(
  String label,
  VoidCallback action, {
  required bool selected,
  double height = 46,
  String? help,
  double fontSize = 12,
}) => Semantics(
  selected: selected,
  child: TextButton(
    onPressed: action,
    style: TextButton.styleFrom(
      backgroundColor: selected ? CALENDAR_INK : const Color(0xfff2f2ed),
      foregroundColor: selected ? Colors.white : const Color(0xff55554f),
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      alignment: Alignment.centerLeft,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const RoundedRectangleBorder(),
      side: BorderSide(color: selected ? CALENDAR_INK : CALENDAR_LINE),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
        ),
        if (help != null)
          Text(
            help,
            style: TextStyle(
              fontSize: 10,
              color: selected ? Colors.white54 : CALENDAR_MUTED,
            ),
          ),
      ],
    ),
  ),
);
Widget calendarMode(
  CalendarSession s,
  void Function(String) change,
  String value,
  String label,
  String help,
) => InkWell(
  onTap: () => change(value),
  child: Container(
    constraints: const BoxConstraints(minHeight: 82),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    decoration: BoxDecoration(
      color: s.setup.mode == value ? const Color(0xfffaf9f5) : Colors.white,
      border: Border.all(
        color: s.setup.mode == value ? CALENDAR_INK : CALENDAR_LINE,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        calendarBody(help, size: 11),
      ],
    ),
  ),
);
