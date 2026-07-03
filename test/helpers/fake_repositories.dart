import 'dart:async';

import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/auth/domain/entities/register_attribution.dart';
import 'package:look_atlas/features/auth/domain/repositories/auth_repository.dart';
import 'package:look_atlas/features/subscription/domain/subscription_repository.dart';
import 'package:look_atlas/features/subscription/domain/subscription_status.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// In-memory [AuthRepository] for widget and router tests: no storage, no
/// validation, always succeeds. Seed a session via the constructor or the
/// [currentUser] setter.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? user}) : _currentUser = user;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

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
  Future<String?> refreshSession() async => 'fake-refreshed-token';

  @override
  Future<void> handleSessionExpired() async => currentUser = null;

  void dispose() => unawaited(_controller.close());
}

/// In-memory [SubscriptionRepository] so screens that watch the subscription
/// state can build without RevenueCat (whose default wiring needs
/// SharedPreferences and platform channels).
///
/// Seed [packages] and the [purchaseResult]/[restoreResult] fields to walk
/// the paywall's happy and failure paths. Like the real repository, a
/// successful purchase or restore updates [currentStatus] and is emitted on
/// [statusChanges].
class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({
    this.packages = const [],
    SubscriptionStatus status = SubscriptionStatus.free,
  }) : _status = status;

  /// A premium status matching what a successful purchase would produce.
  static const premiumStatus = SubscriptionStatus(
    isPremium: true,
    activeEntitlements: ['premium'],
    entitlementId: 'premium',
    productId: 'product_monthly',
    willRenew: true,
  );

  List<Package> packages;
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
  Future<Result<List<Package>>> fetchPackages() async => Result.ok(packages);

  @override
  Future<Result<SubscriptionStatus>> purchase(Package package) async =>
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

/// Builds a purchasable [Package] without platform channels, for paywall
/// widget tests.
Package fakePackage({String id = 'monthly'}) => Package(
  id,
  PackageType.monthly,
  const StoreProduct(
    'product_monthly',
    'Full access, billed monthly.',
    'Premium Monthly',
    9.99,
    r'$9.99',
    'USD',
  ),
  const PresentedOfferingContext('default', null, null),
);
