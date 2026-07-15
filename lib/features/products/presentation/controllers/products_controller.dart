part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductsScreenState {
  const _ProductsScreenState({
    required this.products,
    this.searchQuery = '',
    this.categoryFilter = _ProductCategoryFilter.all,
    this.statusFilter = _ProductStatusFilter.all,
    this.sortOrder = _ProductSortOrder.newest,
  });

  final List<_Product> products;
  final String searchQuery;
  final _ProductCategoryFilter categoryFilter;
  final _ProductStatusFilter statusFilter;
  final _ProductSortOrder sortOrder;

  List<_Product> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();
    return products
        .where((product) {
          if (query.isNotEmpty && !product.matchesSearch(query)) return false;
          if (!categoryFilter.matches(product)) return false;
          if (!statusFilter.matches(product)) return false;
          return true;
        })
        .toList(growable: false)
      ..sort((a, b) => sortOrder.compare(products, a, b));
  }

  int get filteredCalibratedCount => filteredProducts
      .where((product) => product.status == 'Calibrated')
      .length;

  _ProductsScreenState copyWith({
    List<_Product>? products,
    String? searchQuery,
    _ProductCategoryFilter? categoryFilter,
    _ProductStatusFilter? statusFilter,
    _ProductSortOrder? sortOrder,
  }) {
    return _ProductsScreenState(
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class _ProductsController extends Notifier<_ProductsScreenState> {
  @override
  _ProductsScreenState build() => const _ProductsScreenState(
    products: _products,
  );

  void updateSearchQuery(String value) {
    if (value == state.searchQuery) return;
    state = state.copyWith(searchQuery: value);
  }

  void clearSearch() {
    if (state.searchQuery.isEmpty) return;
    state = state.copyWith(searchQuery: '');
  }

  void updateCategoryFilter(_ProductCategoryFilter value) {
    if (value == state.categoryFilter) return;
    state = state.copyWith(categoryFilter: value);
  }

  void updateStatusFilter(_ProductStatusFilter value) {
    if (value == state.statusFilter) return;
    state = state.copyWith(statusFilter: value);
  }

  void updateSortOrder(_ProductSortOrder value) {
    if (value == state.sortOrder) return;
    state = state.copyWith(sortOrder: value);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      categoryFilter: _ProductCategoryFilter.all,
      statusFilter: _ProductStatusFilter.all,
      sortOrder: _ProductSortOrder.newest,
    );
  }
}

final _productsControllerProvider =
    NotifierProvider<_ProductsController, _ProductsScreenState>(
      _ProductsController.new,
    );

enum _ProductCategoryFilter {
  all('All categories'),
  tops('Tops'),
  dresses('Dresses'),
  outerwear('Outerwear'),
  bottoms('Bottoms'),
  bags('Bags'),
  shoes('Shoes'),
  jewelry('Jewelry'),
  eyewear('Eyewear'),
  watches('Watches'),
  accessories('Accessories'),
  other('Other');

  const _ProductCategoryFilter(this.label);

  final String label;

  bool matches(_Product product) => this == all || product.category == label;
}

enum _ProductStatusFilter {
  all('All products'),
  calibrated('Calibrated'),
  notCalibrated('Non calibrated');

  const _ProductStatusFilter(this.label);

  final String label;

  bool matches(_Product product) {
    return switch (this) {
      all => true,
      calibrated => product.status == 'Calibrated',
      notCalibrated => product.status != 'Calibrated',
    };
  }
}

enum _ProductSortOrder {
  newest('Newest first'),
  oldest('Oldest first'),
  nameAsc('Name A-Z'),
  nameDesc('Name Z-A');

  const _ProductSortOrder(this.label);

  final String label;

  int compare(List<_Product> products, _Product a, _Product b) {
    return switch (this) {
      newest => products.indexOf(a).compareTo(products.indexOf(b)),
      oldest => products.indexOf(b).compareTo(products.indexOf(a)),
      nameAsc => a.name.compareTo(b.name),
      nameDesc => b.name.compareTo(a.name),
    };
  }
}
