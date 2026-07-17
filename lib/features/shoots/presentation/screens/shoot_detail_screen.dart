part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class ShootDetailScreen extends ConsumerWidget {
  const ShootDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: CustomAppBar(
        title: 'Shoot Detail',
        showBackButton: true,
        onBack: () => _closeShootDetail(context),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: _ShootDetailContent(
                onOpenModal: (kind) => _openDashboardModal(context, ref, kind),
                onToast: (text) => AppSnackBar.show(context, text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _closeShootDetail(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(AppRoutes.dashboardShoots);
}

class _ShootDetailContent extends ConsumerWidget {
  const _ShootDetailContent({
    required this.onOpenModal,
    required this.onToast,
  });

  final ValueChanged<_ModalKind> onOpenModal;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_shootsControllerProvider);
    final controller = ref.read(_shootsControllerProvider.notifier);
    final shoot = state.selectedShoot;
    if (shoot.status == 'failed') {
      return _FailedShootDetail(
        shoot: shoot,
        onToast: onToast,
      );
    }
    final isProcessing = shoot.status == 'processing';
    return _Stack(
      gap: 14,
      children: [
        _PageHeader(
          title: shoot.name,
          body: 'Generated images for Mila',
          small: true,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _StatusBadge(shoot.status),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AppOutlinedButton(
                label: 'Refresh Status',
                icon: Icons.refresh,
                fitToContent: true,
                height: 36,
                onPressed: () => onToast('Shoot refreshed'),
              ),
              const SizedBox(width: 8),
              if (isProcessing)
                AppOutlinedButton(
                  label: 'Cancel Job',
                  icon: Icons.close,
                  fitToContent: true,
                  height: 36,
                  onPressed: () => onToast('Cancellation requested'),
                )
              else ...[
                AppOutlinedButton(
                  label: 'Export',
                  icon: Icons.download_outlined,
                  fitToContent: true,
                  height: 36,
                  onPressed: () => onToast('Export started'),
                ),
                const SizedBox(width: 8),
                AppOutlinedButton(
                  label: 'CSV Only',
                  fitToContent: true,
                  height: 36,
                  onPressed: () => onToast('CSV export started'),
                ),
              ],
            ],
          ),
        ),
        if (isProcessing) _ShootProgress(progress: shoot.progress),
        _ShootSummary(shoot: shoot),
        if (!isProcessing)
          AppOutlinedButton(
            label: 'Calibrate Product',
            icon: Icons.tune,
            onPressed: () => onOpenModal(_ModalKind.calibration),
          ),
        _VideoCard(
          enabled: !isProcessing,
          onTap: () => onOpenModal(_ModalKind.videoOptions),
        ),
        _GeneratedImages(
          isProcessing: isProcessing,
          assets: state.shotAssets,
          approvedAssets: state.approvedAssets,
          onApprove: controller.toggleApproval,
          onPreview: (_) => onOpenModal(_ModalKind.imagePreview),
          onEdit: () => onOpenModal(_ModalKind.editAi),
          onVersions: () => onOpenModal(_ModalKind.versions),
          onVariation: () => onOpenModal(_ModalKind.variation),
          onDownload: () => onToast('Image download started'),
        ),
      ],
    );
  }
}
