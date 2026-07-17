part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootDialog extends StatelessWidget {
  const _ShootDialog({
    required this.kind,
    required this.onNavigate,
    required this.onOpenModal,
    required this.onToast,
  });

  final _ModalKind kind;
  final ValueChanged<_DashboardPage> onNavigate;
  final ValueChanged<_ModalKind> onOpenModal;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _ModalKind.contextPaywall => _ShootPaywall(
        onNavigate: onNavigate,
      ),
      _ModalKind.product => _AddProductDialog(
        onCrop: () => onOpenModal(_ModalKind.cropProduct),
        onToast: onToast,
      ),
      _ModalKind.cropProduct => _CropProductDialog(onToast: onToast),
      _ModalKind.productSubtype => const _ProductSubtypeDialog(),
      _ModalKind.model => _AddModelDialog(onToast: onToast),
      _ModalKind.directorPortfolio => _DirectorPortfolioDialog(
        onPreview: () => onOpenModal(_ModalKind.portfolioViewer),
      ),
      _ModalKind.portfolioViewer => const _PortfolioViewer(),
      _ModalKind.customShot => _CustomShotDialog(onToast: onToast),
      _ModalKind.imagePreview => const _ImagePreviewDialog(),
      _ModalKind.editAi => _AiEditDialog(onToast: onToast),
      _ModalKind.variation => _VariationDialog(onToast: onToast),
      _ModalKind.versions => _VersionHistoryDialog(onToast: onToast),
      _ModalKind.calibration => const _CalibrationDialog(),
      _ModalKind.videoOptions => _VideoOptionsDialog(
        onNext: () => _replace(context, _ModalKind.videoFrame),
      ),
      _ModalKind.videoFrame => _VideoFrameDialog(
        onBack: () => _replace(context, _ModalKind.videoOptions),
        onNext: () => _replace(context, _ModalKind.videoConfirm),
      ),
      _ModalKind.videoConfirm => _VideoConfirmDialog(
        onBack: () => _replace(context, _ModalKind.videoFrame),
        onToast: onToast,
      ),
      _ModalKind.delete => const SizedBox.shrink(),
    };
  }

  void _replace(BuildContext context, _ModalKind next) {
    Navigator.pop(context);
    onOpenModal(next);
  }
}

class _ShootPaywall extends StatelessWidget {
  const _ShootPaywall({required this.onNavigate});

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
      color: AppColors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _IconButton(
              icon: Icons.close,
              label: 'Close paywall',
              onTap: () => Navigator.pop(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.neutral960),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PRO PLAN',
              style: TextStyle(fontSize: 9, color: AppColors.neutral400),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Spin up another shoot.',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 25,
              height: 1.14,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Get a fresh batch of model-on-product photos every month on Pro, plus AI video on the same shoot.',
            style: TextStyle(
              color: AppColors.neutral400,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const _PaywallBenefit('200 photos every month'),
          const _PaywallBenefit('AI video, cinematic 8-second clips'),
          const _PaywallBenefit('Cancel anytime, one tap'),
          const SizedBox(height: 18),
          AppOutlinedButton(
            label: 'See Pro',
            icon: Icons.arrow_forward,
            iconAlignment: IconAlignment.end,
            onPressed: () {
              Navigator.pop(context);
              onNavigate(_DashboardPage.billing);
            },
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Center(
              child: Text(
                'Not now',
                style: TextStyle(color: AppColors.neutral500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallBenefit extends StatelessWidget {
  const _PaywallBenefit(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddProductDialog extends StatelessWidget {
  const _AddProductDialog({required this.onCrop, required this.onToast});

  final VoidCallback onCrop;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Add New Product',
      subtitle: 'It will also be saved to Products',
      leading: Icons.inventory_2_outlined,
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Add Product',
          icon: Icons.check,
          onPressed: () {
            Navigator.pop(context);
            onToast('Product added');
          },
        ),
      ],
      children: [
        const AppTextField(
          labelText: 'Product name *',
          hintText: 'e.g., Classic Cotton T-Shirt',
        ),
        const AppTextField(labelText: 'SKU *', hintText: 'e.g., TSH-001'),
        const AppTextField(
          labelText: 'Description',
          hintText: 'Describe your product...',
          minLines: 3,
          maxLines: 3,
        ),
        _DialogUpload(label: 'Photos · 0/5', onTap: onCrop),
      ],
    );
  }
}

class _AddModelDialog extends StatelessWidget {
  const _AddModelDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Add New Model',
      subtitle: 'Upload photos and details',
      leading: Icons.person_outline,
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Add Model',
          icon: Icons.check,
          onPressed: () {
            Navigator.pop(context);
            onToast('Model added');
          },
        ),
      ],
      children: const [
        AppTextField(
          labelText: 'Model name *',
          hintText: 'e.g., Sarah Martinez',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(labelText: 'Gender *', hintText: 'Female'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: AppTextField(labelText: 'Height *', hintText: '170 cm'),
            ),
          ],
        ),
        _DialogUpload(label: 'Photos · 0/5'),
      ],
    );
  }
}

class _ProductSubtypeDialog extends StatelessWidget {
  const _ProductSubtypeDialog();

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Pick a sub-type',
      subtitle: 'Helps the AI place the product correctly.',
      showClose: false,
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
      ],
      children: const [
        _OptionWrap(
          options: ['Shoulder bag', 'Crossbody bag', 'Clutch', 'Tote'],
          selected: 0,
        ),
      ],
    );
  }
}

class _CropProductDialog extends StatelessWidget {
  const _CropProductDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 10, 14),
            child: Row(
              children: [
                const Expanded(
                  child: _CreateSectionHeader(
                    title: 'Crop photo',
                    subtitle:
                        'Drag the corners or edges to crop. Drag inside to move it.',
                  ),
                ),
                AppOutlinedButton(
                  label: 'Reset',
                  icon: Icons.refresh,
                  fitToContent: true,
                  height: 36,
                  onPressed: () {},
                ),
                _IconButton(
                  icon: Icons.close,
                  label: 'Close crop',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Expanded(
            child: ColoredBox(
              color: AppColors.nearBlack,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: 0.55,
                          child: _AssetImage(
                            '$_img/showcase-bag-before.jpg',
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 38,
                          ),
                          child: _CropGrid(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(13),
            color: AppColors.neutral50,
            child: Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: PrimaryButton(
                    label: 'Save crop',
                    onPressed: () {
                      Navigator.pop(context);
                      onToast('Crop saved');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropGrid extends StatelessWidget {
  const _CropGrid();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white, width: 2),
      ),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++)
            Expanded(
              child: Row(
                children: [
                  for (var column = 0; column < 3; column++)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: column < 2
                                ? const BorderSide(
                                    color: AppColors.whiteAlpha50,
                                  )
                                : BorderSide.none,
                            bottom: row < 2
                                ? const BorderSide(
                                    color: AppColors.whiteAlpha50,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomShotDialog extends StatelessWidget {
  const _CustomShotDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Create Custom Shot',
      subtitle: 'Describe your vision, we will format it',
      leading: Icons.edit_outlined,
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Add Shot',
          icon: Icons.add,
          onPressed: () {
            Navigator.pop(context);
            onToast('Custom shot added');
          },
        ),
      ],
      children: const [
        AppTextField(
          labelText: "What's your shot idea? *",
          hintText: 'Close-up focusing on the stitching detail...',
          minLines: 4,
          maxLines: 4,
        ),
        _Caption('Be descriptive, this is the main input.'),
        AppTextField(
          labelText: 'Pose Direction (optional)',
          hintText: 'Walking confidently',
        ),
        AppTextField(
          labelText: 'Focus Area (optional)',
          hintText: 'Product detail',
        ),
        _Alert(
          kind: _AlertKind.info,
          text: 'Matches background: Let AI Decide · director: Alex Chen',
        ),
      ],
    );
  }
}
