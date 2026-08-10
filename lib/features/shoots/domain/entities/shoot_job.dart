import 'package:flutter/foundation.dart';

@immutable
class ShootJob {
  const ShootJob({
    required this.id,
    required this.name,
    required this.status,
    required this.renders,
    required this.date,
    required this.productThumbnail,
    required this.modelThumbnail,
    this.progress = 1,
    this.supportTicketId,
    this.productId,
    this.productSku,
    this.modelId,
    this.modelName,
    this.preset,
    this.aspectRatio,
    this.images = const [],
    this.shots = const [],
    this.hasActiveMediaWork = false,
  });

  final String id;
  final String name;
  final String status;
  final int renders;
  final DateTime? date;
  final String productThumbnail;
  final String modelThumbnail;
  final double progress;
  final String? supportTicketId;
  final String? productId;
  final String? productSku;
  final String? modelId;
  final String? modelName;
  final String? preset;
  final String? aspectRatio;
  final List<ShootImage> images;
  final List<ShootShot> shots;
  final bool hasActiveMediaWork;

  bool get isActive => const {
    'pending',
    'enqueued',
    'processing',
    'retrying',
    'cancel_requested',
  }.contains(status.toLowerCase());

  bool get isCompleted => status.toLowerCase() == 'completed';

  ShootJob copyWith({
    String? status,
    int? renders,
    double? progress,
    List<ShootImage>? images,
    List<ShootShot>? shots,
  }) {
    return ShootJob(
      id: id,
      name: name,
      status: status ?? this.status,
      renders: renders ?? this.renders,
      date: date,
      productThumbnail: productThumbnail,
      modelThumbnail: modelThumbnail,
      progress: progress ?? this.progress,
      supportTicketId: supportTicketId,
      productId: productId,
      productSku: productSku,
      modelId: modelId,
      modelName: modelName,
      preset: preset,
      aspectRatio: aspectRatio,
      images: images ?? this.images,
      shots: shots ?? this.shots,
      hasActiveMediaWork: hasActiveMediaWork,
    );
  }
}

@immutable
class ShootImage {
  const ShootImage({
    required this.id,
    required this.url,
    this.approved = false,
    this.shotIndex = 0,
    this.variationIndex = 0,
    this.status = 'completed',
  });

  final String id;
  final String url;
  final bool approved;
  final int shotIndex;
  final int variationIndex;
  final String status;

  ShootImage copyWith({bool? approved}) => ShootImage(
    id: id,
    url: url,
    approved: approved ?? this.approved,
    shotIndex: shotIndex,
    variationIndex: variationIndex,
    status: status,
  );
}

@immutable
class ShootShot {
  const ShootShot({
    required this.index,
    required this.title,
    required this.description,
    this.images = const [],
  });

  final int index;
  final String title;
  final String description;
  final List<ShootImage> images;
}

@immutable
class ShootPage {
  const ShootPage({
    required this.jobs,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<ShootJob> jobs;
  final int page;
  final int totalPages;
  final int total;
}

@immutable
class ShootProgressStatus {
  const ShootProgressStatus({
    required this.status,
    required this.progress,
    this.currentStep,
    this.estimatedCompletion,
  });

  final String status;
  final double progress;
  final String? currentStep;
  final DateTime? estimatedCompletion;

  bool get isActive => const {
    'pending',
    'enqueued',
    'processing',
    'retrying',
    'cancel_requested',
  }.contains(status.toLowerCase());
}

@immutable
class ShootImageVersion {
  const ShootImageVersion({
    required this.id,
    required this.url,
    required this.label,
    required this.description,
    this.isActive = false,
  });

  final String id;
  final String url;
  final String label;
  final String description;
  final bool isActive;
}

enum ShootImageEditState { pending, processing, completed, failed }
