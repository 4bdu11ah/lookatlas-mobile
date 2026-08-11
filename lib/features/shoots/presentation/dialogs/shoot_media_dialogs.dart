part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _PortfolioIndex extends Notifier<int> {
  @override
  int build() => 0;

  void _set({required int value}) {
    if (state == value) return;
    state = value;
  }
}

final NotifierProvider<_PortfolioIndex, int> _portfolioIndexProvider =
    NotifierProvider.autoDispose<_PortfolioIndex, int>(_PortfolioIndex.new);

class _DirectorPortfolioDialog extends ConsumerWidget {
  const _DirectorPortfolioDialog({required this.onPreview});

  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final director = _selectedShootDirector(ref);
    final assets = _directorAssets(director);
    return _ModalFrame(
      title: director?.name ?? 'Creative Director',
      subtitle: director?.subtitle,
      leading: Icons.person_outline,
      actions: [
        AppOutlinedButton(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Selected',
          icon: Icons.check,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      children: [
        const _FieldLabel('Portfolio'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assets.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) => InkWell(
            key: ValueKey('portfolio-image-$index'),
            onTap: onPreview,
            child: _AssetImage(assets[index]),
          ),
        ),
        const _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow('The story'),
              SizedBox(height: 8),
              _BodyText(
                'Alex built a career on images where clarity is the luxury: clean lines, honest light, and product-first composition.',
              ),
            ],
          ),
        ),
        const _FieldLabel('Style characteristics'),
        const _OptionWrap(
          options: [
            'Clean lighting',
            'Crisp detail',
            'Commercial polish',
            'Product focus',
          ],
          selected: 0,
        ),
      ],
    );
  }
}

class _PortfolioViewer extends ConsumerWidget {
  const _PortfolioViewer();

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final director = _selectedShootDirector(ref);
    final assets = _directorAssets(director);
    final index = ref
        .watch(_portfolioIndexProvider)
        .clamp(0, assets.length - 1);
    return _FullPreview(
      asset: assets[index],
      caption: director?.subtitle,
      counter: '${index + 1} of ${assets.length}',
      actions: [
        _PreviewAction(
          icon: Icons.arrow_back,
          onTap: () => _movePortfolio(ref, -1, assets.length),
        ),
        _PreviewAction(
          icon: Icons.arrow_forward,
          onTap: () => _movePortfolio(ref, 1, assets.length),
        ),
        _PreviewAction(
          icon: Icons.close,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

void _movePortfolio(WidgetRef ref, int direction, int length) {
  var index = (ref.read(_portfolioIndexProvider) + direction) % length;
  if (index < 0) index += length;
  ref.read(_portfolioIndexProvider.notifier)._set(value: index);
}

ShootLook? _selectedShootDirector(WidgetRef ref) {
  final state = ref.watch(_createShootControllerProvider);
  if (state.directors.isEmpty) return null;
  return state.directors[state.selectedDirector.clamp(
    0,
    state.directors.length - 1,
  )];
}

List<String> _directorAssets(ShootLook? director) {
  if (director == null) return const [''];
  if (director.portfolioImages.isNotEmpty) return director.portfolioImages;
  return [director.imageUrl];
}

class _ImagePreviewDialog extends ConsumerWidget {
  const _ImagePreviewDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_shootDetailControllerProvider);
    final controller = ref.read(_shootDetailControllerProvider.notifier);
    final image = state.selectedImage;
    return _FullPreview(
      asset: image?.url ?? '',
      actions: [
        _PreviewAction(
          icon: Icons.download_outlined,
          onTap: image == null
              ? null
              : () async {
                  final result = await controller.download(image);
                  if (!context.mounted) return;
                  result.fold(
                    (_) => AppSnackBar.show(context, 'Image downloaded'),
                    (failure) =>
                        AppSnackBar.showError(context, failure.message),
                  );
                },
        ),
        _PreviewAction(
          icon: Icons.close,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _FullPreview extends StatelessWidget {
  const _FullPreview({
    required this.asset,
    required this.actions,
    this.caption,
    this.counter,
  });

  final String asset;
  final List<Widget> actions;
  final String? caption;
  final String? counter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: ColoredBox(
        color: const Color(0xFF050505),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 62, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.white,
                            width: 2,
                          ),
                        ),
                        child: _AssetImage(asset),
                      ),
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        caption!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (counter != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        counter!,
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              right: 13,
              top: 38,
              child: Row(children: actions),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewAction extends StatelessWidget {
  const _PreviewAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: Material(
        color: AppColors.white,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 38,
            child: Icon(icon, size: 19),
          ),
        ),
      ),
    );
  }
}

class _AiEditDialog extends ConsumerStatefulWidget {
  const _AiEditDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  ConsumerState<_AiEditDialog> createState() => _AiEditDialogState();
}

class _AiEditDialogState extends ConsumerState<_AiEditDialog> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_shootDetailControllerProvider);
    final controller = ref.read(_shootDetailControllerProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 230,
          child: ColoredBox(
            color: AppColors.neutralLight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _AssetImage(state.selectedImage?.url ?? ''),
            ),
          ),
        ),
        Flexible(
          child: _ModalFrame(
            title: 'Edit with AI',
            leading: Icons.auto_fix_high,
            actions: [
              AppOutlinedButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
              PrimaryButton(
                label: 'Apply Edit',
                icon: Icons.auto_fix_high,
                isLoading: state.isActionRunning,
                onPressed: () async {
                  final prompt = _promptController.text.trim();
                  if (prompt.isEmpty) {
                    AppSnackBar.showError(context, 'Enter an edit prompt.');
                    return;
                  }
                  final failure = await controller.editImage(prompt);
                  if (!context.mounted) return;
                  if (failure != null) {
                    AppSnackBar.showError(context, failure.message);
                    return;
                  }
                  Navigator.pop(context);
                  widget.onToast('AI edit started');
                },
              ),
            ],
            children: [
              const _BodyText(
                'Describe what you would like to change. Be specific about the edit you want.',
              ),
              AppTextField(
                controller: _promptController,
                labelText: 'Edit prompt',
                hintText:
                    'Remove the shadow on the left side, make the background pure white...',
                minLines: 5,
                maxLines: 5,
              ),
              const Row(
                children: [
                  Expanded(child: _Caption('0 / 500 words')),
                  SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _Caption('Credits based on resolution'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VariationDialog extends ConsumerStatefulWidget {
  const _VariationDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  @override
  ConsumerState<_VariationDialog> createState() => _VariationDialogState();
}

class _VariationDialogState extends ConsumerState<_VariationDialog> {
  final _remarksController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_shootDetailControllerProvider);
    final controller = ref.read(_shootDetailControllerProvider.notifier);
    return _ModalFrame(
      title: 'Add Variation',
      leading: Icons.add,
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Generate',
          icon: Icons.auto_awesome,
          isLoading: state.isActionRunning,
          onPressed: () async {
            final failure = await controller.addVariation(
              _remarksController.text,
            );
            if (!context.mounted) return;
            if (failure != null) {
              AppSnackBar.showError(context, failure.message);
              return;
            }
            Navigator.pop(context);
            widget.onToast('Variation generation started');
          },
        ),
      ],
      children: [
        _CardTitle('Shot ${state.selectedShotIndex + 1}'),
        const _BodyText(
          'Generate a fresh variation using the same product and model references.',
        ),
        AppTextField(
          controller: _remarksController,
          labelText: 'Extra remarks (optional)',
          hintText: 'Warmer lighting...',
          minLines: 3,
          maxLines: 3,
        ),
        const _Caption('Generated using current shoot settings.'),
      ],
    );
  }
}

class _VersionHistoryDialog extends ConsumerWidget {
  const _VersionHistoryDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_shootDetailControllerProvider);
    final controller = ref.read(_shootDetailControllerProvider.notifier);
    return _ModalFrame(
      title: 'Version History',
      leading: Icons.history,
      children: [
        if (state.versions.isEmpty)
          const _Caption('No previous versions are available.')
        else
          for (final version in state.versions)
            _VersionCard(
              version: version.label,
              description: version.description,
              asset: version.url,
              active: version.isActive,
              onActivate: version.isActive
                  ? null
                  : () async {
                      final failure = await controller.setActiveVersion(
                        version.id,
                      );
                      if (!context.mounted) return;
                      if (failure != null) {
                        AppSnackBar.showError(context, failure.message);
                        return;
                      }
                      onToast('${version.label} activated');
                    },
            ),
      ],
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.description,
    required this.asset,
    this.active = false,
    this.onActivate,
  });

  final String version;
  final String description;
  final String asset;
  final bool active;
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? AppColors.neutral100 : AppColors.white,
        border: Border.all(
          color: active ? AppColors.black : AppColors.neutral200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetBox(asset, width: 68, height: 68),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _CardTitle(version)),
                    if (active) const _Badge('Active', kind: _BadgeKind.dark),
                  ],
                ),
                const SizedBox(height: 4),
                _Caption(description),
                if (!active) ...[
                  const SizedBox(height: 6),
                  AppOutlinedButton(
                    label: 'Set Active',
                    icon: Icons.refresh,
                    fitToContent: true,
                    height: 36,
                    onPressed: onActivate,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showImageReportDialog(
  BuildContext context,
  _ShootDetailController controller,
  ShootImage image,
) => showAppDialog<void>(
  context: context,
  title: 'Report image quality',
  subtitle: 'Describe the issue so our team can review it.',
  icon: Icons.flag_outlined,
  builder: (dialogContext) => _ImageReportForm(
    pageContext: context,
    dialogContext: dialogContext,
    controller: controller,
    image: image,
  ),
);

class _ImageReportForm extends StatefulWidget {
  const _ImageReportForm({
    required this.pageContext,
    required this.dialogContext,
    required this.controller,
    required this.image,
  });

  final BuildContext pageContext;
  final BuildContext dialogContext;
  final _ShootDetailController controller;
  final ShootImage image;

  @override
  State<_ImageReportForm> createState() => _ImageReportFormState();
}

class _ImageReportFormState extends State<_ImageReportForm> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppTextField(
        controller: _commentController,
        labelText: 'What is wrong?',
        hintText: 'At least 20 characters',
        maxLines: 5,
      ),
      const SizedBox(height: 12),
      _reportButton(
        label: 'Report product deformation',
        icon: Icons.inventory_2_outlined,
        reason: 'product_deformed',
      ),
      const SizedBox(height: 8),
      _reportButton(
        label: 'Report model deformation',
        icon: Icons.person_outline,
        reason: 'model_deformed',
      ),
    ],
  );

  Widget _reportButton({
    required String label,
    required IconData icon,
    required String reason,
  }) => AppOutlinedButton(
    label: label,
    icon: icon,
    onPressed: () => _submitImageReport(
      context: widget.pageContext,
      dialogContext: widget.dialogContext,
      controller: widget.controller,
      image: widget.image,
      reason: reason,
      comment: _commentController.text,
    ),
  );
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
