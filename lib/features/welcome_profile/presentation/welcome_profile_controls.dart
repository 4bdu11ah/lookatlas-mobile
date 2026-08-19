part of 'welcome_profile_screen.dart';

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(40, 44),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      backgroundColor: selected ? AppColors.black : AppColors.white,
      foregroundColor: selected ? AppColors.white : AppColors.black,
      side: BorderSide(
        color: selected ? AppColors.black : AppColors.neutral200,
        width: 2,
      ),
    ),
    child: Text(label, style: const TextStyle(fontSize: 13)),
  );
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({
    required this.finalStep,
    required this.canContinue,
    required this.submitting,
    required this.onSkip,
    required this.onContinue,
  });

  final bool finalStep;
  final bool canContinue;
  final bool submitting;
  final VoidCallback onSkip;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(24, 8, 24, 22),
    child: Row(
      children: [
        TextButton(
          onPressed: submitting ? null : onSkip,
          child: const Text(
            'Skip for now',
            style: TextStyle(
              color: AppColors.neutral500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const Spacer(),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: canContinue || submitting ? 1 : 0.45,
          child: LoadingIconButton(
            label: finalStep ? 'Enter your studio' : 'Continue',
            isLoading: submitting,
            onPressed: canContinue && !submitting ? onContinue : null,
          ),
        ),
      ],
    ),
  );
}
