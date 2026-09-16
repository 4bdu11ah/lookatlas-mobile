import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_overview.dart';

abstract interface class DashboardRepository {
  Future<Result<DashboardOverview>> getOverview();

  void cancelOverviewRequest();
  Future<Result<DashboardStats>> getStats();

  Future<Result<List<DashboardRecentJob>>> getRecentJobs();

  Future<Result<DashboardSubscription>> getSubscription();
}
