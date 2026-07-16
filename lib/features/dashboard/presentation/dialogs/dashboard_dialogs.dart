part of '../screens/dashboard_screen.dart';

class _DashboardModal extends StatelessWidget {
  const _DashboardModal({
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
    final content = _modalContent(context);
    return AppDialog(
      config: AppDialogConfig.standard.copyWith(
        insetPadding: const EdgeInsets.all(16),
        maxWidth: 520,
        maxHeightOffset: 32,
      ),
      child: content,
    );
  }

  Widget _modalContent(BuildContext context) {
    return switch (kind) {
      _ModalKind.contextPaywall => _ModalFrame(
        title: 'Add products. Keep shooting.',
        actions: [
          _Button.secondary(
            label: 'Close',
            full: true,
            onTap: () => Navigator.pop(context),
          ),
          _Button(
            label: 'View Plans',
            full: true,
            onTap: () {
              Navigator.pop(context);
              onNavigate(_DashboardPage.billing);
            },
          ),
        ],
        children: const [
          _BodyText(
            r'Upload your catalog and run a shoot whenever you are ready. Starter is $49/mo, Pro is $99/mo plus AI video.',
          ),
          _Alert(
            kind: _AlertKind.info,
            text:
                'Up to 200 photos a month on Pro\nAI video on Pro and Business\nCancel anytime, one tap',
          ),
        ],
      ),
      _ModalKind.product => _ProductModal(onToast: onToast),
      _ModalKind.model => _ModelModal(onToast: onToast),
      _ModalKind.customShot => _ModalFrame(
        title: 'Add Custom Shot',
        actions: [
          _Button.secondary(
            label: 'Cancel',
            full: true,
            onTap: () => Navigator.pop(context),
          ),
          _Button(
            label: 'Format Shot',
            full: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
        children: const [
          _TextAreaLike('Describe your shot idea...'),
          _Caption(
            'Your custom shot will match the current location, product, model, and director settings.',
          ),
        ],
      ),
      _ModalKind.editAi => _ModalFrame(
        title: 'Edit with AI',
        actions: [
          _Button.secondary(
            label: 'Cancel',
            full: true,
            onTap: () => Navigator.pop(context),
          ),
          _Button(
            label: 'Apply Edit',
            icon: Icons.auto_awesome,
            full: true,
            onTap: () {
              Navigator.pop(context);
              onToast('AI edit started');
            },
          ),
        ],
        children: const [
          _AssetBox('$_img/showcase-dress-after.jpg', height: 190),
          _TextAreaLike('Describe the edit you want...'),
          _Caption(
            'Max 80 words. The processing overlay says "AI is editing..." on the image card.',
          ),
        ],
      ),
      _ModalKind.versions => _ModalFrame(
        title: 'Image Versions',
        children: [
          const _Grid2(
            children: [
              _AssetBox('$_img/showcase-dress-after.jpg', height: 160),
              _AssetBox('$_img/showcase-dress-before.jpg', height: 160),
            ],
          ),
          _Button(
            label: 'Set Active Version',
            full: true,
            onTap: () {
              Navigator.pop(context);
              onToast('Version restored');
            },
          ),
        ],
      ),
      _ModalKind.video => _ModalFrame(
        title: 'Generate Video',
        actions: [
          _Button.secondary(
            label: 'Cancel',
            full: true,
            onTap: () => Navigator.pop(context),
          ),
          _Button(
            label: 'Generate Video',
            full: true,
            onTap: () {
              Navigator.pop(context);
              onToast('Video requested');
            },
          ),
        ],
        children: const [
          _ProgressBar(value: 0.66),
          _CardTitle('Step 1: Choose Variation'),
          _Grid2(
            children: [
              _ChoiceCard(
                title: 'Variation 1',
                asset: '$_img/showcase-dress-after.jpg',
                active: true,
                vertical: true,
              ),
              _ChoiceCard(
                title: 'Variation 2',
                asset: '$_img/showcase-bag-after.jpg',
                vertical: true,
              ),
            ],
          ),
          _Alert(
            kind: _AlertKind.info,
            text:
                'Step 2 picks starting frame when multiple images exist. Step 3 reviews aspect ratio and credits.',
          ),
        ],
      ),
      _ModalKind.delete => _ModalFrame(
        title: 'Delete Item',
        actions: [
          _Button.secondary(
            label: 'Cancel',
            full: true,
            onTap: () => Navigator.pop(context),
          ),
          _Button(
            label: 'Delete',
            full: true,
            danger: true,
            onTap: () {
              Navigator.pop(context);
              onToast('Deleted');
            },
          ),
        ],
        children: const [
          _BodyText(
            'This destructive confirmation appears for product/model deletion.',
          ),
        ],
      ),
    };
  }
}

class _ProductModal extends StatelessWidget {
  const _ProductModal({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Add New Product',
      subtitle: 'Upload photos and details for your product',
      leading: Icons.inventory_2_outlined,
      actions: [
        _Button.secondary(
          label: 'Cancel',
          full: true,
          onTap: () => Navigator.pop(context),
        ),
        _Button(
          label: 'Add Product',
          icon: Icons.check,
          full: true,
          onTap: () {
            Navigator.pop(context);
            onToast('Product added');
          },
        ),
      ],
      children: const [
        _InputLike('Classic Cotton T-Shirt', label: 'Product Name *'),
        _InputLike('TSH-001', label: 'SKU *'),
        _SelectLike('Tops', label: 'Category'),
        _TextAreaLike('Describe your product...', label: 'Description'),
        _UploadBox(label: 'Photos * 0/5'),
        _Alert(
          kind: _AlertKind.error,
          text: 'Error condition: A product with this SKU already exists.',
        ),
      ],
    );
  }
}

class _ModelModal extends StatelessWidget {
  const _ModelModal({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Add New Model',
      subtitle: 'Upload photos and details',
      leading: Icons.person_outline,
      actions: [
        _Button.secondary(
          label: 'Cancel',
          full: true,
          onTap: () => Navigator.pop(context),
        ),
        _Button(
          label: 'Add Model',
          icon: Icons.check,
          full: true,
          onTap: () {
            Navigator.pop(context);
            onToast('Model added');
          },
        ),
      ],
      children: const [
        _InputLike('Sarah Martinez', label: 'Model Name *'),
        _SelectLike('Female', label: 'Gender *'),
        _InputLike('170 cm', label: 'Height *'),
        _UploadBox(label: 'Photos * 0/5'),
      ],
    );
  }
}

class _ModalFrame extends StatelessWidget {
  const _ModalFrame({
    required this.title,
    this.subtitle,
    this.leading,
    this.children = const [],
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final IconData? leading;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
          child: Row(
            children: [
              if (leading != null) ...[
                _SquareIcon(leading!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title),
                    if (subtitle != null) _Caption(subtitle!),
                  ],
                ),
              ),
              _IconButton(
                icon: Icons.close,
                label: 'Close dialog',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const _Hairline(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _Stack(gap: 12, children: children),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const _Hairline(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  Expanded(child: actions[i]),
                  if (i != actions.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
