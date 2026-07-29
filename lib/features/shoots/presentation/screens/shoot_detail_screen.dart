part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class ShootDetailScreen extends ConsumerStatefulWidget {
  const ShootDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ShootDetailScreen> createState() => _ShootDetailScreenState();
}

class _ShootDetailScreenState extends ConsumerState<ShootDetailScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(
        () => ref
            .read(_shootDetailControllerProvider.notifier)
            .load(widget.jobId),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ShootDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobId != widget.jobId) {
      unawaited(
        ref.read(_shootDetailControllerProvider.notifier).load(widget.jobId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final state = ref.watch(_shootDetailControllerProvider);
    final controller = ref.read(_shootDetailControllerProvider.notifier);
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: BarSpinner()),
      );
    }
    final job = state.job;
    if (job == null) {
      return _Card(
        child: _Stack(
          gap: 12,
          children: [
            Text(state.failure?.message ?? 'Could not load this shoot.'),
            AppOutlinedButton(
              label: 'Try again',
              icon: Icons.refresh,
              onPressed: () => unawaited(controller.refresh()),
            ),
          ],
        ),
      );
    }
    final shoot = _Shoot.fromJob(job);
    if (shoot.status == 'failed') {
      return _FailedShootDetail(
        shoot: shoot,
        onRerun: () => _handleAction(
          context,
          controller.rerun,
          'Job queued again',
        ),
        onToast: onToast,
      );
    }
    final isProcessing = job.isActive;
    return _Stack(
      gap: 14,
      children: [
        _PageHeader(
          title: shoot.name,
          body: 'Generated images for ${job.modelName ?? 'your model'}',
          small: true,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _StatusBadge(shoot.status),
        ),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                label: 'Refresh Status',
                icon: Icons.refresh,
                height: 36,
                onPressed: () => _handleAction(
                  context,
                  controller.refresh,
                  'Shoot refreshed',
                ),
              ),
            ),
            if (isProcessing) ...[
              const SizedBox(width: 8),
              Expanded(
                child: AppOutlinedButton(
                  label: 'Cancel Job',
                  icon: Icons.close,
                  height: 36,
                  onPressed: () => _handleAction(
                    context,
                    controller.cancel,
                    'Cancellation requested',
                  ),
                ),
              ),
            ],
          ],
        ),
        if (isProcessing) _ShootProgress(progress: shoot.progress),
        _ShootSummary(shoot: shoot, modelName: job.modelName),
        _VideoCard(
          enabled: !isProcessing,
          onTap: () => onOpenModal(_ModalKind.videoOptions),
        ),
        _GeneratedImages(
          isProcessing: isProcessing,
          shots: _displayShots(job),
          onApprove: (image) => _handleAction(
            context,
            () => controller.toggleApproval(image),
            image.approved ? 'Approval removed' : 'Image approved',
          ),
          onPreview: (image) {
            controller.selectImage(image);
            onOpenModal(_ModalKind.imagePreview);
          },
          onEdit: (image) {
            controller.selectImage(image);
            onOpenModal(_ModalKind.editAi);
          },
          onVersions: (image) async {
            final failure = await controller.loadVersions(image);
            if (!context.mounted) return;
            if (failure != null) {
              AppSnackBar.showError(context, failure.message);
              return;
            }
            onOpenModal(_ModalKind.versions);
          },
          onVariation: (shotIndex) {
            final image = _displayShots(
              job,
            ).firstWhere((shot) => shot.index == shotIndex).images.firstOrNull;
            if (image != null) {
              controller.selectImage(image, shotIndex: shotIndex);
            }
            onOpenModal(_ModalKind.variation);
          },
          onDownload: (image) async {
            final result = await controller.download(image);
            if (!context.mounted) return;
            result.fold(
              (_) => onToast('Image downloaded'),
              (failure) => AppSnackBar.showError(context, failure.message),
            );
          },
        ),
        if (!isProcessing && state.images.isNotEmpty)
          AppOutlinedButton(
            label: 'Redo Hand Shots',
            icon: Icons.pan_tool_outlined,
            onPressed: () => _handleAction(
              context,
              controller.redoHandShots,
              'Hand shot replacement started',
            ),
          ),
      ],
    );
  }
}

List<ShootShot> _displayShots(ShootJob job) {
  if (job.shots.isNotEmpty) return job.shots;
  if (job.images.isEmpty) return const [];
  final grouped = <int, List<ShootImage>>{};
  for (final image in job.images) {
    grouped.putIfAbsent(image.shotIndex, () => []).add(image);
  }
  return [
    for (final entry in grouped.entries)
      ShootShot(
        index: entry.key,
        title: 'Shot ${entry.key + 1}',
        description: '',
        images: entry.value,
      ),
  ];
}

Future<void> _handleAction(
  BuildContext context,
  Future<Failure?> Function() action,
  String successMessage,
) async {
  final failure = await action();
  if (!context.mounted) return;
  if (failure == null) {
    AppSnackBar.show(context, successMessage);
  } else {
    AppSnackBar.showError(context, failure.message);
  }
}
