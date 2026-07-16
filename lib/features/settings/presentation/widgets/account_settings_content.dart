part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _SettingsAccountBody extends ConsumerWidget {
  const _SettingsAccountBody({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_accountSettingsControllerProvider);
    return switch (state.status) {
      _AccountSettingsStatus.loading => _SettingsSkeletonList(
        compact: compact,
      ),
      _AccountSettingsStatus.error => _SettingsErrorBox(
        message: state.errorMessage ?? 'Failed to load settings',
      ),
      _AccountSettingsStatus.loaded => _SettingsInfoList(
        state: state,
        compact: compact,
      ),
    };
  }
}

class _SettingsInfoList extends StatelessWidget {
  const _SettingsInfoList({required this.state, required this.compact});

  final _AccountSettingsState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final companyName = state.companyName;
    final email = state.email;
    return Column(
      children: [
        _SettingsInfoRow(
          icon: Icons.business_outlined,
          label: 'COMPANY NAME',
          value: companyName == null || companyName.isEmpty ? '-' : companyName,
          compact: compact,
        ),
        const SizedBox(height: 16),
        _SettingsInfoRow(
          icon: Icons.mail_outline,
          label: 'EMAIL ADDRESS',
          value: email == null || email.isEmpty ? '-' : email,
          compact: compact,
        ),
        const SizedBox(height: 16),
        _SettingsPlanRow(state: state, compact: compact),
        const SizedBox(height: 16),
        _SettingsInfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'MEMBER SINCE',
          value: state.memberSince,
          compact: compact,
        ),
      ],
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 14.0 : 16.0;
    final gap = compact ? 12.0 : 16.0;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha68,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsRowIcon(icon: icon),
          SizedBox(width: gap),
          Expanded(
            child: _SettingsInfoCopy(label: label, value: value),
          ),
        ],
      ),
    );
  }
}

class _SettingsPlanRow extends StatelessWidget {
  const _SettingsPlanRow({required this.state, required this.compact});

  final _AccountSettingsState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 14.0 : 16.0;
    final gap = compact ? 12.0 : 16.0;
    return Container(
      padding: EdgeInsets.all(padding),
      color: AppColors.black,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsRowIcon(
            icon: Icons.verified_outlined,
            inverted: true,
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT PLAN',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.33,
                    fontWeight: AppTypography.medium,
                    color: AppColors.whiteAlpha60,
                  ),
                ),
                const SizedBox(height: 4),
                if (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsPlanName(state.plan),
                      _SettingsPlanPrice(state.planPrice),
                    ],
                  )
                else
                  Row(
                    children: [
                      _SettingsPlanName(state.plan),
                      const SizedBox(width: 8),
                      _SettingsPlanPrice(state.planPrice),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPlanName extends StatelessWidget {
  const _SettingsPlanName(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: AppTypography.bold,
        color: AppColors.white,
      ),
    );
  }
}

class _SettingsPlanPrice extends StatelessWidget {
  const _SettingsPlanPrice(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 14,
        height: 1.43,
        fontWeight: AppTypography.bold,
        color: AppColors.whiteAlpha70,
      ),
    );
  }
}

class _SettingsRowIcon extends StatelessWidget {
  const _SettingsRowIcon({required this.icon, this.inverted = false});

  final IconData icon;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: inverted ? AppColors.white : AppColors.neutral200,
        ),
      ),
      child: Icon(icon, size: 20, color: AppColors.black),
    );
  }
}

class _SettingsInfoCopy extends StatelessWidget {
  const _SettingsInfoCopy({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            height: 1.33,
            fontWeight: AppTypography.medium,
            color: AppColors.neutral500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: AppTypography.bold,
          ),
        ),
      ],
    );
  }
}

class _SettingsSkeletonList extends StatelessWidget {
  const _SettingsSkeletonList({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 4; index++) ...[
          _SettingsSkeletonRow(compact: compact),
          if (index != 3) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SettingsSkeletonRow extends StatelessWidget {
  const _SettingsSkeletonRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 14.0 : 16.0;
    final gap = compact ? 12.0 : 16.0;
    return Container(
      key: const ValueKey('settings-skeleton-row'),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsSkeleton(width: 40, height: 40),
          SizedBox(width: gap),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsSkeleton(width: 112, height: 16),
                SizedBox(height: 8),
                _SettingsSkeleton(width: 192, height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: ColoredBox(
        color: AppColors.neutral250,
        child: SizedBox(width: double.infinity, height: height),
      ),
    );
  }
}

class _SettingsErrorBox extends StatelessWidget {
  const _SettingsErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Error Loading Settings',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: AppTypography.bold,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.43,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
