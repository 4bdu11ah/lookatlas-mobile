import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_view_controller.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_setup_controls.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarProductPriorities extends ConsumerWidget {
  const CalendarProductPriorities({required this.s, super.key});
  final CalendarSession s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.products,
          state.productError,
          state.productsLoading,
          state.setup.objective,
          state.setup.priorities,
        ),
      ),
    );
    final productsOpen = ref.watch(
      calendarViewProvider.select((state) => state.productsOpen),
    );
    final local = ref.read(calendarViewProvider.notifier);
    final controller = ref.read(calendarControllerProvider.notifier);
    final d = s.setup;
    final launch = d.objective == 'Launch a product';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => local.setProductsOpen(value: !productsOpen),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 19,
              vertical: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        launch
                            ? 'Which product are you launching?'
                            : 'Choose priority products',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      calendarBody(
                        launch
                            ? 'Mark it Prioritize, the month opens and closes on it'
                            : 'Optional · We can use your whole library',
                        size: 11,
                      ),
                    ],
                  ),
                ),
                Icon(
                  productsOpen
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (productsOpen) ...[
          if (s.productsLoading) calendarNote('Loading products…'),
          if (s.productError != null)
            calendarErrorBanner(s.productError!, s.loadProducts),
          for (final p in (launch ? s.products : s.products.take(8)))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19),
              child: Column(
                children: [
                  calendarRule(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      calendarPhoto(
                        p.thumbnail,
                        width: 40,
                        height: 50,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            calendarBody(
                              p.sku,
                              size: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final e in {
                        'spotlight': 'Prioritize',
                        'rotate': 'Use normally',
                        'pause': 'Don’t use',
                      }.entries)
                        Expanded(
                          child: calendarChoice(
                            e.value,
                            () => controller.changeSetup(
                              () => d.productModes[p.id] = e.key,
                            ),
                            selected:
                                (d.productModes[p.id] ?? 'rotate') == e.key,
                            height: 35,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
