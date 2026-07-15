import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/director_portfolio_modal.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Wizard step 5 — pick a director / photo style from nine cards, each with a
/// portfolio preview (mockup 05).
class DirectorStep extends ConsumerWidget {
  const DirectorStep({super.key});

  void _showPortfolio(BuildContext context, Director director) {
    unawaited(
      showDirectorPortfolio(context, director: director),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final controller = ref.read(wizardControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
      child: Column(
        spacing: 24,
        children: [
          const WizardStepHeader(
            title: 'What should your photos look like?',
            subtitle:
                'Your director studies your product, plans the shots, decides '
                'on poses, lighting, and composition. Same quality and '
                'creative direction that billion-dollar brands use for their '
                'campaigns.',
          ),
          Column(
            spacing: 12,
            children: [
              for (var i = 0; i < directors.length; i += 2)
                Row(
                  spacing: 12,
                  children: [
                    for (var j = i; j < i + 2; j++)
                      Expanded(
                        child: j < directors.length
                            ? _DirectorCard(
                                director: directors[j],
                                selected:
                                    state.selectedDirector?.id ==
                                    directors[j].id,
                                onTap: () =>
                                    controller.selectDirector(directors[j]),
                                onPortfolio: () =>
                                    _showPortfolio(context, directors[j]),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DirectorCard extends StatelessWidget {
  const _DirectorCard({
    required this.director,
    required this.selected,
    required this.onTap,
    required this.onPortfolio,
  });

  final Director director;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onPortfolio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: selected ? 0.98 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? scheme.onSurface : scheme.outline,
              width: 2,
            ),
          ),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ShotImage(director.imageUrl),
                // Bottom info gradient.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 48, 12, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.blackAlpha90,
                          AppColors.blackAlpha60,
                          AppColors.transparent,
                        ],
                        stops: [0, 0.4, 1],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          director.name,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: AppTypography.semiBold,
                            letterSpacing: -0.14,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          director.tagline,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: AppColors.whiteAlpha70,
                          ),
                        ),
                        Text(
                          'Like ${director.brands}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: AppColors.whiteAlpha60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Portfolio eye button.
                Positioned(
                  top: 6,
                  left: 6,
                  child: Material(
                    color: AppColors.white.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                      side: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: InkWell(
                      onTap: onPortfolio,
                      child: const SizedBox.square(
                        dimension: 36,
                        child: Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: scheme.onSurface,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.blackAlpha25,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: scheme.surface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
