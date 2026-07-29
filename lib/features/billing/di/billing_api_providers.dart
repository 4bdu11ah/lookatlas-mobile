import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/billing/data/data_sources/billing_remote_data_source.dart';
import 'package:look_atlas/features/billing/data/repositories/billing_api_repository_impl.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';
import 'package:look_atlas/features/billing/domain/repositories/billing_api_repository.dart';
import 'package:look_atlas/features/billing/domain/use_cases/billing_api_use_cases.dart';

final billingRemoteDataSourceProvider = Provider<BillingRemoteDataSource>(
  (ref) => BillingRemoteDataSourceImpl(
    api: ref.watch(apiServiceProvider),
    publicApi: ref.watch(publicApiServiceProvider),
  ),
);

final billingApiRepositoryProvider = Provider<BillingApiRepository>(
  (ref) => BillingApiRepositoryImpl(ref.watch(billingRemoteDataSourceProvider)),
);

final getBillingPlansUseCaseProvider = Provider<GetBillingPlansUseCase>(
  (ref) => GetBillingPlansUseCase(ref.watch(billingApiRepositoryProvider)),
);
final getBillingHistoryUseCaseProvider = Provider<GetBillingHistoryUseCase>(
  (ref) => GetBillingHistoryUseCase(ref.watch(billingApiRepositoryProvider)),
);
final createBillingCheckoutUseCaseProvider =
    Provider<CreateBillingCheckoutUseCase>(
      (ref) => CreateBillingCheckoutUseCase(
        ref.watch(billingApiRepositoryProvider),
      ),
    );
final createOnetimeCheckoutUseCaseProvider =
    Provider<CreateOnetimeCheckoutUseCase>(
      (ref) => CreateOnetimeCheckoutUseCase(
        ref.watch(billingApiRepositoryProvider),
      ),
    );
final verifyOnetimeUseCaseProvider = Provider<VerifyOnetimeUseCase>(
  (ref) => VerifyOnetimeUseCase(ref.watch(billingApiRepositoryProvider)),
);
final getProUpsellOfferUseCaseProvider = Provider<GetProUpsellOfferUseCase>(
  (ref) => GetProUpsellOfferUseCase(ref.watch(billingApiRepositoryProvider)),
);

final FutureProvider<List<BillingPlan>> billingPlansProvider =
    FutureProvider.autoDispose<List<BillingPlan>>((ref) async {
      final result = await ref.watch(getBillingPlansUseCaseProvider)();
      return result.fold((plans) => plans, (failure) => throw failure);
    });

final FutureProvider<List<BillingHistoryEntry>> billingHistoryProvider =
    FutureProvider.autoDispose<List<BillingHistoryEntry>>((ref) async {
      final result = await ref.watch(getBillingHistoryUseCaseProvider)();
      return result.fold((history) => history, (failure) => throw failure);
    });

final FutureProvider<ProUpsellOffer?> proUpsellOfferProvider =
    FutureProvider.autoDispose<ProUpsellOffer?>((ref) async {
      final result = await ref.watch(getProUpsellOfferUseCaseProvider)();
      return result.fold((offer) => offer, (failure) => throw failure);
    });
