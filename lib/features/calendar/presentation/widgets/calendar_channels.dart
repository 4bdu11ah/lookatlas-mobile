import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';

Widget calendarChannelChoices(
  List<String> selected,
  ValueChanged<String> toggle,
) => LayoutBuilder(
  builder: (context, c) {
    final columns = c.maxWidth < 520 ? 2 : calendarPlatforms.length;
    final width = (c.maxWidth - (columns - 1) * 5) / columns;
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final e in calendarPlatforms.entries)
          SizedBox(
            width: width,
            child: Semantics(
              selected: selected.contains(e.key),
              child: InkWell(
                onTap: () => toggle(e.key),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: selected.contains(e.key) ? Colors.white : null,
                    border: Border.all(
                      color: selected.contains(e.key)
                          ? CALENDAR_MUTED
                          : CALENDAR_LINE,
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/calendar/${e.key}.svg',
                        width: 13,
                        height: 13,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          e.value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  },
);

Widget calendarSetupWidth(Widget child) => child;
