part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CreateShootHeader extends StatelessWidget {
  const _CreateShootHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'New Shoot',
              style: TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: AppTypography.bold,
              ),
            ),
            _Badge('AI Director', kind: _BadgeKind.dark),
          ],
        ),
        SizedBox(height: 4),
        _Caption('AI Director handles everything for you'),
      ],
    );
  }
}

class _CreateSectionHeader extends StatelessWidget {
  const _CreateSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 4),
        _Caption(subtitle),
      ],
    );
  }
}

class _ProductStep extends StatefulWidget {
  const _ProductStep({
    required this.products,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });

  final List<ShootCatalogItem> products;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  State<_ProductStep> createState() => _ProductStepState();
}

class _ProductStepState extends State<_ProductStep> {
  static const _pageSize = 4;

  int _pageIndex = 0;
  String _query = '';

  void _changePage(int pageIndex) {
    setState(() => _pageIndex = pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = [
      for (final (index, product) in widget.products.indexed)
        if (normalizedQuery.isEmpty ||
            product.name.toLowerCase().contains(normalizedQuery) ||
            product.subtitle.toLowerCase().contains(normalizedQuery))
          (index, product),
    ];
    final pageCount = (filtered.length / _pageSize).ceil().clamp(1, 1000);
    final firstProductIndex = _pageIndex * _pageSize;
    final lastProductIndex = (firstProductIndex + _pageSize).clamp(
      0,
      filtered.length,
    );
    final visibleProducts = firstProductIndex < filtered.length
        ? filtered.sublist(firstProductIndex, lastProductIndex)
        : const <(int, ShootCatalogItem)>[];
    final selectedProduct = widget.products.isEmpty
        ? null
        : widget.products[widget.selected.clamp(0, widget.products.length - 1)];

    return _Stack(
      gap: 12,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _CreateSectionHeader(
                title: 'Select Product',
                subtitle: 'Choose the product you want to photograph',
              ),
            ),
            AppOutlinedButton(
              label: 'Add New Product',
              icon: Icons.add,
              fitToContent: true,
              height: 36,
              onPressed: widget.onAdd,
            ),
          ],
        ),
        AppTextField(
          fieldKey: const ValueKey('create-product-search'),
          hintText: 'Search by name or SKU...',
          textInputAction: TextInputAction.search,
          leading: const Icon(Icons.search, size: 20),
          onChanged: (value) => setState(() {
            _query = value;
            _pageIndex = 0;
          }),
        ),
        if (selectedProduct != null)
          _SelectedRoster(
            count: '1 product',
            name: selectedProduct.name,
            asset: selectedProduct.imageUrl,
          ),
        _SelectionGrid(
          items: [
            for (final item in visibleProducts)
              (item.$1, item.$2.name, item.$2.subtitle, item.$2.imageUrl),
          ],
          selected: widget.selected,
          square: true,
          onSelect: widget.onSelect,
        ),
        if (pageCount > 1)
          _ProductPagination(
            pageIndex: _pageIndex,
            pageCount: pageCount,
            onPageChanged: _changePage,
          ),
      ],
    );
  }
}

class _ModelStep extends StatefulWidget {
  const _ModelStep({
    required this.models,
    required this.userModelCount,
    required this.libraryModelCount,
    required this.useLibraryModels,
    required this.selected,
    required this.onSelect,
    required this.onSourceChanged,
    required this.onAdd,
  });

  final List<ShootCatalogItem> models;
  final int userModelCount;
  final int libraryModelCount;
  final bool useLibraryModels;
  final int selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<bool> onSourceChanged;
  final VoidCallback onAdd;

  @override
  State<_ModelStep> createState() => _ModelStepState();
}

class _ModelStepState extends State<_ModelStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleModels = [
      for (final (index, model) in widget.models.indexed)
        if (normalizedQuery.isEmpty ||
            model.name.toLowerCase().contains(normalizedQuery))
          (index, model.name, model.subtitle, model.imageUrl),
    ];
    final selectedModel = widget.models.isEmpty
        ? null
        : widget.models[widget.selected.clamp(0, widget.models.length - 1)];
    return _Stack(
      gap: 12,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _CreateSectionHeader(
                title: 'Select Model',
                subtitle: 'Choose a model to wear your product',
              ),
            ),
            AppOutlinedButton(
              label: 'Add',
              icon: Icons.add,
              fitToContent: true,
              height: 36,
              onPressed: widget.onAdd,
            ),
          ],
        ),
        _SegmentedChoices(
          choices: [
            'My Models · ${widget.userModelCount}',
            'LookAtlas · ${widget.libraryModelCount}',
          ],
          selected: widget.useLibraryModels ? 1 : 0,
          onSelect: (index) => widget.onSourceChanged(index == 1),
        ),
        if (selectedModel != null)
          _SelectedRoster(
            count: '1 model · 1 primary',
            name: selectedModel.name,
            asset: selectedModel.imageUrl,
          ),
        AppTextField(
          fieldKey: const ValueKey('create-model-search'),
          hintText: 'Search models by name...',
          textInputAction: TextInputAction.search,
          leading: const Icon(Icons.search, size: 20),
          onChanged: (value) => setState(() => _query = value),
        ),
        _SelectionGrid(
          items: visibleModels,
          selected: widget.selected,
          onSelect: widget.onSelect,
        ),
      ],
    );
  }
}

class _DirectorStep extends StatelessWidget {
  const _DirectorStep({
    required this.directors,
    required this.settings,
    required this.selected,
    required this.onSelect,
    required this.onSettingsChanged,
    required this.onPortfolio,
  });

  final List<ShootLook> directors;
  final ShootSettings settings;
  final int selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<ShootSettings> onSettingsChanged;
  final VoidCallback onPortfolio;

  @override
  Widget build(BuildContext context) {
    return _Stack(
      gap: 12,
      children: [
        const _CreateSectionHeader(
          title: 'Choose Your Creative Director',
          subtitle: 'Select what you are creating and who should direct it',
        ),
        const _FieldLabel('What are you creating?'),
        _OptionWrap(
          options: const [
            'Product Page',
            'Social Media',
            'Lookbook',
            'Campaign',
            'Marketplace',
          ],
          selected: const [
            'pdp',
            'social',
            'lookbook',
            'campaign',
            'marketplace',
          ].indexOf(settings.useCase).clamp(0, 4),
          onSelect: (index) => onSettingsChanged(
            settings.copyWith(
              useCase: const [
                'pdp',
                'social',
                'lookbook',
                'campaign',
                'marketplace',
              ][index],
            ),
          ),
        ),
        const _FieldLabel('Select a Director'),
        _SelectionGrid(
          items: [
            for (final (index, director) in directors.indexed)
              (
                index,
                director.name,
                director.subtitle,
                director.imageUrl,
              ),
          ],
          selected: selected,
          onSelect: onSelect,
          onPreview: onPortfolio,
        ),
        TextField(
          minLines: 3,
          maxLines: 4,
          decoration: InputDecoration(
            labelText:
                'Brief ${directors.isEmpty ? 'director' : directors[selected.clamp(0, directors.length - 1)].name} (optional)',
            hintText: 'Tell your director any specific direction...',
            alignLabelWithHint: true,
          ),
          onChanged: (value) => onSettingsChanged(
            settings.copyWith(directorFeedback: value),
          ),
        ),
        const _FieldLabel('Resolution'),
        _OptionWrap(
          options: const ['1K · 1', '2K · 2', '4K · 4'],
          selected: const ['1K', '2K', '4K'].indexOf(settings.imageSize),
          onSelect: (index) => onSettingsChanged(
            settings.copyWith(imageSize: const ['1K', '2K', '4K'][index]),
          ),
        ),
        const _FieldLabel('Additional Settings'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Caption('Number of shots'),
            _CardTitle('${settings.numberOfShots}'),
          ],
        ),
        Slider(
          min: 1,
          max: 10,
          divisions: 9,
          value: settings.numberOfShots.toDouble(),
          onChanged: (value) => onSettingsChanged(
            settings.copyWith(numberOfShots: value.round()),
          ),
        ),
        const _Caption('Variations per shot'),
        _OptionWrap(
          options: const ['1', '2', '3', '4', '5'],
          selected: settings.variations - 1,
          onSelect: (index) => onSettingsChanged(
            settings.copyWith(variations: index + 1),
          ),
        ),
        const _Caption('Background preference'),
        _OptionWrap(
          options: const [
            'Studio',
            'Studio Dark',
            'Street',
            'Home',
            'Let AI Decide',
          ],
          selected: const [
            'studio',
            'studio_dark',
            'street',
            'home',
            'ai',
          ].indexOf(settings.background).clamp(0, 4),
          onSelect: (index) => onSettingsChanged(
            settings.copyWith(
              background: const [
                'studio',
                'studio_dark',
                'street',
                'home',
                'ai',
              ][index],
            ),
          ),
        ),
      ],
    );
  }
}
