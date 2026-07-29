import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';

abstract interface class DashboardRepository {
  Future<Result<DashboardStats>> getStats();

  Future<Result<List<DashboardRecentJob>>> getRecentJobs();

  Future<Result<DashboardSubscription>> getSubscription();
}
