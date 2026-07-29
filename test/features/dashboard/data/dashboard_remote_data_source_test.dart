import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/dashboard/data/data_sources/dashboard_remote_data_source.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late DashboardRemoteDataSource dataSource;

  setUp(() {
    api = _MockApiService();
    dataSource = DashboardRemoteDataSourceImpl(api: api);
  });

  test('get_stats_decodes_dashboard_totals', () async {
    when(
      () => api.get<DashboardStats>(
        ApiEndpoints.dashboardStats,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as DashboardStats Function(
                dynamic,
              );
      return Result.ok(
        decoder({
          'credits': 80,
          'creditsTotal': 100,
          'creditsUsed': 20,
          'totalRenders': 35,
          'activeJobs': 2,
          'completedJobs': 5,
        }),
      );
    });

    final stats = (await dataSource.getStats()).valueOrNull!;

    expect(stats.credits, 80);
    expect(stats.creditsTotal, 100);
    expect(stats.creditsUsed, 20);
    expect(stats.totalRenders, 35);
    expect(stats.activeJobs, 2);
    expect(stats.completedJobs, 5);
  });

  test('get_recent_jobs_decodes_job_rows', () async {
    when(
      () => api.get<List<DashboardRecentJob>>(
        ApiEndpoints.dashboardRecentJobs,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as List<DashboardRecentJob> Function(dynamic);
      return Result.ok(
        decoder({
          'jobs': [
            {
              'id': 'job-1',
              'name': 'Product-Model',
              'status': 'completed',
              'renders': 8,
              'date': '2026-07-28T10:30:00Z',
              'productThumbnail': 'https://example.com/product.jpg',
              'modelThumbnail': 'https://example.com/model.jpg',
            },
          ],
        }),
      );
    });

    final job = (await dataSource.getRecentJobs()).valueOrNull!.single;

    expect(job.id, 'job-1');
    expect(job.name, 'Product-Model');
    expect(job.status, 'completed');
    expect(job.renders, 8);
    expect(job.date, DateTime.utc(2026, 7, 28, 10, 30));
    expect(job.productThumbnail, 'https://example.com/product.jpg');
    expect(job.modelThumbnail, 'https://example.com/model.jpg');
  });

  test('get_subscription_decodes_access_and_offer_state', () async {
    when(
      () => api.get<DashboardSubscription>(
        ApiEndpoints.billingSubscription,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as DashboardSubscription Function(dynamic);
      return Result.ok(
        decoder({
          'plan': 'pro',
          'status': 'active',
          'currentPeriodEnd': '2026-08-28T00:00:00Z',
          'cancelAtPeriodEnd': false,
          'freeShootUsed': true,
          'onboardingJobStatus': 'completed',
          'accessTier': 'subscriber',
          'firstPaidProductId': 'pro_monthly',
          'proUpsellOffer': {
            'active': true,
            'expiresAt': '2026-07-30T00:00:00Z',
            'accepted': false,
          },
          'billingCycle': 'monthly',
        }),
      );
    });

    final subscription = (await dataSource.getSubscription()).valueOrNull!;

    expect(subscription.status, 'active');
    expect(subscription.accessTier, 'subscriber');
    expect(subscription.cancelAtPeriodEnd, isFalse);
    expect(subscription.proUpsellActive, isTrue);
  });
}
