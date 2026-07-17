part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootsScreenState {
  const _ShootsScreenState({
    required this.shoots,
    required this.shotAssets,
    this.query = '',
    this.status = 'all',
    this.selectedIndex = 0,
    this.approvedAssets = const {'$_img/showcase-bag-after.jpg'},
  });

  final List<_Shoot> shoots;
  final List<String> shotAssets;
  final String query;
  final String status;
  final int selectedIndex;
  final Set<String> approvedAssets;

  List<_Shoot> get visibleShoots {
    final normalizedQuery = query.trim().toLowerCase();
    return shoots
        .where((shoot) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              shoot.name.toLowerCase().contains(normalizedQuery);
          final matchesStatus = status == 'all' || shoot.status == status;
          return matchesQuery && matchesStatus;
        })
        .toList(growable: false);
  }

  _Shoot get selectedShoot => shoots[selectedIndex];

  _ShootsScreenState copyWith({
    String? query,
    String? status,
    int? selectedIndex,
    Set<String>? approvedAssets,
  }) {
    return _ShootsScreenState(
      shoots: shoots,
      shotAssets: shotAssets,
      query: query ?? this.query,
      status: status ?? this.status,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      approvedAssets: approvedAssets ?? this.approvedAssets,
    );
  }
}

class _ShootsController extends Notifier<_ShootsScreenState> {
  @override
  _ShootsScreenState build() => const _ShootsScreenState(
    shoots: _shoots,
    shotAssets: _shotAssets,
  );

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setStatus(String status) {
    state = state.copyWith(status: status);
  }

  void selectShoot(_Shoot shoot) {
    state = state.copyWith(selectedIndex: state.shoots.indexOf(shoot));
  }

  void toggleApproval(String asset) {
    final approved = {...state.approvedAssets};
    approved.contains(asset) ? approved.remove(asset) : approved.add(asset);
    state = state.copyWith(approvedAssets: approved);
  }
}

final _shootsControllerProvider =
    NotifierProvider<_ShootsController, _ShootsScreenState>(
      _ShootsController.new,
    );
