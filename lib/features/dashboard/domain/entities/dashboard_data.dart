class DashboardStats {
  const DashboardStats({
    required this.credits,
    required this.creditsTotal,
    required this.creditsUsed,
    required this.totalRenders,
    required this.activeJobs,
    required this.completedJobs,
  });

  final int credits;
  final int creditsTotal;
  final int creditsUsed;
  final int totalRenders;
  final int activeJobs;
  final int completedJobs;
}

class DashboardRecentJob {
  const DashboardRecentJob({
    required this.id,
    required this.name,
    required this.status,
    required this.renders,
    required this.productThumbnail,
    required this.modelThumbnail,
    this.date,
    this.heroImage = '',
    this.progress = 0,
    this.currentStep,
    this.updatedAt,
    this.completedAt,
    this.reviewedAt,
    this.estimatedCompletion,
  });

  final String id;
  final String name;
  final String status;
  final int renders;
  final DateTime? date;
  final String productThumbnail;
  final String modelThumbnail;
  final String heroImage;
  final int progress;
  final String? currentStep;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? reviewedAt;
  final DateTime? estimatedCompletion;
}

class DashboardSubscription {
  const DashboardSubscription({
    required this.status,
    required this.cancelAtPeriodEnd,
    required this.accessTier,
    required this.proUpsellActive,
    this.proUpsellExpiresAt,
  });

  final String status;
  final bool cancelAtPeriodEnd;
  final String accessTier;
  final bool proUpsellActive;
  final DateTime? proUpsellExpiresAt;

  bool get needsPaymentUpdate => status == 'past_due' || status == 'unpaid';
}
