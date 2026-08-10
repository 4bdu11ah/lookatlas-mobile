import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/generation_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/swipe_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';

part '../widgets/swipe_results_visual_widgets.dart';
part '../widgets/swipe_results_content_widgets.dart';

/// Post-swipe results / collection view (mockup 10): stats, the saved grid,
/// in-context mockups, the dark ROI calculator and the unlock CTA. Falls back
/// to the "tune to your brand" pitch when nothing was saved.
class SwipeResultsScreen extends ConsumerStatefulWidget {
  const SwipeResultsScreen({super.key});

  @override
  ConsumerState<SwipeResultsScreen> createState() => _SwipeResultsScreenState();
}

class _SwipeResultsScreenState extends ConsumerState<SwipeResultsScreen> {
  void _unlock() => context.go(AppRoutes.onboardingActivate);

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedImagesProvider);
    final swipe = ref.watch(swipeControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    if (saved.isEmpty) {
      return _ZeroSavedView(onCta: _unlock, scheme: scheme);
    }

    final total = ref.watch(generationControllerProvider).images.length;
    final ctaLabel =
        'Unlock my ${saved.length} '
        'photo${saved.length == 1 ? '' : 's'} in HD';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            const _BackgroundShapes(),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 108),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusPill(scheme: scheme),
                  const SizedBox(height: 18),
                  _Headline(scheme: scheme),
                  const SizedBox(height: 12),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: Text(
                        'You kept ${saved.length} of $total preview shots. '
                        'Here is your catalog in HD, once you unlock it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _StatRow(
                    kept: saved.length,
                    matchRate: swipe.matchRatePercent,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel('Your shots', scheme: scheme),
                  const SizedBox(height: 14),
                  _SavedGrid(urls: [for (final s in saved) s.url]),
                  const SizedBox(height: 28),
                  _SectionLabel('In context', scheme: scheme),
                  const SizedBox(height: 14),
                  _StoreContextMockup(heroUrl: saved.first.url, scheme: scheme),
                  const SizedBox(height: 28),
                  _SectionLabel('The math', scheme: scheme),
                  const SizedBox(height: 14),
                  _MathCard(keptCount: saved.length, scheme: scheme),
                  const SizedBox(height: 22),
                  const _UseCasePills(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _StickyBar(
                label: ctaLabel,
                onTap: _unlock,
                scheme: scheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
