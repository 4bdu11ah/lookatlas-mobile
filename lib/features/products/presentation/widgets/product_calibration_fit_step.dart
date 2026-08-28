part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CalibrationWornStep extends StatelessWidget {
  const _CalibrationWornStep({
    required this.onBack,
    required this.onUpload,
    required this.isUploading,
  });

  final VoidCallback onBack;
  final VoidCallback onUpload;
  final bool isUploading;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _StepIndicator(current: 'Step 1', label: '2: Photo'),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionCopy(
                title: 'Upload a photo of the product being worn',
                copy:
                    'Any photo of the product on a person will do, even rough phone shots. We only use it to measure size.',
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: isUploading ? null : onUpload,
                child: AppDottedBorder(
                  color: AppColors.neutral200,
                  strokeWidth: 2,
                  dotWidth: 8,
                  gap: 6,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 220),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isUploading)
                            const BarSpinner(
                              size: 28,
                              color: AppColors.black,
                            )
                          else
                            const Icon(
                              Icons.photo_camera_outlined,
                              size: 26,
                              color: AppColors.neutral500,
                            ),
                          const SizedBox(height: 10),
                          Text(
                            isUploading
                                ? 'Uploading photo'
                                : 'Tap to choose a photo',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'JPG, PNG, or WebP up to 20 MB',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Do not have a worn photo? Go back and place the product on a body outline instead.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
      _ProductFlowFooter(onBack: onBack, showPrimary: false),
    ],
  );
}

class _CalibrationFitStep extends StatefulWidget {
  const _CalibrationFitStep({
    required this.bodyPreset,
    required this.renders,
    required this.feedbackController,
    required this.isMutating,
    required this.onBodyPresetChanged,
    required this.onRender,
    required this.onRegenerate,
    required this.onApprove,
    required this.onSelectRender,
    required this.onBack,
  });

  final String bodyPreset;
  final List<CalibrationRender> renders;
  final TextEditingController feedbackController;
  final bool isMutating;
  final ValueChanged<String> onBodyPresetChanged;
  final VoidCallback onRender;
  final VoidCallback onRegenerate;
  final VoidCallback onApprove;
  final ValueChanged<CalibrationRender> onSelectRender;
  final VoidCallback onBack;

  @override
  State<_CalibrationFitStep> createState() => _CalibrationFitStepState();
}

class _CalibrationFitStepState extends State<_CalibrationFitStep> {
  String? _loadedRenderId;

  void _markLoaded(String renderId) {
    if (!mounted || _loadedRenderId == renderId) return;
    setState(() => _loadedRenderId = renderId);
  }

  @override
  Widget build(BuildContext context) {
    final render = widget.renders.firstOrNull;
    return Column(
      children: [
        const _StepIndicator(current: 'Step 3', label: '4: Fit'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionCopy(
                title: 'Check the fit on a real body',
                copy:
                    'We turn your placement into a photo at that exact size. Approve only after the completed image loads correctly.',
              ),
              const SizedBox(height: 18),
              const _Kicker('Body'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final preset in const ['Female', 'Male', 'Unisex']) ...[
                    Expanded(
                      child: _FitPreset(
                        label: preset,
                        selected: widget.bodyPreset == preset,
                        onTap: widget.isMutating
                            ? null
                            : () => widget.onBodyPresetChanged(preset),
                      ),
                    ),
                    if (preset != 'Unisex') const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 360,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutral100Alpha68,
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: _FitPreview(
                  render: render,
                  onLoaded: render == null
                      ? null
                      : () => _markLoaded(render.id),
                ),
              ),
              if (render == null ||
                  render.status == CalibrationRenderStatus.failed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PrimaryButton(
                    label: render == null
                        ? 'Generate Fit, 1 credit'
                        : 'Retry Fit',
                    onPressed: widget.isMutating ? null : widget.onRender,
                    height: 44,
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                  ),
                ),
              if (render?.status == CalibrationRenderStatus.completed) ...[
                const SizedBox(height: 14),
                AppTextField(
                  controller: widget.feedbackController,
                  labelText: 'Regeneration feedback',
                  hintText: 'Describe what needs adjustment.',
                  maxLength: 300,
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                AppOutlinedButton(
                  label: 'Regenerate, 1 credit',
                  icon: Icons.refresh,
                  onPressed: widget.isMutating ? null : widget.onRegenerate,
                  height: 44,
                ),
              ],
              if (widget.renders.length > 1) ...[
                const SizedBox(height: 22),
                const _Kicker('Fit history'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.renders.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = widget.renders[index];
                      return InkWell(
                        onTap: () => widget.onSelectRender(item),
                        child: Container(
                          width: 72,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: index == 0
                                  ? AppColors.black
                                  : AppColors.neutral200,
                              width: index == 0 ? 2 : 1,
                            ),
                          ),
                          child: item.imageUrl == null
                              ? Center(
                                  child: Text(
                                    item.status.name,
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                )
                              : _AssetImage(item.imageUrl!),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        _ProductFlowFooter(
          onBack: widget.onBack,
          primaryLabel: 'Approve & use',
          onPrimary:
              (render?.isApprovalEligible ?? false) &&
                  _loadedRenderId == render?.id &&
                  !widget.isMutating
              ? widget.onApprove
              : null,
        ),
      ],
    );
  }
}

class _FitPreset extends StatelessWidget {
  const _FitPreset({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.neutral100 : AppColors.white,
        border: Border.all(
          color: selected ? AppColors.black : AppColors.neutral200,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: AppTypography.bold),
      ),
    ),
  );
}

class _FitPreview extends StatelessWidget {
  const _FitPreview({required this.render, required this.onLoaded});

  final CalibrationRender? render;
  final VoidCallback? onLoaded;

  @override
  Widget build(BuildContext context) {
    if (render == null) {
      return const Text(
        'Ready to generate your Fit.',
        style: TextStyle(color: AppColors.neutral500),
      );
    }
    if (render!.status.isPending) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BarSpinner(color: AppColors.black),
          SizedBox(height: 12),
          Text('Fit is being rendered'),
        ],
      );
    }
    if (render!.status == CalibrationRenderStatus.failed) {
      return const Text('Fit failed. Retry when ready.');
    }
    return AppImage(
      render!.imageUrl ?? '',
      fit: BoxFit.cover,
      onImageLoaded: onLoaded,
      errorWidget: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
