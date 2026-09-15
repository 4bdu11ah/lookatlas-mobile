import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/learning_center_style.dart';

class CreditCalculatorState {
  const CreditCalculatorState({this.shots = 5, this.variations = 3});
  final int shots;
  final int variations;
  int get images => shots * variations;
  int get standardCredits => images;
  int get hdCredits => images * 2;
  int get fourKCredits => images * 3;
  int get businessPacedCredits => 0;
}

class CreditCalculatorController extends Notifier<CreditCalculatorState> {
  @override
  CreditCalculatorState build() => const CreditCalculatorState();
  void setShots(double value) => state = CreditCalculatorState(
    shots: value.round().clamp(1, 10),
    variations: state.variations,
  );
  void setVariations(double value) => state = CreditCalculatorState(
    shots: state.shots,
    variations: value.round().clamp(1, 5),
  );
}

final NotifierProvider<CreditCalculatorController, CreditCalculatorState>
creditCalculatorProvider =
    NotifierProvider.autoDispose<
      CreditCalculatorController,
      CreditCalculatorState
    >(CreditCalculatorController.new);

class CreditCalculator extends ConsumerWidget {
  const CreditCalculator({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creditCalculatorProvider);
    final controller = ref.read(creditCalculatorProvider.notifier);
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3ED),
        border: Border.all(color: LearningCenterStyle.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalculatorSlider(
            label: 'Shots',
            value: state.shots.toDouble(),
            max: 10,
            onChanged: controller.setShots,
          ),
          const SizedBox(height: 13),
          _CalculatorSlider(
            label: 'Variations',
            value: state.variations.toDouble(),
            max: 5,
            onChanged: controller.setVariations,
          ),
          const SizedBox(height: 17),
          const Divider(height: 1, color: LearningCenterStyle.line),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${state.shots} shots × ${state.variations} variations',
                  style: LearningCenterStyle.body(
                    11.5,
                    color: LearningCenterStyle.ink,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${state.images} images',
                key: const ValueKey('studio-school-credit-math'),
                style: LearningCenterStyle.body(
                  11,
                  color: LearningCenterStyle.ink,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            'Standard: ${state.standardCredits} credits • HD: ${state.hdCredits} • 4K: ${state.fourKCredits}. Business Unlimited photos in the paced lane do not use credits.',
            style: LearningCenterStyle.body(11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CalculatorSlider extends StatelessWidget {
  const _CalculatorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 77,
        child: Text(
          label,
          style: LearningCenterStyle.body(11, weight: FontWeight.w700),
        ),
      ),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: SliderComponentShape.noOverlay,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: max,
            divisions: max.toInt() - 1,
            activeColor: LearningCenterStyle.ink,
            onChanged: onChanged,
          ),
        ),
      ),
      SizedBox(
        width: 25,
        child: Text(
          '${value.toInt()}',
          textAlign: TextAlign.right,
          style: LearningCenterStyle.body(
            11,
            color: LearningCenterStyle.ink,
            weight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
