import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';

abstract interface class BillingRemoteDataSource {
  Future<Result<List<BillingPlan>>> getPlans();
  Future<Result<List<BillingHistoryEntry>>> getHistory();
  Future<Result<CheckoutSession>> createCheckout(Map<String, Object?> body);
  Future<Result<CheckoutSession>> createOnetimeCheckout(
    Map<String, Object?> body,
  );
  Future<Result<OnetimeVerification>> verifyOnetime(String sessionId);
  Future<Result<ProUpsellOffer?>> getProUpsellOffer();
}

class BillingRemoteDataSourceImpl implements BillingRemoteDataSource {
  const BillingRemoteDataSourceImpl({
    required ApiService api,
    required ApiService publicApi,
  }) : _api = api,
       _publicApi = publicApi;

  final ApiService _api;
  final ApiService _publicApi;

  @override
  Future<Result<List<BillingPlan>>> getPlans() =>
      _publicApi.get<List<BillingPlan>>(
        ApiEndpoints.billingPlans,
        decoder: (data) => [
          for (final item in _map(data)['plans'] as List? ?? const [])
            if (item is Map<String, dynamic>) _plan(item),
        ],
      );

  @override
  Future<Result<List<BillingHistoryEntry>>> getHistory() =>
      _api.get<List<BillingHistoryEntry>>(
        ApiEndpoints.billingHistory,
        decoder: (data) => [
          for (final item in _historyItems(data))
            if (item is Map<String, dynamic>) _historyEntry(item),
        ],
      );

  @override
  Future<Result<CheckoutSession>> createCheckout(
    Map<String, Object?> body,
  ) => _api.post<CheckoutSession>(
    ApiEndpoints.billingCheckoutSession,
    data: body,
    decoder: _checkout,
  );

  @override
  Future<Result<CheckoutSession>> createOnetimeCheckout(
    Map<String, Object?> body,
  ) => _api.post<CheckoutSession>(
    ApiEndpoints.billingOnetimeSession,
    data: body,
    decoder: _checkout,
  );

  @override
  Future<Result<OnetimeVerification>> verifyOnetime(String sessionId) =>
      _api.post<OnetimeVerification>(
        ApiEndpoints.billingOnetimeVerify,
        data: {'sessionId': sessionId},
        decoder: (data) {
          final body = _map(data);
          final offer = body['offer'];
          return OnetimeVerification(
            status: OnetimePaymentStatus.values.firstWhere(
              (value) => value.name == body['status'],
              orElse: () => OnetimePaymentStatus.pending,
            ),
            jobId: body['jobId'] as String?,
            offerExpiresAt: offer is Map<String, dynamic>
                ? DateTime.tryParse(offer['expiresAt'] as String? ?? '')
                : null,
          );
        },
      );

  @override
  Future<Result<ProUpsellOffer?>> getProUpsellOffer() =>
      _api.get<ProUpsellOffer?>(
        ApiEndpoints.billingSubscription,
        decoder: (data) {
          final offer = _map(data)['proUpsellOffer'];
          if (offer is! Map<String, dynamic>) return null;
          return ProUpsellOffer(
            active: offer['active'] as bool? ?? false,
            accepted: offer['accepted'] as bool? ?? false,
            expiresAt: DateTime.tryParse(offer['expiresAt'] as String? ?? ''),
          );
        },
      );

  static CheckoutSession _checkout(dynamic data) {
    final body = _map(data);
    final rawUrl = body['url'];
    final url = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (url == null || !url.hasScheme) {
      throw const FormatException('Checkout response did not include a URL.');
    }
    return CheckoutSession(url: url, mode: body['mode'] as String?);
  }

  static BillingPlan _plan(Map<String, dynamic> json) => BillingPlan(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    tagline: json['tagline'] as String?,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    yearlyPrice: (json['yearlyPrice'] as num?)?.toDouble() ?? 0,
    monthlyCredits: (json['monthlyCredits'] as num?)?.toInt() ?? 0,
    features: _strings(json['features']),
    excludedFeatures: _strings(json['excludedFeatures']),
    priceId: json['priceId'] as String? ?? '',
    yearlyPriceId: json['yearlyPriceId'] as String? ?? '',
    popular: json['popular'] as bool? ?? false,
  );

  static List<dynamic> _historyItems(dynamic data) {
    if (data is List) return data;
    final body = _map(data);
    final items = body['history'] ?? body['items'] ?? body['transactions'];
    return items is List ? items : const [];
  }

  static BillingHistoryEntry _historyEntry(Map<String, dynamic> json) =>
      BillingHistoryEntry(
        occurredAt: _date(
          json['date'] ?? json['createdAt'] ?? json['created_at'],
        ),
        description:
            json['description'] as String? ??
            json['label'] as String? ??
            'Billing transaction',
        amount: _double(json['amount'] ?? json['amountPaid']),
        currencyCode: json['currency'] as String? ?? 'USD',
        credits: _integer(
          json['credits'] ?? json['creditsGranted'] ?? json['creditAmount'],
        ),
        balance: _integer(
          json['balance'] ?? json['balanceAfter'] ?? json['creditBalance'],
        ),
      );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : null;

  static int? _integer(Object? value) => value is num ? value.toInt() : null;

  static List<String> _strings(Object? value) => [
    for (final item in value as List? ?? const [])
      if (item is String) item,
  ];

  static Map<String, dynamic> _map(dynamic data) =>
      data is Map<String, dynamic> ? data : const {};
}
