import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';

abstract interface class DashboardRemoteDataSource {
  Future<Result<DashboardStats>> getStats();

  Future<Result<List<DashboardRecentJob>>> getRecentJobs();

  Future<Result<DashboardSubscription>> getSubscription();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  const DashboardRemoteDataSourceImpl({required this._api});

  final ApiService _api;

  @override
  Future<Result<DashboardStats>> getStats() => _api.get<DashboardStats>(
    ApiEndpoints.dashboardStats,
    decoder: (data) {
      final body = _map(data);
      return DashboardStats(
        credits: _integer(body['credits']),
        creditsTotal: _integer(body['creditsTotal']),
        creditsUsed: _integer(body['creditsUsed']),
        totalRenders: _integer(body['totalRenders']),
        activeJobs: _integer(body['activeJobs']),
        completedJobs: _integer(body['completedJobs']),
      );
    },
  );

  @override
  Future<Result<List<DashboardRecentJob>>> getRecentJobs() =>
      _api.get<List<DashboardRecentJob>>(
        ApiEndpoints.dashboardRecentJobs,
        decoder: (data) => [
          for (final item in _map(data)['jobs'] as List? ?? const [])
            if (item is Map<String, dynamic>) _recentJob(item),
        ],
      );

  @override
  Future<Result<DashboardSubscription>> getSubscription() =>
      _api.get<DashboardSubscription>(
        ApiEndpoints.billingSubscription,
        decoder: (data) {
          final body = _map(data);
          final offer = body['proUpsellOffer'];
          return DashboardSubscription(
            status: body['status'] as String? ?? '',
            cancelAtPeriodEnd: body['cancelAtPeriodEnd'] as bool? ?? false,
            accessTier: body['accessTier'] as String? ?? 'none',
            proUpsellActive:
                offer is Map<String, dynamic> &&
                (offer['active'] as bool? ?? false),
            proUpsellExpiresAt: offer is Map<String, dynamic>
                ? _date(offer['expiresAt'])
                : null,
          );
        },
      );

  static DashboardRecentJob _recentJob(Map<String, dynamic> json) =>
      DashboardRecentJob(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled shoot',
        status: json['status'] as String? ?? 'pending',
        renders: _integer(json['renders']),
        date: _date(json['date']),
        productThumbnail: json['productThumbnail'] as String? ?? '',
        modelThumbnail: json['modelThumbnail'] as String? ?? '',
      );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static int _integer(Object? value) => value is num ? value.toInt() : 0;

  static Map<String, dynamic> _map(dynamic data) =>
      data is Map<String, dynamic> ? data : const {};
}
