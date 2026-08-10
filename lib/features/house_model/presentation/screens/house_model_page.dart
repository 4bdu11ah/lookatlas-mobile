part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class HouseModelsScreen extends ConsumerWidget {
  const HouseModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFeatureScaffold(
      title: 'House Models',
      contentBackgroundColor: AppColors.neutral50,
      maxContentWidth: 440,
      floatingActionButton: AppFloatingActionButton(
        key: const ValueKey('add-model-fab'),
        label: 'Add Model',
        icon: Icons.people_alt_outlined,
        onPressed: () => _showModelFormDialog(
          context,
          ref,
          (text) => _toastDashboard(context, text),
        ),
      ),

      child: RefreshIndicator(
        onRefresh: ref.read(_houseModelControllerProvider.notifier).reload,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
          child: _HouseModelPage(
            onToast: (text) => _toastDashboard(context, text),
          ),
        ),
      ),
    );
  }
}

class _HouseModelPage extends ConsumerWidget {
  const _HouseModelPage({required this.onToast, this.onOpenModal});

  final ValueChanged<String> onToast;
  final ValueChanged<_ModalKind>? onOpenModal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_houseModelControllerProvider);
    if (state.failure != null &&
        state.libraryModels.isEmpty &&
        state.userModels.isEmpty) {
      return _HouseModelsLoadError(
        message: state.failure!.message,
        onRetry: ref.read(_houseModelControllerProvider.notifier).reload,
      );
    }
    return _Column(
      children: [
        if (state.failure != null)
          _HouseModelsRefreshError(
            message: state.failure!.message,
            onRetry: ref.read(_houseModelControllerProvider.notifier).reload,
          ),
        Text(
          'Manage your brand models for consistent on-model imagery.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _HouseModelsRefreshError extends StatelessWidget {
  const _HouseModelsRefreshError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.neutral100,
      child: Row(
        children: [
          const Icon(
            Icons.sync_problem_outlined,
            size: 20,
            color: AppColors.neutral500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not refresh models. Displayed data may be outdated. $message',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => unawaited(onRetry()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _HouseModelsLoadError extends StatelessWidget {
  const _HouseModelsLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 38,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load house models',
              style: TextStyle(
                fontSize: 18,
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral500),
            ),
            const SizedBox(height: 18),
            AppOutlinedButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: () => unawaited(onRetry()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAiButton extends ConsumerWidget {
  const _CreateAiButton({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppOutlinedButton(
      label: 'Create with AI',
      icon: Icons.auto_awesome,
      onPressed: () => _showAiSheet(context, ref, onToast),
    );
  }
}
