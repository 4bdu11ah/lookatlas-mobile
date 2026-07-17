part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

const _portfolioAssets = [
  '$_img/showcase-tshirt-after.jpg',
  '$_img/showcase-dress-after.jpg',
  '$_img/showcase-shoes-after.jpg',
  '$_img/showcase-sunglasses-after.jpg',
];

class _DirectorPortfolioDialog extends StatelessWidget {
  const _DirectorPortfolioDialog({required this.onPreview});

  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Alex Chen',
      subtitle: 'Clean Professional',
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
          itemCount: _portfolioAssets.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) => InkWell(
            key: ValueKey('portfolio-image-$index'),
            onTap: onPreview,
            child: _AssetImage(_portfolioAssets[index]),
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

class _PortfolioViewer extends StatefulWidget {
  const _PortfolioViewer();

  @override
  State<_PortfolioViewer> createState() => _PortfolioViewerState();
}

class _PortfolioViewerState extends State<_PortfolioViewer> {
  int _index = 0;

  void _move(int direction) {
    setState(() {
      _index = (_index + direction) % _portfolioAssets.length;
      if (_index < 0) _index += _portfolioAssets.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _FullPreview(
      asset: _portfolioAssets[_index],
      caption: 'Crisp tailoring with clean, commercial light',
      counter: '${_index + 1} of ${_portfolioAssets.length}',
      actions: [
        _PreviewAction(icon: Icons.arrow_back, onTap: () => _move(-1)),
        _PreviewAction(icon: Icons.arrow_forward, onTap: () => _move(1)),
        _PreviewAction(
          icon: Icons.close,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _ImagePreviewDialog extends StatelessWidget {
  const _ImagePreviewDialog();

  @override
  Widget build(BuildContext context) {
    return _FullPreview(
      asset: '$_img/showcase-bag-after.jpg',
      actions: [
        const _PreviewAction(icon: Icons.download_outlined),
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

class _AiEditDialog extends StatelessWidget {
  const _AiEditDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: 230,
          child: ColoredBox(
            color: AppColors.neutralLight,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: _AssetImage('$_img/showcase-bag-after.jpg'),
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
                onPressed: () {
                  Navigator.pop(context);
                  onToast('AI edit started');
                },
              ),
            ],
            children: const [
              _BodyText(
                'Describe what you would like to change. Be specific about the edit you want.',
              ),
              AppTextField(
                labelText: 'Edit prompt',
                hintText:
                    'Remove the shadow on the left side, make the background pure white...',
                minLines: 5,
                maxLines: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Caption('0 / 500 words'),
                  _Caption('Credits based on resolution'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VariationDialog extends StatelessWidget {
  const _VariationDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
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
          onPressed: () {
            Navigator.pop(context);
            onToast('Variation generation started');
          },
        ),
      ],
      children: const [
        _CardTitle('Shot 1: Cafe Arrival'),
        _BodyText(
          'Generate a fresh variation using the same product and model references.',
        ),
        AppTextField(
          labelText: 'Extra remarks (optional)',
          hintText: 'Warmer lighting...',
          minLines: 3,
          maxLines: 3,
        ),
        _Caption('Generated in 2K · 2 credits.'),
      ],
    );
  }
}

class _VersionHistoryDialog extends StatelessWidget {
  const _VersionHistoryDialog({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Version History',
      leading: Icons.history,
      children: [
        const _VersionCard(
          version: 'Version 3',
          description: 'Pure white backdrop and softer hand shadow.',
          asset: '$_img/showcase-bag-after.jpg',
          active: true,
        ),
        _VersionCard(
          version: 'Version 2',
          description: 'Warmer lighting and more relaxed hand pose.',
          asset: '$_img/showcase-tshirt-after.jpg',
          onActivate: () => onToast('Version 2 activated'),
        ),
        _VersionCard(
          version: 'Version 1',
          description: 'Original image',
          asset: '$_img/showcase-dress-after.jpg',
          onActivate: () => onToast('Version 1 activated'),
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
