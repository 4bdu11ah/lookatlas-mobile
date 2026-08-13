part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _DialogUpload extends StatelessWidget {
  const _DialogUpload({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.neutral250,
                width: 2,
              ),
            ),
            child: const Column(
              children: [
                Icon(Icons.upload_outlined, size: 24),
                SizedBox(height: 6),
                _CardTitle('Click to upload'),
                _Caption('PNG, JPG up to 10MB'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageReportReason extends Notifier<String> {
  @override
  String build() => 'product_deformed';

  void select(String reason) {
    if (state == reason) return;
    state = reason;
  }
}

class _ImageReportComment extends Notifier<String> {
  @override
  String build() => '';

  void update(String comment) {
    if (state == comment) return;
    state = comment;
  }
}

final NotifierProvider<_ImageReportReason, String> _imageReportReasonProvider =
    NotifierProvider.autoDispose<_ImageReportReason, String>(
      _ImageReportReason.new,
    );
final NotifierProvider<_ImageReportComment, String>
_imageReportCommentProvider =
    NotifierProvider.autoDispose<_ImageReportComment, String>(
      _ImageReportComment.new,
    );

Future<void> _showImageReportDialog(
  BuildContext context,
  _ShootDetailController controller,
  ShootImage image,
) async {
  await showAppDialog<void>(
    context: context,
    title: 'Report image quality',
    subtitle: 'Describe the issue so our team can review it.',
    icon: Icons.flag_outlined,
    showCloseButton: false,
    barrierDismissible: false,
    builder: (_) => const _ImageReportBody(),
    footer: _ImageReportFooter(
      pageContext: context,
      controller: controller,
      image: image,
    ),
  );
}

class _ImageReportBody extends ConsumerWidget {
  const _ImageReportBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedReason = ref.watch(_imageReportReasonProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            labelText: 'What is wrong?',
            hintText: 'At least 20 characters',
            maxLines: 5,
            onChanged: (comment) =>
                ref.read(_imageReportCommentProvider.notifier).update(comment),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Report reason'),
          const SizedBox(height: 8),
          _ImageReportReasonTile(
            key: const ValueKey('report-reason-product'),
            label: 'Product deformation',
            icon: Icons.inventory_2_outlined,
            selected: selectedReason == 'product_deformed',
            onTap: () => ref
                .read(_imageReportReasonProvider.notifier)
                .select('product_deformed'),
          ),
          const SizedBox(height: 8),
          _ImageReportReasonTile(
            key: const ValueKey('report-reason-model'),
            label: 'Model deformation',
            icon: Icons.person_outline,
            selected: selectedReason == 'model_deformed',
            onTap: () => ref
                .read(_imageReportReasonProvider.notifier)
                .select('model_deformed'),
          ),
        ],
      ),
    );
  }
}

class _ImageReportReasonTile extends StatelessWidget {
  const _ImageReportReasonTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.neutral100 : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.black : AppColors.neutral200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Expanded(child: _CardTitle(label, fontSize: 14)),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageReportFooter extends ConsumerWidget {
  const _ImageReportFooter({
    required this.pageContext,
    required this.controller,
    required this.image,
  });

  final BuildContext pageContext;
  final _ShootDetailController controller;
  final ShootImage image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      _shootDetailControllerProvider.select((state) => state.isActionRunning),
    );
    final reason = ref.watch(_imageReportReasonProvider);
    final comment = ref.watch(_imageReportCommentProvider);
    return AppDialogActionFooter(
      primaryLabel: 'Report image',
      primaryIcon: Icons.flag_outlined,
      primaryButtonKey: const ValueKey('report-image-submit'),
      isLoading: isLoading,
      onCancel: isLoading ? null : () => Navigator.pop(context),
      onPrimary: () => _submitImageReport(
        context: pageContext,
        dialogContext: context,
        controller: controller,
        image: image,
        reason: reason,
        comment: comment,
      ),
    );
  }
}

Future<void> _submitImageReport({
  required BuildContext context,
  required BuildContext dialogContext,
  required _ShootDetailController controller,
  required ShootImage image,
  required String reason,
  required String comment,
}) async {
  final failure = await controller.reportImage(
    image: image,
    reason: reason,
    comment: comment,
  );
  if (!context.mounted) return;
  if (failure != null) {
    AppSnackBar.showError(context, failure.message);
    return;
  }
  if (dialogContext.mounted) Navigator.pop(dialogContext);
  AppSnackBar.show(context, 'Quality report submitted');
}

class _AiEditPrompt extends Notifier<String> {
  @override
  String build() => '';

  void update(String prompt) {
    if (state == prompt) return;
    state = prompt;
  }
}

final NotifierProvider<_AiEditPrompt, String> _aiEditPromptProvider =
    NotifierProvider.autoDispose<_AiEditPrompt, String>(_AiEditPrompt.new);

Future<void> _showAiEditDialog(
  BuildContext context, {
  required ValueChanged<String> onToast,
}) => showAppDialog<void>(
  context: context,
  title: 'Edit with AI',
  icon: Icons.auto_fix_high,
  barrierDismissible: false,
  builder: (_) => const _AiEditDialog(),
  footer: _AiEditDialogFooter(pageContext: context, onToast: onToast),
);

class _AiEditDialog extends ConsumerWidget {
  const _AiEditDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = ref.watch(
      _shootDetailControllerProvider.select(
        (state) => state.selectedImage?.url ?? '',
      ),
    );
    final prompt = ref.watch(_aiEditPromptProvider);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 230,
            child: ColoredBox(
              color: AppColors.neutralLight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _AssetImage(imageUrl),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _BodyText(
                  'Describe what you would like to change. Be specific about the edit you want.',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  labelText: 'Edit prompt',
                  hintText:
                      'e.g., Remove the shadow on the left side, make the model smile more, change the background to pure white...',
                  minLines: 5,
                  maxLines: 5,
                  onChanged: (value) =>
                      ref.read(_aiEditPromptProvider.notifier).update(value),
                ),
                const SizedBox(height: 8),
                _Caption('${_aiEditWordCount(prompt)} / 500 words'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiEditDialogFooter extends ConsumerWidget {
  const _AiEditDialogFooter({
    required this.pageContext,
    required this.onToast,
  });

  final BuildContext pageContext;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      _shootDetailControllerProvider.select((state) => state.isActionRunning),
    );
    final controller = ref.read(_shootDetailControllerProvider.notifier);
    final prompt = ref.watch(_aiEditPromptProvider);
    final isValid = prompt.trim().isNotEmpty && _aiEditWordCount(prompt) <= 500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Caption('Credits will be charged based on image resolution'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                label: 'Cancel',
                onPressed: isLoading ? null : () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                key: const ValueKey('ai-edit-submit'),
                label: 'Apply Edit',
                icon: Icons.auto_fix_high,
                isLoading: isLoading,
                onPressed: isValid
                    ? () => _submitAiEdit(
                        pageContext: pageContext,
                        dialogContext: context,
                        controller: controller,
                        prompt: prompt,
                        onToast: onToast,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

int _aiEditWordCount(String prompt) {
  final trimmedPrompt = prompt.trim();
  if (trimmedPrompt.isEmpty) return 0;
  return trimmedPrompt.split(RegExp(r'\s+')).length;
}

Future<void> _submitAiEdit({
  required BuildContext pageContext,
  required BuildContext dialogContext,
  required _ShootDetailController controller,
  required String prompt,
  required ValueChanged<String> onToast,
}) async {
  final failure = await controller.editImage(prompt.trim());
  if (!pageContext.mounted) return;
  if (failure != null) {
    AppSnackBar.showError(pageContext, failure.message);
    return;
  }
  if (dialogContext.mounted) Navigator.pop(dialogContext);
  onToast('AI edit started');
}
