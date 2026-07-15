part of '../screens/dashboard_screen.dart';

enum _AlertKind { info, warn, error }

class _Alert extends StatelessWidget {
  const _Alert({required this.kind, required this.text});

  final _AlertKind kind;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = switch (kind) {
      _AlertKind.info => (
        AppColors.infoLight,
        AppColors.infoBorder,
        AppColors.infoDark,
        Icons.info_outline,
      ),
      _AlertKind.warn => (
        AppColors.warningLight,
        AppColors.warningBorder,
        AppColors.warningDark,
        Icons.warning_amber_outlined,
      ),
      _AlertKind.error => (
        AppColors.dangerLight,
        AppColors.dangerBorder,
        AppColors.dangerDark,
        Icons.error_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.$1,
        border: Border.all(color: colors.$2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(colors.$4, size: 18, color: colors.$3),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.4, color: colors.$3),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BadgeKind { neutral, dark, success, warn }

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.kind = _BadgeKind.neutral});

  final String label;
  final _BadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = switch (kind) {
      _BadgeKind.neutral => (
        AppColors.neutral100,
        AppColors.neutral200,
        AppColors.neutral500,
      ),
      _BadgeKind.dark => (AppColors.black, AppColors.black, AppColors.white),
      _BadgeKind.success => (
        AppColors.successLight,
        AppColors.successBorder,
        AppColors.successDark,
      ),
      _BadgeKind.warn => (
        AppColors.warningLight,
        AppColors.warningBorder,
        AppColors.warningDark,
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$1,
        border: Border.all(color: colors.$2),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          height: 1.3,
          fontWeight: AppTypography.bold,
          color: colors.$3,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    return _Badge(
      status[0].toUpperCase() + status.substring(1),
      kind: switch (status) {
        'completed' => _BadgeKind.success,
        'processing' => _BadgeKind.dark,
        _ => _BadgeKind.warn,
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
    this.secondary = false,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            color: AppColors.neutral100,
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 14),
          _SectionTitle(title),
          const SizedBox(height: 8),
          _BodyText(body, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          if (secondary)
            _Button.secondary(label: buttonLabel, onTap: onTap)
          else
            _Button(label: buttonLabel, onTap: onTap),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, [this.caption]);

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(label),
          const SizedBox(height: 4),
          _CardTitle(value),
          if (caption != null) ...[
            const SizedBox(height: 4),
            _Caption(caption!),
          ],
        ],
      ),
    );
  }
}
