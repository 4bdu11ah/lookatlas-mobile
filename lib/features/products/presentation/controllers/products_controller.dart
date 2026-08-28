part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ProductsScreenState {
  const _ProductsScreenState({
    this.products = const [],
    this.searchQuery = '',
    this.categoryFilter = _ProductCategoryFilter.all,
    this.statusFilter = _ProductStatusFilter.all,
    this.sortOrder = _ProductSortOrder.newest,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.isMutating = false,
    this.categoryBannerDismissed = false,
    this.failure,
  });

  final List<_Product> products;
  final String searchQuery;
  final _ProductCategoryFilter categoryFilter;
  final _ProductStatusFilter statusFilter;
  final _ProductSortOrder sortOrder;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isMutating;
  final bool categoryBannerDismissed;
  final Failure? failure;

  int get calibratedCount =>
      products.where((product) => product.calibrated).length;

  List<_Product> get productsWithoutCategory => products
      .where(
        (product) =>
            product.category.trim().isEmpty ||
            product.category.toLowerCase() == 'other',
      )
      .toList(growable: false);

  _ProductsScreenState copyWith({
    List<_Product>? products,
    String? searchQuery,
    _ProductCategoryFilter? categoryFilter,
    _ProductStatusFilter? statusFilter,
    _ProductSortOrder? sortOrder,
    int? totalCount,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isMutating,
    bool? categoryBannerDismissed,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return _ProductsScreenState(
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      sortOrder: sortOrder ?? this.sortOrder,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMutating: isMutating ?? this.isMutating,
      categoryBannerDismissed:
          categoryBannerDismissed ?? this.categoryBannerDismissed,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

class _ProductsController extends Notifier<_ProductsScreenState> {
  Timer? _searchDebounce;
  Timer? _statusRefreshTimer;
  int _requestGeneration = 0;

  ProductsRepository get _repository => ref.read(productsRepositoryProvider);

  @override
  _ProductsScreenState build() {
    ref.onDispose(() {
      _searchDebounce?.cancel();
      _statusRefreshTimer?.cancel();
    });
    unawaited(Future.microtask(reload));
    return const _ProductsScreenState();
  }

  Future<void> reload() async {
    final generation = ++_requestGeneration;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearFailure: true,
    );
    final calibratedResult = await _repository.getCalibrationStatuses();
    if (generation != _requestGeneration) return;
    if (calibratedResult case Err(:final failure)) {
      state = state.copyWith(isLoading: false, failure: failure);
      return;
    }
    final statuses = calibratedResult.valueOrNull!;
    final calibratedIds = {
      for (final entry in statuses.entries)
        if (entry.value.isCalibrated) entry.key,
    };
    final productsResult = await _repository.getProducts(
      _query(1, calibratedIds),
    );
    if (generation != _requestGeneration) return;
    state = switch (productsResult) {
      Ok(:final value) => state.copyWith(
        products: [
          for (final product in value.products)
            _Product.fromCatalog(product, statuses),
        ],
        totalCount: value.total,
        currentPage: value.page,
        totalPages: value.totalPages,
        isLoading: false,
        clearFailure: true,
      ),
      Err(:final failure) => state.copyWith(
        isLoading: false,
        failure: failure,
      ),
    };
    _syncStatusPolling();
  }

  Future<void> loadNextPage() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.currentPage >= state.totalPages) {
      return;
    }
    final generation = ++_requestGeneration;
    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    final calibratedResult = await _repository.getCalibrationStatuses();
    if (generation != _requestGeneration) return;
    if (calibratedResult case Err(:final failure)) {
      state = state.copyWith(isLoadingMore: false, failure: failure);
      return;
    }
    final statuses = calibratedResult.valueOrNull!;
    final calibratedIds = {
      for (final entry in statuses.entries)
        if (entry.value.isCalibrated) entry.key,
    };
    final result = await _repository.getProducts(
      _query(state.currentPage + 1, calibratedIds),
    );
    if (generation != _requestGeneration) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        products: _appendUnique(state.products, value.products, statuses),
        totalCount: value.total,
        currentPage: value.page,
        totalPages: value.totalPages,
        isLoadingMore: false,
        clearFailure: true,
      ),
      Err(:final failure) => state.copyWith(
        isLoadingMore: false,
        failure: failure,
      ),
    };
    _syncStatusPolling();
  }

  List<_Product> _appendUnique(
    List<_Product> current,
    List<ProductCatalogItem> incoming,
    Map<String, ProductCalibrationStatus> statuses,
  ) {
    final ids = {for (final product in current) product.id};
    return [
      ...current,
      for (final product in incoming)
        if (ids.add(product.id)) _Product.fromCatalog(product, statuses),
    ];
  }

  void _syncStatusPolling() {
    final shouldPoll = state.products.any(
      (product) => product.calibrationStatus.needsPolling,
    );
    if (!shouldPoll) {
      _statusRefreshTimer?.cancel();
      _statusRefreshTimer = null;
      return;
    }
    _statusRefreshTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_refreshStatuses()),
    );
  }

  Future<void> _refreshStatuses() async {
    final result = await _repository.getCalibrationStatuses();
    if (result case Ok(:final value)) {
      state = state.copyWith(
        products: [
          for (final product in state.products)
            _Product.fromCatalog(product.item, value),
        ],
      );
    } else {
      return;
    }
    _syncStatusPolling();
  }

  ProductQuery _query(int page, Set<String> calibratedIds) => ProductQuery(
    page: page,
    search: state.searchQuery.trim(),
    category: state.categoryFilter.wireValue,
    sort: state.sortOrder.wireValue,
    calibration: state.statusFilter.wireValue,
    calibratedIds: calibratedIds,
  );

  void updateSearchQuery(String value) {
    if (value == state.searchQuery) return;
    state = state.copyWith(searchQuery: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), reload);
  }

  void clearSearch() {
    if (state.searchQuery.isEmpty) return;
    _searchDebounce?.cancel();
    state = state.copyWith(searchQuery: '');
    unawaited(reload());
  }

  void updateCategoryFilter(_ProductCategoryFilter value) {
    if (value == state.categoryFilter) return;
    state = state.copyWith(categoryFilter: value);
    unawaited(reload());
  }

  void updateStatusFilter(_ProductStatusFilter value) {
    if (value == state.statusFilter) return;
    state = state.copyWith(statusFilter: value);
    unawaited(reload());
  }

  void updateSortOrder(_ProductSortOrder value) {
    if (value == state.sortOrder) return;
    state = state.copyWith(sortOrder: value);
    unawaited(reload());
  }

  void applyFilters({
    required _ProductCategoryFilter category,
    required _ProductStatusFilter status,
    required _ProductSortOrder sort,
  }) {
    if (category == state.categoryFilter &&
        status == state.statusFilter &&
        sort == state.sortOrder) {
      return;
    }
    state = state.copyWith(
      categoryFilter: category,
      statusFilter: status,
      sortOrder: sort,
    );
    unawaited(reload());
  }

  void clearFilters() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      searchQuery: '',
      categoryFilter: _ProductCategoryFilter.all,
      statusFilter: _ProductStatusFilter.all,
      sortOrder: _ProductSortOrder.newest,
    );
    unawaited(reload());
  }

  void dismissCategoryBanner() {
    state = state.copyWith(categoryBannerDismissed: true);
  }

  Future<Result<void>> createProduct(CatalogProductDraft draft) async {
    if (state.isMutating) {
      return const Err(
        ValidationFailure('Another product action is already running.'),
      );
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    final result = await _repository.createProduct(draft);
    if (result case Err(:final failure)) {
      state = state.copyWith(isMutating: false, failure: failure);
      return Err(failure);
    }
    final productId = result.valueOrNull!;
    final statuses = await _repository.getCalibrationStatuses();
    final canonical = await _repository.getProducts(
      ProductQuery(productId: productId, limit: 1),
    );
    state = state.copyWith(isMutating: false, clearFailure: true);
    if (canonical case Ok(:final value) when value.products.isNotEmpty) {
      final statusMap = statuses.valueOrNull ?? const {};
      final created = _Product.fromCatalog(value.products.first, statusMap);
      state = state.copyWith(
        products: [
          created,
          ...state.products.where((item) => item.id != created.id),
        ],
        totalCount:
            state.totalCount +
            (state.products.any((item) => item.id == created.id) ? 0 : 1),
      );
    } else {
      await reload();
    }
    return const Ok(null);
  }

  Future<Result<void>> updateProduct(
    _Product product,
    CatalogProductDraft draft,
  ) async {
    final updated = await _mutate(
      () => _repository.updateProduct(product.id, draft),
      reloadAfter: draft.photos.isNotEmpty && draft.viewAngles.isEmpty,
    );
    if (updated case Err()) return updated;
    if (draft.viewAngles.isNotEmpty || draft.existingPhotoAngles.isNotEmpty) {
      return _mutate(
        () => _repository.updatePhotoAngles(product.id, {
          ...draft.existingPhotoAngles,
          ...draft.viewAngles,
        }),
      );
    }
    if (draft.photos.isEmpty) _applyMetadataUpdate(product, draft);
    return updated;
  }

  void _applyMetadataUpdate(_Product product, CatalogProductDraft draft) {
    final updated = _Product(
      item: ProductCatalogItem(
        id: product.item.id,
        name: draft.name,
        sku: product.item.sku,
        description: draft.description,
        category: draft.category,
        subCategory: draft.subCategory.isEmpty ? null : draft.subCategory,
        createdAt: product.item.createdAt,
        thumbnail: product.item.thumbnail,
        photos: product.item.photos,
      ),
      calibrationStatus: product.calibrationStatus,
    );
    state = state.copyWith(
      products: [
        for (final item in state.products)
          if (item.id == product.id) updated else item,
      ],
    );
  }

  Future<Result<void>> deleteProduct(_Product product) =>
      _mutate(() => _repository.deleteProduct(product.id));

  Future<Result<void>> deletePhoto(_Product product, String photoId) async {
    final result = await _mutate(
      () => _repository.deletePhoto(product.id, photoId),
      reloadAfter: false,
    );
    if (result.isOk) unawaited(Future.microtask(reload));
    return result;
  }

  Future<Result<void>> replacePhoto(
    _Product product,
    ProductPhoto photo,
    ProductUpload replacement,
  ) => _mutate(
    () => _repository.replacePhoto(product.id, photo.id, replacement),
  );

  Future<Result<void>> _mutate(
    Future<Result<void>> Function() operation, {
    bool reloadAfter = true,
  }) async {
    if (state.isMutating) {
      return const Err(
        ValidationFailure('Another product action is already running.'),
      );
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    final result = await operation();
    if (result case Err(:final failure)) {
      state = state.copyWith(isMutating: false, failure: failure);
      return result;
    }
    state = state.copyWith(isMutating: false, clearFailure: true);
    if (reloadAfter) await reload();
    return const Ok(null);
  }
}

final NotifierProvider<_ProductsController, _ProductsScreenState>
_productsControllerProvider =
    NotifierProvider<_ProductsController, _ProductsScreenState>(
      _ProductsController.new,
    );

enum _ProductCategoryFilter {
  all('All categories', ''),
  tops('Tops', 'Tops'),
  dresses('Dresses', 'Dresses'),
  outerwear('Outerwear', 'Outerwear'),
  bottoms('Bottoms', 'Bottoms'),
  bags('Bags', 'Bags'),
  shoes('Shoes', 'Shoes'),
  jewelry('Jewelry', 'Jewelry'),
  eyewear('Eyewear', 'Eyewear'),
  watches('Watches', 'Watches'),
  accessories('Accessories', 'Accessories'),
  other('Other', 'Other');

  const _ProductCategoryFilter(this.label, this.wireValue);

  final String label;
  final String wireValue;
}

enum _ProductStatusFilter {
  all('All products', ''),
  calibrated('Calibrated', 'calibrated'),
  notCalibrated('Non calibrated', 'uncalibrated');

  const _ProductStatusFilter(this.label, this.wireValue);

  final String label;
  final String wireValue;
}

enum _ProductSortOrder {
  newest('Newest first', 'newest'),
  oldest('Oldest first', 'oldest'),
  nameAsc('Name A-Z', 'name_asc'),
  nameDesc('Name Z-A', 'name_desc');

  const _ProductSortOrder(this.label, this.wireValue);

  final String label;
  final String wireValue;
}
