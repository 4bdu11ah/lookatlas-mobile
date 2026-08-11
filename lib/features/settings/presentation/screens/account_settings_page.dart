part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppFeatureScaffold(
      backgroundColor: AppColors.neutral50,
      title: 'Settings',
      child: _SettingsPage(),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth <= 350;
        final pagePadding = compact ? 14.0 : 16.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            pagePadding,
            16,
            pagePadding,
            16,
          ),
          children: [
            const _SettingsPageHeader(),
            const SizedBox(height: 32),
            _SettingsAccountCard(compact: compact),
          ],
        );
      },
    );
  }
}

class _SettingsPageHeader extends StatelessWidget {
  const _SettingsPageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure your account and application preferences',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _SettingsAccountCard extends StatelessWidget {
  const _SettingsAccountCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 20.0 : 24.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                const _SettingsTitleIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),
          Padding(
            padding: EdgeInsets.all(padding),
            child: _SettingsAccountBody(compact: compact),
          ),
        ],
      ),
    );
  }
}

class _SettingsTitleIcon extends StatelessWidget {
  const _SettingsTitleIcon();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.black,
      child: SizedBox.square(
        dimension: 40,
        child: Icon(Icons.person_outline, size: 20, color: AppColors.white),
      ),
    );
  }
}
