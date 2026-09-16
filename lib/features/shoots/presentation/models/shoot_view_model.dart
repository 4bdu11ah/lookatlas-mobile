import 'package:intl/intl.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';

class ShootViewModel {
  const ShootViewModel({
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
    this.modelName,
    this.directorName,
    this.reviewedAt,
    this.galleryAssets = const [],
  });

  factory ShootViewModel.fromJob(ShootJob job) => ShootViewModel(
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
    modelName: job.modelName,
    directorName: job.directorName ?? job.preset,
    reviewedAt: job.reviewedAt,
    galleryAssets: [
      for (final image
          in job.shots.isEmpty
              ? job.images
              : [for (final shot in job.shots) ...shot.images])
        if (image.url.isNotEmpty) image.url,
    ],
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
  final String? modelName;
  final String? directorName;
  final DateTime? reviewedAt;
  final List<String> galleryAssets;

  bool get isActive => status == 'processing';

  bool get isReady => status == 'completed' && reviewedAt == null;

  bool get needsAttention => const {'failed', 'cancelled'}.contains(status);

  bool get isArchived => reviewedAt != null || needsAttention;
}
