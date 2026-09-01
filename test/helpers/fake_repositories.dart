import 'dart:async';
import 'dart:typed_data';

import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';
import 'package:look_atlas/features/products/domain/repositories/products_repository.dart';
import 'package:look_atlas/features/subscription/domain/subscription_repository.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/domain/repositories/workshop_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class FakeDashboardRepository implements DashboardRepository {
  const FakeDashboardRepository({
    this.stats = const DashboardStats(
      credits: 142,
      creditsTotal: 200,
      creditsUsed: 58,
      totalRenders: 386,
      activeJobs: 2,
      completedJobs: 18,
    ),
    this.jobs = const [
      DashboardRecentJob(
        id: 'job-bag',
        name: 'Tan Leather Bag',
        status: 'completed',
        renders: 15,
        productThumbnail: 'assets/images/onboarding/showcase-bag-before.jpg',
        modelThumbnail: 'assets/images/onboarding/showcase-dress-after.jpg',
      ),
      DashboardRecentJob(
        id: 'job-heels-processing',
        name: 'Gold Evening Heels',
        status: 'processing',
        renders: 6,
        productThumbnail: 'assets/images/onboarding/showcase-shoes-before.jpg',
        modelThumbnail: 'assets/images/onboarding/showcase-tshirt-after.jpg',
      ),
      DashboardRecentJob(
        id: 'job-heels-failed',
        name: 'Gold Evening Heels',
        status: 'failed',
        renders: 0,
        productThumbnail: 'assets/images/onboarding/showcase-shoes-before.jpg',
        modelThumbnail: 'assets/images/onboarding/showcase-dress-after.jpg',
      ),
    ],
    this.subscription = const DashboardSubscription(
      status: 'active',
      cancelAtPeriodEnd: false,
      accessTier: 'subscriber',
      proUpsellActive: false,
    ),
  });

  final DashboardStats stats;
  final List<DashboardRecentJob> jobs;
  final DashboardSubscription subscription;

  @override
  Future<Result<List<DashboardRecentJob>>> getRecentJobs() async =>
      Result.ok(jobs);

  @override
  Future<Result<DashboardStats>> getStats() async => Result.ok(stats);

  @override
  Future<Result<DashboardSubscription>> getSubscription() async =>
      Result.ok(subscription);
}

class FakeProductsRepository implements ProductsRepository {
  const FakeProductsRepository({this.products = const []});

  final List<ProductCatalogItem> products;

  @override
  Future<Result<ProductCatalogPage>> getProducts(ProductQuery query) async =>
      Result.ok(
        ProductCatalogPage(
          products: products,
          page: 1,
          limit: 20,
          total: products.length,
          totalPages: 1,
        ),
      );

  @override
  Future<Result<Set<String>>> getCalibratedProductIds() async =>
      const Result.ok({});

  @override
  Future<Result<Map<String, ProductCalibrationStatus>>>
  getCalibrationStatuses() async => const Result.ok({});

  @override
  Future<Result<String>> createProduct(CatalogProductDraft draft) async =>
      const Result.ok('product-created');

  @override
  Future<Result<void>> updateProduct(
    String productId,
    CatalogProductDraft draft,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> updatePhotoAngles(
    String productId,
    Map<Object, String?> angles,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> deleteProduct(String productId) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> deletePhoto(String productId, String photoId) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> replacePhoto(
    String productId,
    String photoId,
    ProductUpload photo,
  ) async => const Result.ok(null);

  @override
  Future<Result<ProductCalibrationWorkspace>> loadCalibration(
    String productId,
  ) async => const Result.ok(
    ProductCalibrationWorkspace(
      outlines: [],
      calibration: ProductCalibration(),
      calibratedProducts: [],
    ),
  );

  @override
  Future<Result<void>> uploadWornPhoto(
    String productId,
    ProductUpload photo, {
    required String? calibrationId,
    required String? revision,
    required String mutationId,
  }) async => const Result.ok(null);

  @override
  Future<Result<void>> deleteWornPhoto(
    String productId,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> uploadPlacement(
    String productId,
    ProductUpload cutout,
    Map<String, dynamic> placement,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);

  @override
  Future<Result<CalibrationRender>> startCalibrationRender(
    String productId, {
    required String bodyPreset,
    required String mutationId,
    String? feedback,
    String? previousRenderId,
  }) async => const Result.ok(
    CalibrationRender(id: 'render-1', status: CalibrationRenderStatus.queued),
  );

  @override
  Future<Result<CalibrationRender?>> getLatestCalibrationRender(
    String productId,
  ) async => const Result.ok(null);

  @override
  Future<Result<List<CalibrationRender>>> getCalibrationRenders(
    String productId,
  ) async => const Result.ok([]);

  @override
  Future<Result<void>> approveCalibrationRender(
    String productId,
    String renderId,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> promoteCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> discardCalibrationCandidate(
    String productId,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> saveCalibration(
    String productId,
    ProductCalibrationDraft calibration,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> copyCalibration(
    String targetProductId,
    String sourceProductId,
    CalibrationMutationFence fence,
  ) async => const Result.ok(null);
}

class FakeWorkshopRepository implements WorkshopRepository {
  FakeWorkshopRepository({
    this.active,
    List<WorkshopGeneration> history = const [],
    this.onLoad,
    this.onGenerate,
  }) : history = List.of(history);

  WorkshopGeneration? active;
  final List<WorkshopGeneration> history;
  final Future<Result<WorkshopWorkspace>> Function()? onLoad;
  final Future<Result<WorkshopGeneration>> Function(WorkshopGenerateRequest)?
  onGenerate;
  WorkshopGenerateRequest? lastRequest;
  String? deletedGenerationId;
  int detailCalls = 0;

  @override
  Future<Result<WorkshopWorkspace>> load() async {
    if (onLoad != null) return onLoad!();
    return Result.ok(
      WorkshopWorkspace(active: active, history: List.unmodifiable(history)),
    );
  }

  @override
  Future<Result<WorkshopGeneration?>> getActive() async => Result.ok(active);

  @override
  Future<Result<List<WorkshopGeneration>>> getGenerations() async =>
      Result.ok(List.unmodifiable(history));

  @override
  Future<Result<WorkshopGeneration>> generate(
    WorkshopGenerateRequest request,
  ) async {
    lastRequest = request;
    if (onGenerate != null) return onGenerate!(request);
    final generation = WorkshopGeneration(
      id: 'generated-1',
      status: WorkshopGenerationStatus.completed,
      prompt: request.prompt,
      imageUrl: 'https://example.com/generated.jpg',
      creditCost: 1,
    );
    history
      ..removeWhere((item) => item.id == generation.id)
      ..insert(0, generation);
    return Result.ok(generation);
  }

  @override
  Future<Result<WorkshopGeneration>> getGeneration(
    String generationId,
  ) async {
    detailCalls++;
    return Result.ok(
      history.firstWhere(
        (generation) => generation.id == generationId,
        orElse: () => WorkshopGeneration(
          id: generationId,
          status: WorkshopGenerationStatus.processing,
        ),
      ),
    );
  }

  @override
  Future<Result<void>> deleteGeneration(String generationId) async {
    deletedGenerationId = generationId;
    history.removeWhere((generation) => generation.id == generationId);
    return const Result.ok(null);
  }

  @override
  Future<Result<Uint8List>> downloadImage(String imageUrl) async =>
      Result.ok(Uint8List.fromList(_onePixelPng));
}

const List<int> _onePixelPng = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0,
  0,
  0,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
];

/// In-memory [AuthRepository] for widget and router tests: no storage, no
/// validation, always succeeds. Seed a session via the constructor or the
/// [currentUser] setter.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? user}) : _currentUser = user;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  int restoreCalls = 0;

  @override
  AppUser? get currentUser => _currentUser;

  set currentUser(AppUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<void> restore() async {}

  @override
  Future<Result<AppUser>> verifySession() async {
    restoreCalls++;
    final user = _currentUser;
    return user == null
        ? const Result.err(AuthFailure('No active session.'))
        : Result.ok(user);
  }

  @override
  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    final user = AppUser(id: 'fake-user', email: email);
    currentUser = user;
    return Result.ok(user);
  }

  @override
  Future<Result<AppUser>> signUpWithEmail({
    required String email,
    required String password,
    required String companyName,
    RegisterAttribution? attribution,
    String? captchaToken,
  }) => signInWithEmail(email: email, password: password);

  @override
  Future<Result<AppUser>> signInWithApple() =>
      signInWithEmail(email: 'apple@example.com', password: 'unused');

  @override
  Future<Result<AppUser>> signInWithGoogle() =>
      signInWithEmail(email: 'google@example.com', password: 'unused');

  @override
  Future<Result<void>> resetPassword({required String email}) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> signOut() async {
    currentUser = null;
    return const Result.ok(null);
  }

  @override
  Future<Result<String>> reauthenticateForAccountDeletion({
    required String provider,
    required String material,
  }) async => const Result.ok('fake-deletion-proof');

  @override
  Future<Result<void>> deleteAccount({
    required String email,
    required String confirmation,
    required String reason,
    required String reauthenticationProof,
    required String idempotencyKey,
  }) async {
    currentUser = null;
    return const Result.ok(null);
  }

  @override
  Future<String?> refreshSession() async => 'fake-refreshed-token';

  @override
  Future<void> handleSessionExpired() async => currentUser = null;

  void dispose() => unawaited(_controller.close());
}

/// In-memory [SubscriptionRepository] so screens that watch the subscription
/// state can build without RevenueCat (whose default wiring needs
/// SharedPreferences and platform channels).
///
/// Seed [products] and the [purchaseResult]/[restoreResult] fields to walk
/// the paywall's happy and failure paths. Like the real repository, a
/// successful purchase or restore updates [currentStatus] and is emitted on
/// [statusChanges].
class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({
    this.products = const [],
    this._status = SubscriptionStatus.free,
  });

  /// A premium status matching what a successful purchase would produce.
  static const premiumStatus = SubscriptionStatus(
    isPremium: true,
    activeEntitlements: ['premium'],
    entitlementId: 'premium',
    productId: 'product_monthly',
    willRenew: true,
  );

  List<StoreProduct> products;
  Result<SubscriptionStatus> purchaseResult = const Result.ok(premiumStatus);
  Result<SubscriptionStatus> restoreResult = const Result.ok(premiumStatus);

  SubscriptionStatus _status;
  final _controller = StreamController<SubscriptionStatus>.broadcast();

  @override
  bool get isConfigured => false;

  @override
  Future<void> configure({String? appUserId}) async {}

  @override
  Stream<SubscriptionStatus> statusChanges() => _controller.stream;

  @override
  Future<SubscriptionStatus> currentStatus() async => _status;

  @override
  Future<Result<List<StoreProduct>>> fetchProducts() async =>
      Result.ok(products);

  @override
  Future<Result<SubscriptionStatus>> purchase(StoreProduct product) async =>
      _complete(purchaseResult);

  @override
  Future<Result<SubscriptionStatus>> restore() async =>
      _complete(restoreResult);

  @override
  Future<void> logIn(String userId) async {}

  @override
  Future<void> logOut() async {}

  Result<SubscriptionStatus> _complete(Result<SubscriptionStatus> result) {
    final status = result.valueOrNull;
    if (status != null) {
      _status = status;
      _controller.add(status);
    }
    return result;
  }

  void dispose() => unawaited(_controller.close());
}

/// Builds a purchasable product without platform channels.
StoreProduct fakeProduct({String id = 'product_monthly'}) => StoreProduct(
  id,
  'Full access, billed monthly.',
  'Premium Monthly',
  9.99,
  r'$9.99',
  'USD',
  productCategory: ProductCategory.subscription,
  subscriptionPeriod: 'P1M',
);
