part of 'welcome_profile_screen.dart';

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.semanticLabel,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.hasError = false,
    this.onChanged,
  });

  final String semanticLabel;
  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    textField: true,
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, color: AppColors.black),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: hasError ? AppColors.danger : AppColors.neutral200,
            width: 2,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.black, width: 2),
        ),
      ),
    ),
  );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onPressed,
    this.mutuallyExclusive = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onPressed;
  final bool mutuallyExclusive;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: mutuallyExclusive ? selected : null,
    toggled: mutuallyExclusive ? null : selected,
    inMutuallyExclusiveGroup: mutuallyExclusive,
    child: InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.black : AppColors.neutral200,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.white : AppColors.black,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.black,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: selected
                        ? AppColors.whiteAlpha70
                        : AppColors.neutral500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (selected)
              const Positioned(
                right: 0,
                top: 0,
                child: ColoredBox(
                  color: AppColors.white,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Icon(Icons.check, size: 13, color: AppColors.black),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

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
          child: PrimaryButton(
            label: finalStep ? 'Enter your studio' : 'Continue',
            icon: Icons.arrow_forward,
            iconAlignment: IconAlignment.end,
            fitToContent: true,
            height: 46,
            isLoading: submitting,
            onPressed: canContinue && !submitting ? onContinue : null,
          ),
        ),
      ],
    ),
  );
}
