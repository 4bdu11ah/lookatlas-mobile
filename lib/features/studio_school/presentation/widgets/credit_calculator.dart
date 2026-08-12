import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

class CreditCalculator extends StatefulWidget {
  const CreditCalculator({super.key});

  @override
  State<CreditCalculator> createState() => _CreditCalculatorState();
}

class _CreditCalculatorState extends State<CreditCalculator> {
  double _shots = 5;
  double _variations = 3;

  @override
  Widget build(BuildContext context) {
    final images = _shots.toInt() * _variations.toInt();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          _CalculatorSlider(
            label: 'Shots',
            value: _shots,
            max: 10,
            onChanged: (value) => setState(() => _shots = value),
          ),
          _CalculatorSlider(
            label: 'Variations',
            value: _variations,
            max: 5,
            onChanged: (value) => setState(() => _variations = value),
          ),
          const Divider(color: AppColors.neutral200),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_shots.toInt()} x ${_variations.toInt()} = $images images. '
              'Starter example, standard: $images credits. 2K: ${images * 2}.',
              key: const ValueKey('studio-school-credit-math'),
              style: const TextStyle(
                fontSize: 11,
                height: 1.45,
                fontWeight: AppTypography.medium,
              ),
            ),
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral500,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: max,
            divisions: max.toInt() - 1,
            activeColor: AppColors.black,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 22,
          child: Text(
            '${value.toInt()}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
      ],
    );
  }
}
