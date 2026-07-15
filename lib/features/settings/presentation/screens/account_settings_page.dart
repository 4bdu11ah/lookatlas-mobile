part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _SettingsPage extends ConsumerWidget {
  const _SettingsPage({required this.onToast, required this.onLogOut});

  final ValueChanged<String> onToast;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_accountSettingsControllerProvider);
    return _Stack(
      children: [
        const _PageHeader(
          title: 'Settings',
          body: 'Account settings and profile details.',
        ),
        _Card(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: _SectionTitle('Profile'),
              ),
              const SizedBox(height: 4),
              _Caption(state.profileLabel),
              const SizedBox(height: 12),
              const _InputLike('Atlas Studio', label: 'Company Name'),
              const SizedBox(height: 12),
              const _InputLike('alex@example.com', label: 'Email'),
              const SizedBox(height: 12),
              _Button(
                label: 'Save Changes',
                full: true,
                onTap: () => onToast('Settings saved'),
              ),
            ],
          ),
        ),
        _Card(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: _SectionTitle('Account'),
              ),
              const SizedBox(height: 4),
              _Caption(state.notificationLabel),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Created'),
                  _Caption('Jan 17, 2026'),
                ],
              ),
              const SizedBox(height: 12),
              _Button.secondary(label: 'Log Out', full: true, onTap: onLogOut),
            ],
          ),
        ),
      ],
    );
  }
}
