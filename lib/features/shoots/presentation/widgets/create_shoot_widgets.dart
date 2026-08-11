part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CreateProductQueryController extends Notifier<String> {
  @override
  String build() => '';

  void _set({required String value}) {
    if (state == value) return;
    state = value;
  }
}

class _CreateProductPageController extends Notifier<int> {
  @override
  int build() => 0;

  void _set({required int value}) {
    if (state == value) return;
    state = value;
  }
}

class _CreateModelQueryController extends Notifier<String> {
  @override
  String build() => '';

  void _set({required String value}) {
    if (state == value) return;
    state = value;
  }
}

final NotifierProvider<_CreateProductQueryController, String>
_createProductQueryProvider =
    NotifierProvider.autoDispose<_CreateProductQueryController, String>(
      _CreateProductQueryController.new,
    );
final NotifierProvider<_CreateProductPageController, int>
_createProductPageProvider =
    NotifierProvider.autoDispose<_CreateProductPageController, int>(
      _CreateProductPageController.new,
    );
final NotifierProvider<_CreateModelQueryController, String>
_createModelQueryProvider =
    NotifierProvider.autoDispose<_CreateModelQueryController, String>(
      _CreateModelQueryController.new,
    );

class _CreateShootHeader extends StatelessWidget {
  const _CreateShootHeader({
    required this.isAdmin,
    required this.isDemo,
    required this.onDemoChanged,
  });

  final bool isAdmin;
  final bool isDemo;
  final ValueChanged<bool> onDemoChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              isDemo ? 'New Demo Shoot' : 'New Shoot',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                height: 1.1,
              ),
            ),
            const _Badge('AI Director', kind: _BadgeKind.dark),
          ],
        ),
        const SizedBox(height: 4),
        _Caption(
          isDemo
              ? 'Bundle multiple directors into one client demo'
              : 'AI Director handles everything for you',
        ),
        if (isAdmin) ...[
          const SizedBox(height: 10),
          FilterChip(
            key: const ValueKey('demo-shoot-toggle'),
            label: const Text('Demo Shoot'),
            avatar: const Icon(Icons.admin_panel_settings_outlined, size: 18),
            selected: isDemo,
            onSelected: onDemoChanged,
          ),
        ],
      ],
    );
  }
}

class _CreateSectionHeader extends StatelessWidget {
  const _CreateSectionHeader({
    required this.title,
    required this.subtitle,
    this.addLabel,
    this.onAdd,
  });

  final String title;
  final String subtitle;
  final String? addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(child: _SectionTitle(title)),
            if (onAdd != null) ...[
              const SizedBox(width: 4),
              AppOutlinedButton(
                label: addLabel ?? 'Add',
                icon: Icons.add,
                fitToContent: true,
                height: 35,
                onPressed: onAdd,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        _Caption(subtitle),
      ],
    );
  }
}

class _ProductStep extends ConsumerStatefulWidget {
  const _ProductStep({
    required this.products,
    required this.isLoading,
    required this.selectedIds,
    required this.selectedProducts,
    required this.productMode,
    required this.onSelect,
    required this.onClear,
    required this.onModeChanged,
    required this.onAdd,
    required this.onCalibrate,
  });

  final List<ShootCatalogItem> products;
  final bool isLoading;
  final Set<String> selectedIds;
  final List<ShootCatalogItem> selectedProducts;
  final ProductMode productMode;
  final ValueChanged<int> onSelect;
  final VoidCallback onClear;
  final ValueChanged<ProductMode> onModeChanged;
  final VoidCallback onAdd;
  final VoidCallback onCalibrate;

  @override
  ConsumerState<_ProductStep> createState() => _ProductStepState();
}

class _ProductStepState extends ConsumerState<_ProductStep> {
  static const _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_createProductQueryProvider);
    final pageIndex = ref.watch(_createProductPageProvider);
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = [
      for (final (index, product) in widget.products.indexed)
        if (normalizedQuery.isEmpty ||
            product.name.toLowerCase().contains(normalizedQuery) ||
            product.subtitle.toLowerCase().contains(normalizedQuery))
          (index, product),
    ];
    final pageCount = (filtered.length / _pageSize).ceil().clamp(1, 1000);
    final firstProductIndex = pageIndex * _pageSize;
    final lastProductIndex = (firstProductIndex + _pageSize).clamp(
      0,
      filtered.length,
    );
    final visibleProducts = firstProductIndex < filtered.length
        ? filtered.sublist(firstProductIndex, lastProductIndex)
        : const <(int, ShootCatalogItem)>[];
    final maxProducts = widget.productMode == ProductMode.pairing ? 3 : 6;

    return _Column(
      gap: 12,
      children: [
        _CreateSectionHeader(
          title: 'Select Product',
          subtitle: 'Choose the product you want to photograph',
          addLabel: 'Add Product',
          onAdd: widget.onAdd,
        ),
        AppTextField(
          fieldKey: const ValueKey('create-product-search'),
          hintText: 'Search by name or SKU...',
          textInputAction: TextInputAction.search,
          leading: const Icon(Icons.search, size: 20),
          onChanged: (value) {
            ref.read(_createProductQueryProvider.notifier)._set(value: value);
            ref.read(_createProductPageProvider.notifier)._set(value: 0);
          },
        ),
        if (widget.selectedProducts.isNotEmpty)
          _ProductSelectionPanel(
            products: widget.selectedProducts,
            maxProducts: maxProducts,
            productMode: widget.productMode,
            onClear: widget.onClear,
            onCalibrate: widget.onCalibrate,
            onModeChanged: widget.onModeChanged,
            onRemove: (productId) {
              final index = widget.products.indexWhere(
                (product) => product.id == productId,
              );
              if (index >= 0) widget.onSelect(index);
            },
          ),
        if (widget.isLoading)
          const _ProductGridShimmer()
        else
          _SelectionGrid(
            items: [
              for (final item in visibleProducts)
                (item.$1, item.$2.name, item.$2.subtitle, item.$2.imageUrl),
            ],
            selectedIndices: {
              for (final (index, product) in widget.products.indexed)
                if (widget.selectedIds.contains(product.id)) index,
            },
            selectedLabels: {
              for (final (position, product) in widget.selectedProducts.indexed)
                widget.products.indexWhere((item) => item.id == product.id):
                    position == 0 ? 'Primary' : 'Product ${position + 1}',
            },
            square: true,
            onSelect: widget.onSelect,
          ),
        if (!widget.isLoading && pageCount > 1)
          _ProductPagination(
            pageIndex: pageIndex,
            pageCount: pageCount,
            onPageChanged: (value) => ref
                .read(_createProductPageProvider.notifier)
                ._set(value: value),
          ),
      ],
    );
  }
}

class _ProductSelectionPanel extends StatelessWidget {
  const _ProductSelectionPanel({
    required this.products,
    required this.maxProducts,
    required this.productMode,
    required this.onClear,
    required this.onCalibrate,
    required this.onModeChanged,
    required this.onRemove,
  });

  final List<ShootCatalogItem> products;
  final int maxProducts;
  final ProductMode productMode;
  final VoidCallback onClear;
  final VoidCallback onCalibrate;
  final ValueChanged<ProductMode> onModeChanged;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final hasMultiple = products.length > 1;
    final modeSummary = productMode == ProductMode.pairing
        ? 'worn together in every shot'
        : 'split across shots as variants';
    return Container(
      key: const ValueKey('create-product-selection-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: _Column(
        gap: 10,
        children: [
          Row(
            children: [
              Expanded(
                child: _Caption(
                  '${products.length}/$maxProducts products'
                  '${hasMultiple ? ' · $modeSummary' : ''}',
                ),
              ),
              GestureDetector(
                onTap: onClear,
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AppOutlinedButton(
              key: const ValueKey('calibrate-primary-product'),
              label: 'Calibrate size',
              icon: Icons.straighten_outlined,
              fitToContent: true,
              iconAngle: 0.7853981633974483,
              height: 30,
              borderColor: AppColors.neutral250,
              onPressed: onCalibrate,
            ),
          ),
          _Caption(
            hasMultiple
                ? 'Sets real-world size for the primary product (${products.first.name})'
                : 'Set real-world size so the model renders it to scale',
          ),
          if (hasMultiple)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _productModeCard(
                    title: 'Worn together',
                    description: 'A set/outfit, all products in every shot',
                    selected: productMode == ProductMode.pairing,
                    onTap: () => onModeChanged(ProductMode.pairing),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _productModeCard(
                    title: 'Colour / style variants',
                    description:
                        'Same item, different finishes, split across shots',
                    selected: productMode == ProductMode.variant,
                    onTap: () => onModeChanged(ProductMode.variant),
                  ),
                ),
              ],
            ),
          for (final (index, product) in products.indexed)
            _selectedProductRow(
              product: product,
              role: index == 0 ? 'Primary' : 'Product ${index + 1}',
              onRemove: () => onRemove(product.id),
            ),
        ],
      ),
    );
  }
}

Widget _productModeCard({
  required String title,
  required String description,
  required bool selected,
  required VoidCallback onTap,
}) => InkWell(
  onTap: onTap,
  child: Container(
    constraints: const BoxConstraints(minHeight: 128),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(
        color: selected ? AppColors.black : AppColors.neutral200,
        width: selected ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTitle(title),
        const SizedBox(height: 4),
        _Caption(description),
      ],
    ),
  ),
);

Widget _selectedProductRow({
  required ShootCatalogItem product,
  required String role,
  required VoidCallback onRemove,
}) => Container(
  padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
  decoration: BoxDecoration(
    color: AppColors.white,
    border: Border.all(color: AppColors.neutral200),
  ),
  child: Row(
    children: [
      _AssetBox(product.imageUrl, width: 42, height: 42),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(product.name),
            const SizedBox(height: 2),
            _Caption(role),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Remove ${product.name}',
        onPressed: onRemove,
        icon: const Icon(Icons.close, size: 20),
      ),
    ],
  ),
);

class _ModelStep extends ConsumerStatefulWidget {
  const _ModelStep({
    required this.models,
    required this.userModelCount,
    required this.libraryModelCount,
    required this.useLibraryModels,
    required this.selectedKeys,
    required this.selectedModels,
    required this.onSelect,
    required this.onSourceChanged,
    required this.onAdd,
  });

  final List<ShootCatalogItem> models;
  final int userModelCount;
  final int libraryModelCount;
  final bool useLibraryModels;
  final Set<String> selectedKeys;
  final List<ShootCatalogItem> selectedModels;
  final ValueChanged<int> onSelect;
  final ValueChanged<bool> onSourceChanged;
  final VoidCallback onAdd;

  @override
  ConsumerState<_ModelStep> createState() => _ModelStepState();
}

class _ModelStepState extends ConsumerState<_ModelStep> {
  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_createModelQueryProvider);
    final normalizedQuery = query.trim().toLowerCase();
    final visibleModels = [
      for (final (index, model) in widget.models.indexed)
        if (normalizedQuery.isEmpty ||
            model.name.toLowerCase().contains(normalizedQuery))
          (index, model.name, model.subtitle, model.imageUrl),
    ];
    return _Column(
      gap: 12,
      children: [
        _CreateSectionHeader(
          title: 'Select Model',
          subtitle: 'Choose a model to wear your product',
          onAdd: widget.onAdd,
        ),

        _SegmentedChoices(
          choices: [
            'My Models · ${widget.userModelCount}',
            'LookAtlas · ${widget.libraryModelCount}',
          ],
          selected: widget.useLibraryModels ? 1 : 0,
          onSelect: (index) => widget.onSourceChanged(index == 1),
        ),
        if (widget.selectedModels.isNotEmpty)
          _SelectedRoster(
            count: '${widget.selectedModels.length}/3 models',
            items: widget.selectedModels,
          ),
        AppTextField(
          fieldKey: const ValueKey('create-model-search'),
          hintText: 'Search models by name...',
          textInputAction: TextInputAction.search,
          leading: const Icon(Icons.search, size: 20),
          onChanged: (value) =>
              ref.read(_createModelQueryProvider.notifier)._set(value: value),
        ),
        _SelectionGrid(
          items: visibleModels,
          selectedIndices: {
            for (final (index, model) in widget.models.indexed)
              if (widget.selectedKeys.contains(_modelKey(model))) index,
          },
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
    required this.isDemo,
    required this.selectedDirectorIds,
    required this.onDemoSelect,
  });

  final List<ShootLook> directors;
  final ShootSettings settings;
  final int selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<ShootSettings> onSettingsChanged;
  final ValueChanged<int> onPortfolio;
  final bool isDemo;
  final Set<String> selectedDirectorIds;
  final ValueChanged<int> onDemoSelect;

  @override
  Widget build(BuildContext context) {
    return _Column(
      gap: 12,
      children: [
        const _CreateSectionHeader(
          title: 'Choose Your Creative Director',
          subtitle:
              "Select what you're creating and who should direct the shoot",
        ),
        const _FieldLabel('What are you creating?'),
        _UseCaseGrid(
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
        _FieldLabel(
          isDemo ? 'Select directors (one or more)' : 'Select a Director',
        ),
        if (isDemo)
          const _Caption(
            'Each director becomes one section of the demo, so the client can see their products in several styles.',
          ),
        _DirectorGrid(
          directors: directors,
          selectedIndices: isDemo
              ? {
                  for (final (index, director) in directors.indexed)
                    if (selectedDirectorIds.contains(director.id)) index,
                }
              : {selected},
          onSelect: isDemo ? onDemoSelect : onSelect,
          onPreview: onPortfolio,
        ),
        _FieldLabel(
          isDemo
              ? 'Brief the directors (optional)'
              : 'Brief ${directors.isEmpty ? 'director' : directors[selected.clamp(0, directors.length - 1)].name} (optional)',
        ),
        TextField(
          key: const ValueKey('create-director-brief'),
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Anything specific you'd like the director to consider?",
            alignLabelWithHint: true,
          ),
          onChanged: (value) => onSettingsChanged(
            settings.copyWith(directorFeedback: value),
          ),
        ),
      ],
    );
  }
}
