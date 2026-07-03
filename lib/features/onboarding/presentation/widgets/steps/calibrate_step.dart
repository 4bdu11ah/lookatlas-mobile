import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/onboarding/domain/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/wizard_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Wizard step 3 — proportion calibration for jewelry/bags (mockup 03).
/// Only joins the flow for calibratable categories, and is currently
/// feature-flagged off in the trial ([calibrationEnabledInTrial]).
class CalibrateStep extends ConsumerWidget {
  const CalibrateStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final controller = ref.read(wizardControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final isJewelry = state.category == ProductCategory.jewelry;
    final subtypes = isJewelry ? jewelrySubtypes : bagSubtypes;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          Column(
            children: [
              Icon(Icons.straighten, size: 32, color: scheme.onSurface),
              const SizedBox(height: 12),
              const WizardStepHeader(
                title: 'Calibrate proportions',
                subtitle:
                    'Accessories and jewelry often come out the wrong scale. '
                    'Spend 30 seconds drawing the real size of your product '
                    'on a body outline — the AI will match the proportions '
                    'exactly.',
              ),
            ],
          ),
          _Card(
            child: Column(
              spacing: 12,
              children: [
                Column(
                  spacing: 8,
                  children: [
                    Text(
                      isJewelry
                          ? 'What kind of jewelry is this?'
                          : 'What kind of bag is this?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.43,
                        fontWeight: AppTypography.semiBold,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      'We use this to show the right body outline and preset.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.33,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final subtype in subtypes)
                      _Chip(
                        label: subtype,
                        selected: state.calibrationSubtype == subtype,
                        onTap: () => controller.selectCalibrationSubtype(
                          subtype,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (state.calibrationSaved)
            _Card(
              child: Row(
                spacing: 12,
                children: [
                  const Icon(Icons.check, size: 24, color: Color(0xFF047857)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calibration saved',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.43,
                            fontWeight: AppTypography.semiBold,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          '2 shapes on the '
                          '${state.calibrationSubtype?.toLowerCase() ?? 'body'}'
                          ' outline',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.33,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  WizardButton(
                    label: 'Edit',
                    outlined: true,
                    small: true,
                    onTap: controller.saveCalibration,
                  ),
                ],
              ),
            )
          else
            _Card(
              child: Column(
                spacing: 12,
                children: [
                  Text(
                    'No calibration yet — open the calibration tool to draw '
                    "your product's scale.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.43,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  WizardButton(
                    label: 'Open calibration tool',
                    small: true,
                    onTap: controller.saveCalibration,
                  ),
                ],
              ),
            ),
          Text(
            "Skip for now if you'd rather get your first shoot going — "
            'proportions may be slightly off.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: scheme.outline),
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.onSurface : scheme.surface,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            height: 1.43,
            color: selected ? scheme.surface : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
