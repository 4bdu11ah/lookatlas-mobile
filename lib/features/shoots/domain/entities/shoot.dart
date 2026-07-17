part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _Shoot {
  const _Shoot({
    required this.name,
    required this.status,
    required this.renders,
    required this.date,
    required this.productAsset,
    required this.modelAsset,
    this.progress = 1,
    this.supportTicketId,
  });

  final String name;
  final String status;
  final int renders;
  final String date;
  final String productAsset;
  final String modelAsset;
  final double progress;
  final String? supportTicketId;
}
