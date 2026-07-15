part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootsScreenState {
  const _ShootsScreenState({required this.shoots, required this.shotAssets});

  final List<_Shoot> shoots;
  final List<String> shotAssets;
}

class _ShootsController extends Notifier<_ShootsScreenState> {
  @override
  _ShootsScreenState build() => const _ShootsScreenState(
    shoots: _shoots,
    shotAssets: _shotAssets,
  );
}

final _shootsControllerProvider =
    NotifierProvider<_ShootsController, _ShootsScreenState>(
      _ShootsController.new,
    );
