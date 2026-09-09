import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';

Widget calendarChannelChoices(
  List<String> selected,
  ValueChanged<String> toggle,
) => LayoutBuilder(
  builder: (context, c) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: c.maxWidth < 356.64 ? 356.64 : c.maxWidth,
      child: Row(
        children: [
          for (final e in calendarPlatforms.entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
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
                          Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  ),
);

Widget calendarSetupWidth(Widget child) => LayoutBuilder(
  builder: (context, c) => OverflowBox(
    fit: OverflowBoxFit.deferToChild,
    minWidth: c.maxWidth + 14,
    maxWidth: c.maxWidth + 14,
    alignment: Alignment.topLeft,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: c.maxWidth < 396.64 ? 396.64 : c.maxWidth,
        child: child,
      ),
    ),
  ),
);
