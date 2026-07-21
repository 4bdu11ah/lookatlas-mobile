import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/billing/data/data_sources/billing_remote_data_source.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  test('get_plans_decodes_live_billing_shape', () async {
    final api = _MockApiService();
    final publicApi = _MockApiService();
    when(
      () => publicApi.get<List<BillingPlan>>(
        ApiEndpoints.billingPlans,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as List<BillingPlan> Function(dynamic);
      return Result.ok(
        decoder({
          'plans': [
            {
              'id': 'pro',
              'name': 'Pro',
              'price': 99,
              'yearlyPrice': 950,
              'monthlyCredits': 200,
              'features': ['HD'],
              'excludedFeatures': ['Teams'],
              'priceId': 'price_monthly',
              'yearlyPriceId': 'price_yearly',
              'popular': true,
            },
          ],
        }),
      );
    });
    final dataSource = BillingRemoteDataSourceImpl(
      api: api,
      publicApi: publicApi,
    );

    final result = await dataSource.getPlans();
    final plan = result.valueOrNull!.single;

    expect(plan.id, 'pro');
    expect(plan.yearlyPriceId, 'price_yearly');
    expect(plan.features, ['HD']);
    expect(plan.popular, isTrue);
  });

  test('verify_onetime_decodes_paid_status_and_offer', () async {
    final api = _MockApiService();
    final publicApi = _MockApiService();
    when(
      () => api.post<OnetimeVerification>(
        ApiEndpoints.billingOnetimeVerify,
        data: {'sessionId': 'cs_123'},
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as OnetimeVerification Function(dynamic);
      return Result.ok(
        decoder({
          'status': 'paid',
          'jobId': 'job-1',
          'offer': {'expiresAt': '2026-07-22T12:00:00Z'},
        }),
      );
    });
    final dataSource = BillingRemoteDataSourceImpl(
      api: api,
      publicApi: publicApi,
    );

    final result = await dataSource.verifyOnetime('cs_123');

    expect(result.valueOrNull?.status, OnetimePaymentStatus.paid);
    expect(result.valueOrNull?.jobId, 'job-1');
    expect(result.valueOrNull?.offerExpiresAt, isNotNull);
  });
}
