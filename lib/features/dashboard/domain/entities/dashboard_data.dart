import 'package:flutter/foundation.dart';

@immutable
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

@immutable
class DashboardRecentJob {
  const DashboardRecentJob({
    required this.id,
    required this.name,
    required this.status,
    required this.renders,
    required this.productThumbnail,
    required this.modelThumbnail,
    this.date,
  });

  final String id;
  final String name;
  final String status;
  final int renders;
  final DateTime? date;
  final String productThumbnail;
  final String modelThumbnail;
}

@immutable
class DashboardSubscription {
  const DashboardSubscription({
    required this.status,
    required this.cancelAtPeriodEnd,
    required this.accessTier,
    required this.proUpsellActive,
  });

  final String status;
  final bool cancelAtPeriodEnd;
  final String accessTier;
  final bool proUpsellActive;

  bool get needsPaymentUpdate => status == 'past_due' || status == 'unpaid';
}
