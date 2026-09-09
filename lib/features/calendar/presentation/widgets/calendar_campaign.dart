import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarCampaign extends ConsumerWidget {
  const CalendarCampaign({required this.s, super.key});
  final CalendarSession s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(calendarControllerProvider.select((state) => state.products));
    final own = s.products
        .where((product) => product.thumbnail != null)
        .toList();
    const files = [
      'slideshow-fur-detail-v2',
      'slideshow-fur-hero-v2',
      'slideshow-fur-hook-v2',
      'slideshow-fur-use-v3',
      'slideshow-fur-finish-v3',
      'case-study-fashion-system-v3',
    ];
    const labels = [
      'Teaser detail',
      'On-model reveal',
      'Styling story',
      'Material study',
      'Movement post',
      'Final story',
    ];
    const cells = [
      (0, 0, 5, 4),
      (5, 0, 7, 7),
      (0, 4, 5, 4),
      (0, 8, 4, 4),
      (4, 7, 4, 5),
      (8, 7, 4, 5),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CALENDAR_LINE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                color: CALENDAR_INK,
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 13,
                ),
              ),
              const SizedBox(width: 11),
              calendarKicker('What we’ll create'),
            ],
          ),
          const SizedBox(height: 21),
          calendarDisplay(own.isEmpty ? 'One product.' : 'Your products.', 40),
          calendarDisplay(
            own.isEmpty ? 'Six connected moments.' : 'One connected month.',
            40,
            italic: true,
            color: CALENDAR_MUTED,
          ),
          const SizedBox(height: 23),
          SizedBox(
            height: 440,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - 6 - 33) / 12;
                const h = (440 - 6 - 33) / 12;
                return ColoredBox(
                  color: CALENDAR_INK,
                  child: Stack(
                    children: [
                      for (var i = 0; i < 6; i++)
                        Positioned(
                          left: 3 + cells[i].$1 * (w + 3),
                          top: 3 + cells[i].$2 * (h + 3),
                          width: cells[i].$3 * w + (cells[i].$3 - 1) * 3,
                          height: cells[i].$4 * h + (cells[i].$4 - 1) * 3,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              calendarPhoto(
                                i < own.length
                                    ? own[i].thumbnail!
                                    : 'assets/images/create_content/${files[i]}.webp',
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black87,
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '0${i + 1}',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 9,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          i < own.length
                                              ? own[i].name
                                              : labels[i],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          calendarRule(),
          const SizedBox(height: 17),
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 16),
              const SizedBox(width: 10),
              Expanded(child: calendarBody('Ready to plan from your library')),
            ],
          ),
          Text(
            '    ${s.overview!.productCount} products',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
