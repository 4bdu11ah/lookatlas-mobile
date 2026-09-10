import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/products/di/products_providers.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:look_atlas/features/products/domain/repositories/products_repository.dart';
import 'package:look_atlas/features/products/presentation/models/product_view_model.dart';

class ProductsScreenState {
  const ProductsScreenState({
    this.products = const [],
    this.searchQuery = '',
    this.categoryFilter = ProductCategoryFilter.all,
    this.statusFilter = ProductStatusFilter.all,
    this.sortOrder = ProductSortOrder.newest,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.isMutating = false,
    this.categoryBannerDismissed = false,
    this.calibrationStatusesAvailable = true,
    this.failure,
    this.calibrationFailure,
  });

  final List<ProductViewModel> products;
  final String searchQuery;
  final ProductCategoryFilter categoryFilter;
  final ProductStatusFilter statusFilter;
  final ProductSortOrder sortOrder;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isMutating;
  final bool categoryBannerDismissed;
  final bool calibrationStatusesAvailable;
  final Failure? failure;
  final Failure? calibrationFailure;

  int get calibratedCount =>
      products.where((product) => product.calibrated).length;

  List<ProductViewModel> get productsWithoutCategory => products
      .where(
        (product) =>
            product.category.trim().isEmpty ||
            product.category.toLowerCase() == 'other',
      )
      .toList(growable: false);

  ProductsScreenState copyWith({
    List<ProductViewModel>? products,
    String? searchQuery,
    ProductCategoryFilter? categoryFilter,
    ProductStatusFilter? statusFilter,
    ProductSortOrder? sortOrder,
    int? totalCount,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isMutating,
    bool? categoryBannerDismissed,
    bool? calibrationStatusesAvailable,
    Failure? failure,
    Failure? calibrationFailure,
    bool clearFailure = false,
    bool clearCalibrationFailure = false,
  }) {
    return ProductsScreenState(
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
      calibrationStatusesAvailable:
          calibrationStatusesAvailable ?? this.calibrationStatusesAvailable,
      failure: clearFailure ? null : failure ?? this.failure,
      calibrationFailure: clearCalibrationFailure
          ? null
          : calibrationFailure ?? this.calibrationFailure,
    );
  }
}

class ProductsController extends Notifier<ProductsScreenState> {
  Timer? _searchDebounce;
  Timer? _statusRefreshTimer;
  int _requestGeneration = 0;

  ProductsRepository get _repository => ref.read(productsRepositoryProvider);

  @override
  ProductsScreenState build() {
    ref.onDispose(() {
      _searchDebounce?.cancel();
      _statusRefreshTimer?.cancel();
    });
    unawaited(Future.microtask(reload));
    return const ProductsScreenState();
  }

  Future<void> reload() async {
    final generation = ++_requestGeneration;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearFailure: true,
    );
    final useCases = ref.read(productCatalogUseCasesProvider);
    final loaded = await useCases.loadCalibrationContext();
    if (generation != _requestGeneration) return;
    final calibratedResult = loaded.statuses;
    final statuses = calibratedResult.valueOrNull ?? const {};
    final calibrationFailure = calibratedResult.failureOrNull;
    if (calibrationFailure != null) {
      state = state.copyWith(
        statusFilter: ProductStatusFilter.all,
        calibrationStatusesAvailable: false,
        calibrationFailure: calibrationFailure,
      );
    } else {
      state = state.copyWith(
        calibrationStatusesAvailable: true,
        clearCalibrationFailure: true,
      );
    }
    final productsResult = await useCases.load(
      _query(1),
      loaded.calibratedIds,
    );
    if (generation != _requestGeneration) return;
    state = switch (productsResult) {
      Ok(:final value) => state.copyWith(
        products: [
          for (final product in value.products)
            ProductViewModel.fromCatalog(product, statuses),
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
    final useCases = ref.read(productCatalogUseCasesProvider);
    final loaded = await useCases.loadCalibrationContext();
    if (generation != _requestGeneration) return;
    final calibratedResult = loaded.statuses;
    final statuses = calibratedResult.valueOrNull ?? const {};
    final calibrationFailure = calibratedResult.failureOrNull;
    if (calibrationFailure != null) {
      state = state.copyWith(
        statusFilter: ProductStatusFilter.all,
        calibrationStatusesAvailable: false,
        calibrationFailure: calibrationFailure,
      );
    } else {
      state = state.copyWith(
        calibrationStatusesAvailable: true,
        clearCalibrationFailure: true,
      );
    }
    final result = await useCases.load(
      _query(state.currentPage + 1),
      loaded.calibratedIds,
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

  List<ProductViewModel> _appendUnique(
    List<ProductViewModel> current,
    List<ProductCatalogItem> incoming,
    Map<String, ProductCalibrationStatus> statuses,
  ) {
    final ids = {for (final product in current) product.id};
    return [
      ...current,
      for (final product in incoming)
        if (ids.add(product.id))
          ProductViewModel.fromCatalog(product, statuses),
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
        calibrationStatusesAvailable: true,
        clearCalibrationFailure: true,
        products: [
          for (final product in state.products)
            ProductViewModel.fromCatalog(product.item, value),
        ],
      );
    } else if (result case Err(:final failure)) {
      state = state.copyWith(
        statusFilter: ProductStatusFilter.all,
        calibrationStatusesAvailable: false,
        calibrationFailure: failure,
      );
      return;
    }
    _syncStatusPolling();
  }

  ProductQuery _query(int page) => ProductQuery(
    page: page,
    search: state.searchQuery.trim(),
    category: state.categoryFilter.wireValue,
    sort: state.sortOrder.wireValue,
    calibration: state.statusFilter.wireValue,
  );

  void updateSearchQuery(String value) {
    if (value == state.searchQuery) return;
    state = state.copyWith(searchQuery: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), reload);
  }

  void clearSearch() {
    if (state.searchQuery.isEmpty) return;
    _searchDebounce?.cancel();
    state = state.copyWith(searchQuery: '');
    unawaited(reload());
  }

  void updateCategoryFilter(ProductCategoryFilter value) {
    if (value == state.categoryFilter) return;
    state = state.copyWith(categoryFilter: value);
    unawaited(reload());
  }

  void updateStatusFilter(ProductStatusFilter value) {
    if (!state.calibrationStatusesAvailable) return;
    if (value == state.statusFilter) return;
    state = state.copyWith(statusFilter: value);
    unawaited(reload());
  }

  void updateSortOrder(ProductSortOrder value) {
    if (value == state.sortOrder) return;
    state = state.copyWith(sortOrder: value);
    unawaited(reload());
  }

  void applyFilters({
    required ProductCategoryFilter category,
    required ProductStatusFilter status,
    required ProductSortOrder sort,
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
      categoryFilter: ProductCategoryFilter.all,
      statusFilter: ProductStatusFilter.all,
      sortOrder: ProductSortOrder.newest,
    );
    unawaited(reload());
  }

  void dismissCategoryBanner() {
    state = state.copyWith(categoryBannerDismissed: true);
  }

  Future<ProductViewModel?> resolveProduct(String productId) async {
    final loaded = state.products
        .where((product) => product.id == productId)
        .firstOrNull;
    if (loaded != null) return loaded;
    final resolved = await ref
        .read(productCatalogUseCasesProvider)
        .resolve(
          productId,
        );
    if (resolved == null) return null;
    return ProductViewModel.fromCatalog(resolved.product, resolved.statuses);
  }

  Future<Result<void>> createProduct(CatalogProductDraft draft) async {
    if (state.isMutating) {
      return const Err(
        ValidationFailure('Another product action is already running.'),
      );
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    final result = await ref.read(productCatalogUseCasesProvider).create(draft);
    if (result case Err(:final failure)) {
      state = state.copyWith(isMutating: false, failure: failure);
      return Err(failure);
    }
    final canonical = result.valueOrNull;
    state = state.copyWith(isMutating: false, clearFailure: true);
    if (canonical != null) {
      final created = ProductViewModel.fromCatalog(
        canonical.product,
        canonical.statuses,
      );
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
    ProductViewModel product,
    CatalogProductDraft draft,
  ) async {
    if (!draft.hasUpdates) return const Ok(null);
    return _mutate(() => _repository.updateProduct(product.id, draft));
  }

  Future<Result<void>> deleteProduct(ProductViewModel product) =>
      _mutate(() => _repository.deleteProduct(product.id));

  Future<Result<void>> deletePhoto(
    ProductViewModel product,
    String photoId,
  ) async {
    final result = await _mutate(
      () => _repository.deletePhoto(product.id, photoId),
      reloadAfter: false,
    );
    if (result.isOk) unawaited(Future.microtask(reload));
    return result;
  }

  Future<Result<void>> replacePhoto(
    ProductViewModel product,
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

final NotifierProvider<ProductsController, ProductsScreenState>
productsControllerProvider =
    NotifierProvider<ProductsController, ProductsScreenState>(
      ProductsController.new,
    );

enum ProductCategoryFilter {
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

  const ProductCategoryFilter(this.label, this.wireValue);

  final String label;
  final String wireValue;
}

enum ProductStatusFilter {
  all('All products', ''),
  calibrated('Calibrated', 'calibrated'),
  notCalibrated('Non calibrated', 'uncalibrated');

  const ProductStatusFilter(this.label, this.wireValue);

  final String label;
  final String wireValue;
}

enum ProductSortOrder {
  newest('Newest first', 'newest'),
  oldest('Oldest first', 'oldest'),
  nameAsc('Name A-Z', 'name_asc'),
  nameDesc('Name Z-A', 'name_desc');

  const ProductSortOrder(this.label, this.wireValue);

  final String label;
  final String wireValue;
}
