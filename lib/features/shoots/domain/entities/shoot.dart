part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _Shoot {
  const _Shoot({
    required this.name,
    required this.status,
    required this.renders,
    required this.date,
    required this.productAsset,
    required this.modelAsset,
  });

  final String name;
  final String status;
  final int renders;
  final String date;
  final String productAsset;
  final String modelAsset;
}
