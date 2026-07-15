part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _HouseModelFeatureScaffold extends ConsumerWidget {
  const _HouseModelFeatureScaffold({
    required this.initial,
    required this.onNavigate,
    required this.onToast,
  });

  final String initial;
  final ValueChanged<_DashboardPage> onNavigate;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'House Models',
        showBackButton: true,
      ),
      floatingActionButton: _ModelFab(
        onTap: () => _showModelFormSheet(context, ref, onToast),
      ),

      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ColoredBox(
              color: AppColors.neutral50,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
                child: _HouseModelPage(onToast: onToast),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HouseModelPage extends StatelessWidget {
  const _HouseModelPage({required this.onToast, this.onOpenModal});

  final ValueChanged<String> onToast;
  final ValueChanged<_ModalKind>? onOpenModal;

  @override
  Widget build(BuildContext context) {
    return _Stack(
      children: [
        const Text(
          'Manage your brand models for consistent on-model imagery.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.neutral500,
          ),
        ),
        _CreateAiButton(onToast: onToast),
        const _LibraryModelsSection(),
        const _Hairline(),
        _UserModelsSection(onToast: onToast),
      ],
    );
  }
}

class _CreateAiButton extends ConsumerWidget {
  const _CreateAiButton({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ModelActionButton.secondary(
      label: 'Create with AI',
      icon: Icons.auto_awesome,
      full: true,
      onTap: () => _showAiSheet(context, ref, onToast),
    );
  }
}
