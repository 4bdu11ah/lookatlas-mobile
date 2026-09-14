import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

class CalendarLoadingScreen extends ConsumerWidget {
  const CalendarLoadingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      calendarControllerProvider.select(
        (state) => (state.loading, state.error),
      ),
    );
    if (state.$1) return const _CalendarLoadingSkeleton();

    final session = ref.read(calendarControllerProvider.notifier).session;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 90),
        child: Column(
          children: [
            calendarBody(
              state.$2 ?? 'Your calendar could not be loaded.',
            ),
            calendarButton('Try again', session.refresh),
          ],
        ),
      ),
    );
  }
}

class _CalendarLoadingSkeleton extends StatelessWidget {
  const _CalendarLoadingSkeleton();

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Semantics(
      container: true,
      liveRegion: true,
      label: 'Loading your calendar',
      child: ExcludeSemantics(
        child: Column(
          key: const ValueKey('calendar-loading-skeleton'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: CALENDAR_INK),
                  bottom: BorderSide(color: CALENDAR_LINE),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalendarSkeletonBar(widthFactor: .38, height: 11),
                  SizedBox(height: 15),
                  _CalendarSkeletonBar(widthFactor: .88, height: 38),
                  SizedBox(height: 8),
                  _CalendarSkeletonBar(widthFactor: .58, height: 38),
                  SizedBox(height: 19),
                  _CalendarSkeletonBar(widthFactor: 1, height: 13),
                  SizedBox(height: 7),
                  _CalendarSkeletonBar(widthFactor: .76, height: 13),
                  SizedBox(height: 24),
                  _CalendarSkeletonBar(widthFactor: 1, height: 43),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: _CalendarSkeletonCard()),
                Expanded(child: _CalendarSkeletonCard()),
              ],
            ),
            const Row(
              children: [
                Expanded(child: _CalendarSkeletonCard()),
                Expanded(child: _CalendarSkeletonCard()),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _CalendarSkeletonCard extends StatelessWidget {
  const _CalendarSkeletonCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 94,
    padding: const EdgeInsets.all(13),
    decoration: const BoxDecoration(
      border: Border(
        right: BorderSide(color: CALENDAR_LINE),
        bottom: BorderSide(color: CALENDAR_LINE),
      ),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CalendarSkeletonBar(widthFactor: .55, height: 10),
        SizedBox(height: 12),
        _CalendarSkeletonBar(widthFactor: .34, height: 24),
        SizedBox(height: 8),
        _CalendarSkeletonBar(widthFactor: .72, height: 9),
      ],
    ),
  );
}

class _CalendarSkeletonBar extends StatelessWidget {
  const _CalendarSkeletonBar({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: SizedBox(height: height, child: const ShimmerBox()),
  );
}
