import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';
import 'package:look_atlas/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:look_atlas/features/onboarding/presentation/screens/billing_success_screen.dart';

void main() {
  testWidgets('billing_success_completes_onboarding_then_opens_home', (
    tester,
  ) async {
    final repository = _CompletionRepository();
    final router = GoRouter(
      initialLocation: AppRoutes.billingSuccess,
      routes: [
        GoRoute(
          path: AppRoutes.billingSuccess,
          builder: (_, _) => const BillingSuccessScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.completeCalls, 1);
    expect(find.text('Home'), findsOneWidget);
  });
}

class _CompletionRepository implements OnboardingRepository {
  int completeCalls = 0;

  @override
  Future<Result<void>> completeOnboarding() async {
    completeCalls++;
    return const Result.ok(null);
  }

  @override
  Future<Result<String>> createProduct(ProductDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Result<String>> createUserModel(UserModelDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Result<OnboardingAppConfig>> fetchAppConfig() =>
      throw UnimplementedError();

  @override
  Future<Result<List<LookAtlasModel>>> fetchModels() =>
      throw UnimplementedError();

  @override
  Future<Result<List<OnboardingProduct>>> fetchProducts() =>
      throw UnimplementedError();

  @override
  Future<Result<OnboardingStatus>> fetchStatus() => throw UnimplementedError();

  @override
  Future<Result<List<OnboardingUserModel>>> fetchUserModels() =>
      throw UnimplementedError();

  @override
  Future<Result<StartShootResponse>> startShoot(StartShootRequest request) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> updateProduct(
    String productId,
    ProductDraft draft,
  ) => throw UnimplementedError();

  @override
  Future<Result<void>> updateProductAngles(
    String productId,
    Map<int, String?> angles,
  ) => throw UnimplementedError();

  @override
  Future<Result<void>> updateStatus(OnboardingTrackingStatus status) =>
      throw UnimplementedError();
}
