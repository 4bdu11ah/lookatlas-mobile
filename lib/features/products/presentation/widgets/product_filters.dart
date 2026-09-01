part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductFilterBar extends ConsumerWidget {
  const _ProductFilterBar({
    required this.query,
    required this.categoryFilter,
    required this.statusFilter,
    required this.sortOrder,
    required this.totalCount,
    required this.calibratedCount,
    required this.calibrationStatusesAvailable,
  });

  final String query;
  final _ProductCategoryFilter categoryFilter;
  final _ProductStatusFilter statusFilter;
  final _ProductSortOrder sortOrder;
  final int totalCount;
  final int calibratedCount;
  final bool calibrationStatusesAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(_productsControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductSearchField(query: query),
        AppDropdown<_ProductCategoryFilter>(
          key: const ValueKey('product-category-filter'),
          value: categoryFilter,
          values: _ProductCategoryFilter.values,
          labelFor: (value) => value.label,
          onChanged: controller.updateCategoryFilter,
          config: const AppDropdownConfig(height: 46),
        ),
        AppDropdown<_ProductStatusFilter>(
          key: const ValueKey('product-status-filter'),
          value: statusFilter,
          values: _ProductStatusFilter.values,
          labelFor: (value) => value.label,
          onChanged: controller.updateStatusFilter,
          enabled: calibrationStatusesAvailable,
          config: const AppDropdownConfig(height: 46),
        ),
        AppDropdown<_ProductSortOrder>(
          key: const ValueKey('product-sort-filter'),
          value: sortOrder,
          values: _ProductSortOrder.values,
          labelFor: (value) => value.label,
          onChanged: controller.updateSortOrder,
          config: const AppDropdownConfig(height: 46),
        ),
        const SizedBox(height: 10),
        _CatalogEyebrow(
          calibrationStatusesAvailable
              ? '$totalCount products, $calibratedCount calibrated'
              : '$totalCount products, — calibrated',
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
      hintText: 'Search products or SKUs',
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
