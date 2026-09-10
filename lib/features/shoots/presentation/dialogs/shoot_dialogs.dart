part of 'shoot_modal.dart';

class _CustomShotSubmitting extends Notifier<bool> {
  @override
  bool build() => false;

  void _set({required bool value}) {
    if (state == value) return;
    state = value;
  }
}

final NotifierProvider<_CustomShotSubmitting, bool>
_customShotSubmittingProvider =
    NotifierProvider.autoDispose<_CustomShotSubmitting, bool>(
      _CustomShotSubmitting.new,
    );

class _ShootDialog extends StatelessWidget {
  const _ShootDialog({
    required this.kind,
    required this.onOpenBilling,
    required this.onOpenModal,
    required this.onToast,
  });

  final _ShootModalKind kind;
  final VoidCallback onOpenBilling;
  final ValueChanged<_ShootModalKind> onOpenModal;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _ShootModalKind.contextPaywall => _ShootPaywall(
        onOpenBilling: onOpenBilling,
      ),
      _ShootModalKind.product => _AddProductDialog(onToast: onToast),
      _ShootModalKind.model => _AddModelDialog(onToast: onToast),
      _ShootModalKind.directorPortfolio => _DirectorPortfolioDialog(
        onPreview: () => onOpenModal(_ShootModalKind.portfolioViewer),
      ),
      _ShootModalKind.portfolioViewer => const _PortfolioViewer(),
      _ShootModalKind.customShot => _CustomShotDialog(onToast: onToast),
      _ShootModalKind.imagePreview => const _ImagePreviewDialog(),
      _ShootModalKind.editAi => const _AiEditDialog(),
      _ShootModalKind.variation => _VariationDialog(onToast: onToast),
      _ShootModalKind.versions => _VersionHistoryDialog(onToast: onToast),
      _ShootModalKind.videoOptions => _VideoOptionsDialog(
        onNext: () => _replace(context, _ShootModalKind.videoFrame),
      ),
      _ShootModalKind.videoFrame => _VideoFrameDialog(
        onBack: () => _replace(context, _ShootModalKind.videoOptions),
        onNext: () => _replace(context, _ShootModalKind.videoConfirm),
      ),
      _ShootModalKind.videoConfirm => _VideoConfirmDialog(
        onBack: () => _replace(context, _ShootModalKind.videoFrame),
        onToast: onToast,
      ),
    };
  }

  void _replace(BuildContext context, _ShootModalKind next) {
    Navigator.pop(context);
    onOpenModal(next);
  }
}

class _ShootPaywall extends StatelessWidget {
  const _ShootPaywall({required this.onOpenBilling});

  final VoidCallback onOpenBilling;

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
            child: AppTapIconButton(
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
              onOpenBilling();
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

class _CustomShotDialog extends ConsumerStatefulWidget {
  const _CustomShotDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  ConsumerState<_CustomShotDialog> createState() => _CustomShotDialogState();
}

class _CustomShotDialogState extends ConsumerState<_CustomShotDialog> {
  final _ideaFieldKey = GlobalKey<FormFieldState<String>>();
  final _ideaController = TextEditingController();
  final _poseController = TextEditingController();
  final _focusController = TextEditingController();

  @override
  void dispose() {
    _ideaController.dispose();
    _poseController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(createShootControllerProvider.notifier);
    final isSubmitting = ref.watch(_customShotSubmittingProvider);
    final shootContext = ref.watch(
      createShootControllerProvider.select((state) {
        final director = state.directors[state.selectedDirector];
        return (
          background: _customShotBackgroundLabel(state.settings.background),
          directorName: director.name,
        );
      }),
    );
    return AppModalFrame(
      title: 'Create Custom Shot',
      subtitle: "Describe your vision, we'll format it",
      leading: Icons.edit_outlined,
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Add Shot',
          icon: Icons.add,
          isLoading: isSubmitting,
          onPressed: () async {
            final idea = _ideaController.text.trim();
            if (!(_ideaFieldKey.currentState?.validate() ?? false)) return;
            ref.read(_customShotSubmittingProvider.notifier)._set(value: true);
            final failure = await controller.addCustomShot(
              shotIdea: idea,
              poseDirection: _poseController.text.trim(),
              focusArea: _focusController.text.trim(),
            );
            if (!context.mounted) return;
            ref.read(_customShotSubmittingProvider.notifier)._set(value: false);
            if (failure != null) {
              AppSnackBar.showError(context, failure.message);
              return;
            }
            Navigator.pop(context);
            widget.onToast('Custom shot added');
          },
        ),
      ],
      children: [
        AppTextField(
          controller: _ideaController,
          fieldKey: _ideaFieldKey,
          key: const ValueKey('custom-shot-idea'),
          labelText: "What's your shot idea? *",
          hintText: 'Close-up focusing on the stitching detail while model hold the bag casually at her side',
          minLines: 4,
          maxLines: 4,
          validator: (value) => (value?.trim().length ?? 0) <= 10
              ? 'Shot idea must be more than 10 characters.'
              : null,
        ),
        const AppCaption('Be descriptive, this is the main input.'),
        AppTextField(
          controller: _poseController,
          labelText: 'Pose Direction (optional)',
          hintText: "E.g., 'Walking confidently', 'Leaning against wall', 'Sitting cross-legged'",
        ),
        AppTextField(
          controller: _focusController,
          labelText: 'Focus Area (optional)',
          hintText:
              "E.g., 'Product detail', 'Full body', 'Waist up', 'Feet/shoes'",
        ),
        AppAlert(
          kind: AppAlertKind.info,
          richText: TextSpan(
            children: [
              const TextSpan(
                text:
                    'Your custom shot will match the current shoot settings '
                    '(location: ',
              ),
              TextSpan(
                text: shootContext.background,
                style: const TextStyle(color: AppColors.black),
              ),
              const TextSpan(text: ', director: '),
              TextSpan(
                text: shootContext.directorName,
                style: const TextStyle(color: AppColors.black),
              ),
              const TextSpan(text: ')'),
            ],
          ),
        ),
      ],
    );
  }
}

String _customShotBackgroundLabel(String background) => switch (background) {
  'studio' => 'Studio',
  'studio_dark' => 'Studio Dark',
  'street' => 'Street',
  'home' => 'Home',
  _ => 'Let AI Decide',
};
