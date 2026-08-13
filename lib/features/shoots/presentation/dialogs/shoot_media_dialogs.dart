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
  return state.directors[state.previewDirector.clamp(
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
