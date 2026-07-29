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
              child: RefreshIndicator(
                onRefresh: ref
                    .read(_houseModelControllerProvider.notifier)
                    .reload,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
                  child: _HouseModelPage(onToast: onToast),
                ),
              ),
            ),
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
    if (state.isLoading &&
        state.libraryModels.isEmpty &&
        state.userModels.isEmpty) {
      return const SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_top,
                size: 30,
                color: AppColors.neutral500,
              ),
              SizedBox(height: 10),
              Text(
                'Loading house models...',
                style: TextStyle(color: AppColors.neutral500),
              ),
            ],
          ),
        ),
      );
    }
    if (state.failure != null &&
        state.libraryModels.isEmpty &&
        state.userModels.isEmpty) {
      return _HouseModelsLoadError(
        message: state.failure!.message,
        onRetry: ref.read(_houseModelControllerProvider.notifier).reload,
      );
    }
    return _Stack(
      children: [
        if (state.failure != null)
          _HouseModelsRefreshError(
            message: state.failure!.message,
            onRetry: ref.read(_houseModelControllerProvider.notifier).reload,
          ),
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
            _ModelActionButton.secondary(
              label: 'Retry',
              icon: Icons.refresh,
              onTap: () => unawaited(onRetry()),
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
    return _ModelActionButton.secondary(
      label: 'Create with AI',
      icon: Icons.auto_awesome,
      full: true,
      onTap: () => _showAiSheet(context, ref, onToast),
    );
  }
}
