import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';

Widget calendarSummaryCell(String text, {bool bold = false}) => Container(
  width: double.infinity,
  constraints: const BoxConstraints(minHeight: 49),
  alignment: Alignment.centerLeft,
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  decoration: const BoxDecoration(
    color: Colors.white,
    border: Border(
      bottom: BorderSide(color: CALENDAR_LINE),
      right: BorderSide(color: CALENDAR_LINE),
    ),
  ),
  child: Text(
    text,
    style: TextStyle(
      fontSize: 11,
      height: 1.25,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
    ),
  ),
);
Widget calendarFullBleed(Widget child) => LayoutBuilder(
  builder: (context, c) => OverflowBox(
    fit: OverflowBoxFit.deferToChild,
    minWidth: c.maxWidth + 28,
    maxWidth: c.maxWidth + 28,
    alignment: Alignment.topCenter,
    child: child,
  ),
);
