import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_components.dart';
import 'package:look_atlas/features/calendar/presentation/widgets/calendar_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarSetupEstimate extends ConsumerWidget {
  const CalendarSetupEstimate({required this.s, super.key});
  final CalendarSession s;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      calendarControllerProvider.select(
        (state) => (
          state.quote,
          state.quoteError,
          state.busy.contains('plan'),
          state.overview,
          state.setup,
        ),
      ),
    );
    final controller = ref.read(calendarControllerProvider.notifier);
    final d = s.setup;
    final q = s.quote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (q?.hasFitPreview ?? false)
          Container(
            color: const Color(0xfffaf8f2),
            padding: const EdgeInsets.all(19),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: d.fitToCredits,
                  onChanged: (v) =>
                      controller.changeSetup(() => d.fitToCredits = v!),
                  activeColor: CALENDAR_INK,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Make it fit my credits',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      calendarBody(
                        'Full month ≈ ${q!.totalCredits} credits, you have ${q.creditsRemaining}. We’ll swap ${q.downgradedPosts} slideshow/video posts for single posts (≈ ${q.fitTotal} credits).',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        calendarRule(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 19,
            vertical: 15,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                q == null ? 'Ready to plan' : '${q.postCount} posts',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              calendarBody(
                '${s.products.where((product) => d.productModes[product.id] != "pause").length} products · ${d.platforms.length} channels · ${q == null ? "Final count and credits calculated next" : "≈ ${q.totalCredits} credits"}',
                size: 11,
              ),
              if (s.quoteError != null)
                calendarErrorBanner(s.quoteError!, s.createPlan),
              const SizedBox(height: 12),
              calendarButton(
                s.planning || s.busy.contains('plan')
                    ? 'Writing your month…'
                    : 'Show me the plan',
                s.planning || s.busy.contains('plan') || d.validation != null
                    ? null
                    : s.createPlan,
                primary: true,
                icon: LucideIcons.arrowRight,
              ),
              const SizedBox(height: 12),
              calendarBody(
                d.validation ??
                    'Nothing is created or posted until you approve the plan.',
                size: 11,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
