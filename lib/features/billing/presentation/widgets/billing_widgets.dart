part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

String _billingMoney(double value, {bool alwaysShowCents = false}) {
  final whole = value == value.roundToDouble();
  final digits = alwaysShowCents || !whole ? 2 : 0;
  final parts = value.toStringAsFixed(digits).split('.');
  final formatted = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$formatted${parts.length == 2 ? '.${parts.last}' : ''}';
}

class _BillingActionButton extends StatelessWidget {
  const _BillingActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.outline = false,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outline;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final foreground = outline ? AppColors.black : AppColors.white;
    final background = outline ? AppColors.white : AppColors.black;

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Material(
        color: background,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Opacity(
            opacity: onPressed == null ? 0.5 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.black,
                  width: outline ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? ButtonLoader(color: foreground)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 16, color: foreground),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 14,
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingCardHeader extends StatelessWidget {
  const _BillingCardHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Icon(icon, size: 20, color: AppColors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: AppTypography.bold,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingModal extends StatelessWidget {
  const _BillingModal({
    required this.title,
    required this.body,
    this.subtitle,
    this.footer,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? footer;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.4,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close',
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.neutral500,
                  ),
                ),
            ],
          ),
        ),
        const _Hairline(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: body,
          ),
        ),
        if (footer != null) ...[
          const _Hairline(),
          ColoredBox(
            color: AppColors.neutral100,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: footer,
            ),
          ),
        ],
      ],
    );
  }
}

class _BillingNotice extends StatelessWidget {
  const _BillingNotice({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: warning ? AppColors.warningLight : AppColors.neutral100,
        border: Border(
          left: BorderSide(
            color: warning ? AppColors.warning : AppColors.black,
            width: 4,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: warning ? const Color(0xFF713F12) : AppColors.black,
        ),
      ),
    );
  }
}

Future<T?> _showBillingDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 448,
}) {
  return showAppDialog<T>(
    context: context,
    barrierDismissible: false,
    config: AppDialogConfig.standard.copyWith(
      insetPadding: const EdgeInsets.all(16),
      maxWidth: maxWidth,
      maxHeightOffset: 32,
      barrierColor: AppColors.blackAlpha70,
    ),
    builder: builder,
  );
}
