import 'package:flutter/material.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarDateTimeField extends StatelessWidget {
  const CalendarDateTimeField({
    required this.controller,
    required this.plan,
    required this.now,
    this.label = 'When it posts',
    this.onBlur,
    this.onPicked,
    this.topPadding = 21,
    super.key,
  });

  final TextEditingController controller;
  final CalendarPlan plan;
  final DateTime now;
  final String label;
  final VoidCallback? onBlur;
  final VoidCallback? onPicked;
  final double topPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: topPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        calendarKicker(label),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onBlur?.call();
          },
          child: AppTextField(
            controller: controller,
            fieldKey: const ValueKey('calendar-post-time-field'),
            height: 48,
            keyboardType: TextInputType.datetime,
            textStyle: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 12,
            ),
            trailing: IconButton(
              onPressed: () => _pickDateTime(context),
              tooltip: 'Choose posting date and time',
              icon: const Icon(LucideIcons.calendarDays, size: 18),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _pickDateTime(BuildContext context) async {
    final planStart = DateUtils.dateOnly(DateTime.parse(plan.startsOn));
    final planEnd = DateUtils.dateOnly(DateTime.parse(plan.endsOn));
    final today = DateUtils.dateOnly(now);
    final firstDate = planStart.isAfter(today) ? planStart : today;
    final lastDate = planEnd.isBefore(firstDate) ? firstDate : planEnd;
    final current = calendarParseInput(controller.text);
    final initialDate = _within(current ?? firstDate, firstDate, lastDate);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 11, minute: 0)
          : TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    controller.text = calendarLocalInput(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
    onPicked?.call();
  }

  DateTime _within(DateTime value, DateTime first, DateTime last) {
    if (value.isBefore(first)) return first;
    if (value.isAfter(last)) return last;
    return value;
  }
}
