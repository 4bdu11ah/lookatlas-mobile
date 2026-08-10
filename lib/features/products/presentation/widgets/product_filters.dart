part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductFilterBar extends ConsumerWidget {
  const _ProductFilterBar({
    required this.query,
    required this.categoryFilter,
    required this.statusFilter,
    required this.sortOrder,
    required this.totalCount,
    required this.calibratedCount,
  });

  final String query;
  final _ProductCategoryFilter categoryFilter;
  final _ProductStatusFilter statusFilter;
  final _ProductSortOrder sortOrder;
  final int totalCount;
  final int calibratedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilterCount = [
      categoryFilter != _ProductCategoryFilter.all,
      statusFilter != _ProductStatusFilter.all,
      sortOrder != _ProductSortOrder.newest,
    ].where((active) => active).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductSearchField(query: query),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$totalCount products - '),
                    TextSpan(
                      text: '$calibratedCount',
                      style: const TextStyle(
                        color: AppColors.successDarker,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const TextSpan(text: ' calibrated'),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ),
            AppOutlinedButton(
              key: const ValueKey('open-product-filter-sheet'),
              label: activeFilterCount == 0
                  ? 'Filters'
                  : 'Filters ($activeFilterCount)',
              icon: Icons.tune,
              fitToContent: true,
              height: 40,
              onPressed: () => _showProductFilterSheet(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductFilterSheetInitial {
  const _ProductFilterSheetInitial({
    required this.category,
    required this.status,
    required this.sort,
  });

  final _ProductCategoryFilter category;
  final _ProductStatusFilter status;
  final _ProductSortOrder sort;
}

class _ProductFilterSheetState {
  const _ProductFilterSheetState({
    required this.category,
    required this.status,
    required this.sort,
  });

  final _ProductCategoryFilter category;
  final _ProductStatusFilter status;
  final _ProductSortOrder sort;

  _ProductFilterSheetState copyWith({
    _ProductCategoryFilter? category,
    _ProductStatusFilter? status,
    _ProductSortOrder? sort,
  }) => _ProductFilterSheetState(
    category: category ?? this.category,
    status: status ?? this.status,
    sort: sort ?? this.sort,
  );
}

class _ProductFilterSheetController extends Notifier<_ProductFilterSheetState> {
  _ProductFilterSheetController(this.initial);

  final _ProductFilterSheetInitial initial;

  @override
  _ProductFilterSheetState build() => _ProductFilterSheetState(
    category: initial.category,
    status: initial.status,
    sort: initial.sort,
  );

  void setCategory(_ProductCategoryFilter value) =>
      state = state.copyWith(category: value);
  void setStatus(_ProductStatusFilter value) =>
      state = state.copyWith(status: value);
  void setSort(_ProductSortOrder value) => state = state.copyWith(sort: value);
}

// Riverpod's family provider type is inferred from the factory.
// ignore: specify_nonobvious_property_types
final _productFilterSheetProvider = NotifierProvider.autoDispose
    .family<
      _ProductFilterSheetController,
      _ProductFilterSheetState,
      _ProductFilterSheetInitial
    >(_ProductFilterSheetController.new);

Future<void> _showProductFilterSheet(BuildContext context, WidgetRef ref) {
  final state = ref.read(_productsControllerProvider);
  final initial = _ProductFilterSheetInitial(
    category: state.categoryFilter,
    status: state.statusFilter,
    sort: state.sortOrder,
  );
  return showAppBottomSheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) => _ProductFilterSheet(initial: initial),
  );
}

class _ProductFilterSheet extends ConsumerWidget {
  const _ProductFilterSheet({required this.initial});

  final _ProductFilterSheetInitial initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_productFilterSheetProvider(initial));
    final controller = ref.read(_productFilterSheetProvider(initial).notifier);
    return _SheetFrame(
      title: 'Filter products',
      actions: [
        AppOutlinedButton(
          label: 'Clear',

          onPressed: () {
            ref.read(_productsControllerProvider.notifier).clearFilters();
            Navigator.pop(context);
          },
        ),
        PrimaryButton(
          label: 'Show products',
          onPressed: () {
            ref
                .read(_productsControllerProvider.notifier)
                .applyFilters(
                  category: state.category,
                  status: state.status,
                  sort: state.sort,
                );
            Navigator.pop(context);
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductFilterDropdown<_ProductCategoryFilter>(
            key: const ValueKey('product-category-filter'),
            label: 'Category',
            value: state.category,
            values: _ProductCategoryFilter.values,
            labelFor: (value) => value.label,
            onChanged: controller.setCategory,
          ),
          const SizedBox(height: 20),
          _ProductFilterDropdown<_ProductStatusFilter>(
            key: const ValueKey('product-status-filter'),
            label: 'Calibration',
            value: state.status,
            values: _ProductStatusFilter.values,
            labelFor: (value) => value.label,
            onChanged: controller.setStatus,
          ),
          const SizedBox(height: 20),
          _ProductFilterDropdown<_ProductSortOrder>(
            key: const ValueKey('product-sort-filter'),
            label: 'Sort by',
            value: state.sort,
            values: _ProductSortOrder.values,
            labelFor: (value) => value.label,
            onChanged: controller.setSort,
          ),
        ],
      ),
    );
  }
}

class _ProductFilterDropdown<T> extends StatelessWidget {
  const _ProductFilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    super.key,
  });

  static const _config = AppDropdownConfig(
    height: 40,
    horizontalPadding: 10,
  );

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: AppTypography.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        AppDropdown<T>(
          value: value,
          values: values,
          labelFor: labelFor,
          onChanged: onChanged,
          config: _config,
        ),
      ],
    );
  }
}

class _ProductSearchField extends ConsumerStatefulWidget {
  const _ProductSearchField({required this.query});

  final String query;

  @override
  ConsumerState<_ProductSearchField> createState() =>
      _ProductSearchFieldState();
}

class _ProductSearchFieldState extends ConsumerState<_ProductSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _ProductSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: const ValueKey('product-search-field'),
      controller: _controller,
      height: 40,
      hintText: 'Search by name, sku, or description',
      textInputAction: TextInputAction.search,
      onChanged: ref
          .read(_productsControllerProvider.notifier)
          .updateSearchQuery,
      leading: const Icon(Icons.search, size: 16, color: AppColors.neutral500),
      trailing: widget.query.isEmpty
          ? const SizedBox(width: 11)
          : InkWell(
              key: const ValueKey('clear-product-search'),
              onTap: ref.read(_productsControllerProvider.notifier).clearSearch,
              child: const SizedBox(
                width: 38,
                height: 40,
                child: Icon(Icons.close, size: 16, color: AppColors.black),
              ),
            ),
    );
  }
}
