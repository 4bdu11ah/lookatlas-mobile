part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _Shoot {
  const _Shoot({
    required this.id,
    required this.name,
    required this.status,
    required this.renders,
    required this.date,
    required this.productAsset,
    required this.modelAsset,
    this.productSku,
    this.progress = 1,
    this.supportTicketId,
  });

  factory _Shoot.fromJob(ShootJob job) => _Shoot(
    id: job.id,
    name: job.name,
    status: job.isActive ? 'processing' : job.status,
    renders: job.renders,
    date: job.date == null
        ? ''
        : DateFormat.yMMMd().format(job.date!.toLocal()),
    productAsset: job.productThumbnail,
    modelAsset: job.modelThumbnail,
    productSku: job.productSku,
    progress: job.progress,
    supportTicketId: job.supportTicketId,
  );

  final String id;
  final String name;
  final String status;
  final int renders;
  final String date;
  final String productAsset;
  final String modelAsset;
  final String? productSku;
  final double progress;
  final String? supportTicketId;
}
