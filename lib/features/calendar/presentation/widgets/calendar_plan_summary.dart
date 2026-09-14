import 'package:flutter/material.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarPlanSummary extends StatelessWidget {
  const CalendarPlanSummary({
    required this.overview,
    required this.items,
    required this.productCount,
    super.key,
  });

  final CalendarOverview overview;
  final List<CalendarItem> items;
  final int productCount;

  @override
  Widget build(BuildContext context) {
    final estimate = (overview.estimate['total'] as num).toInt();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CALENDAR_LINE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: calendarKicker('Plan at a glance'),
          ),
          calendarRule(),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  value: '${items.length}',
                  label: 'Post ideas',
                ),
              ),
              const SizedBox(height: 76, child: VerticalDivider(width: 1)),
              Expanded(
                child: _SummaryMetric(
                  value: '$productCount',
                  label: 'Products featured',
                ),
              ),
            ],
          ),
          calendarRule(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _FormatCount(
                    icon: LucideIcons.galleryHorizontalEnd,
                    count: _count('slideshow'),
                    label: 'Slides',
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _FormatCount(
                    icon: LucideIcons.play,
                    count: _count('video'),
                    label: 'Video',
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _FormatCount(
                    icon: LucideIcons.image,
                    count: _count('single'),
                    label: 'Single',
                  ),
                ),
              ],
            ),
          ),
          calendarRule(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      calendarBody('ESTIMATED CREATION', size: 10),
                      const SizedBox(height: 3),
                      Text(
                        estimate == 0
                            ? 'Included in your plan'
                            : '≈ $estimate credits',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (overview.credits case final credits?)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    color: CALENDAR_FIELD,
                    child: Text(
                      '$credits available',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _count(String format) =>
      items.where((item) => item.format == format).length;
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        calendarDisplay(value, 29),
        const SizedBox(height: 4),
        calendarBody(label, size: 10),
      ],
    ),
  );
}

class _FormatCount extends StatelessWidget {
  const _FormatCount({
    required this.icon,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 43,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: CALENDAR_FIELD,
      border: Border.all(color: CALENDAR_LINE),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: CALENDAR_MUTED),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$count $label',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
