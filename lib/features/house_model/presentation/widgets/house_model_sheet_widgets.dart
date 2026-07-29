part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child, this.title, this.actions = const []});

  final String? title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral250,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (title != null)
              Container(
                height: 68,
                padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.neutral200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: AppTypography.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    _IconButton(
                      icon: Icons.close,
                      label: 'Close',
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                child: child,
              ),
            ),
            if (actions.isNotEmpty) _SheetActionBar(actions: actions),
          ],
        ),
      ),
    );
  }
}

class _InnerHeader extends StatelessWidget {
  const _InnerHeader({
    required this.title,
    required this.onClose,
    this.trailing,
  });

  final String title;
  final VoidCallback onClose;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.chevron_left,
            label: 'Back',
            onTap: onClose,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: AppTypography.bold,
                color: AppColors.black,
              ),
            ),
          ),
          SizedBox.square(dimension: 44, child: trailing),
        ],
      ),
    );
  }
}

class _SheetActionBar extends StatelessWidget {
  const _SheetActionBar({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        13,
        16,
        MediaQuery.paddingOf(context).bottom + 13,
      ),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            Expanded(child: actions[i]),
            if (i != actions.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: AppTypography.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in values)
              _ChoiceChipButton(
                label: labelFor(item),
                selected: item == value,
                onTap: () => onChanged(item),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.black : AppColors.neutral200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: AppTypography.bold,
            color: selected ? AppColors.white : AppColors.neutral500,
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inkAlpha04,
        border: Border.all(color: AppColors.inkAlpha18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.inkAlpha08,
              shape: BoxShape.circle,
            ),
            child: Text(
              icon == Icons.info_outline ? 'i' : '',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: AppTypography.bold,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.neutral800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmIcon extends StatelessWidget {
  const _ConfirmIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      margin: const EdgeInsets.only(bottom: 18),
      color: AppColors.dangerDark,
      alignment: Alignment.center,
      child: const Icon(Icons.delete_outline, size: 25, color: AppColors.white),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: AppColors.dangerDark,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const BarSpinner(size: 18, color: AppColors.white)
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: AppTypography.bold,
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _IntroCopy extends StatelessWidget {
  const _IntroCopy({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 25,
              height: 1.15,
              fontWeight: AppTypography.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}
