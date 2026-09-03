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
      const _StepIndicator(current: 1, total: 2, label: 'Photo'),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionCopy(
                title: 'Upload a photo of the product being worn',
                copy: 'Any photo of the product on a person will do, even rough phone shots. We only use it to measure size, not the person.',
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
                    constraints: const BoxConstraints(minHeight: 250),
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
        const _StepIndicator(current: 2, total: 3, label: 'Size'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionCopy(
                title: 'Check the fit on a real body',
                copy: 'We turn your placement into a photo of the product at that exact size on a person. The AI reads its sizing from this photo, so it is worth getting right.',
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
                        description: switch (preset) {
                          'Female' => 'Womenswear, most jewellery',
                          'Male' => 'Menswear, watches',
                          _ => 'Either, or it does not matter',
                        },
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
              const SizedBox(height: 7),
              const Text(
                'This only decides the body in this photo. Your shoots still use whichever model you pick for them.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: AppColors.neutral500,
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Container(
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
              ),
              if (render == null ||
                  render.status == CalibrationRenderStatus.failed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PrimaryButton(
                    label: render == null
                        ? 'Generate ${widget.bodyPreset} Fit (1 credit)'
                        : 'Retry Fit',
                    onPressed: widget.isMutating ? null : widget.onRender,
                    height: 44,
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                  ),
                ),
              if (render?.status == CalibrationRenderStatus.completed) ...[
                const SizedBox(height: 14),
                const Text(
                  'Does the product look the right size on this body?',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 9),
                _CalibrationActionButton(
                  label: 'Approve & use',
                  icon: Icons.check,
                  fullWidth: true,
                  onPressed:
                      render!.isApprovalEligible &&
                          _loadedRenderId == render.id &&
                          !widget.isMutating
                      ? widget.onApprove
                      : null,
                ),
                const SizedBox(height: 9),
                AppTextField(
                  controller: widget.feedbackController,
                  labelText: 'Regeneration feedback',
                  hintText: 'Describe what needs adjustment.',
                  maxLength: 300,
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                _CalibrationActionButton(
                  label: 'Regenerate (1 credit)',
                  icon: Icons.refresh,
                  outlined: true,
                  fullWidth: true,
                  onPressed: widget.isMutating ? null : widget.onRegenerate,
                ),
              ],
              if (widget.renders.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Divider(height: 1),
                const SizedBox(height: 14),
                const Text(
                  'Fit history',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Compare every version and see the note that created it.',
                  style: TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.renders.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = widget.renders[index];
                      return InkWell(
                        onTap: () => widget.onSelectRender(item),
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: index == 0
                                  ? AppColors.black
                                  : AppColors.neutral200,
                              width: index == 0 ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: item.imageUrl == null
                                    ? Center(
                                        child: Text(
                                          item.status.name,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      )
                                    : _AssetImage(item.imageUrl!),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Version ${item.version ?? widget.renders.length - index} · ${item.bodyPreset ?? widget.bodyPreset}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.status == CalibrationRenderStatus.completed
                                    ? 'Ready to review'
                                    : item.status.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ),
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
          showPrimary: false,
        ),
      ],
    );
  }
}

class _FitPreset extends StatelessWidget {
  const _FitPreset({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 65),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: selected ? AppColors.neutral100 : AppColors.white,
        border: Border.all(
          color: selected ? AppColors.black : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.neutral500,
            ),
          ),
        ],
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
        'Nothing rendered yet. Pick a body and generate.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.neutral500,
        ),
      );
    }
    if (render!.status.isPending) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BarSpinner(color: AppColors.black),
          SizedBox(height: 12),
          Text(
            'Rendering. This usually takes two to three minutes. You can leave this open.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.neutral500,
            ),
          ),
        ],
      );
    }
    if (render!.status == CalibrationRenderStatus.failed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Fit failed. Retry when ready.'),
          if (render!.refundStatus != null) ...[
            const SizedBox(height: 6),
            Text(
              render!.refundStatus!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.neutral500,
                fontSize: 11,
              ),
            ),
          ],
        ],
      );
    }
    return AppImage(
      render!.imageUrl ?? '',
      fit: BoxFit.cover,
      onImageLoaded: onLoaded,
      errorWidget: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
