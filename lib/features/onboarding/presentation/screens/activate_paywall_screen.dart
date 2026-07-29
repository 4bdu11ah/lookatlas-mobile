import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/onboarding/presentation/providers/swipe_controller.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/revenuecat_products_section.dart';
import 'package:look_atlas/features/subscription/di/subscription_providers.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_action.dart';
import 'package:look_atlas/features/subscription/presentation/subscription_controller.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// The dark activate / paywall screen (mockup 11): a short "analyzing your
/// liked looks" loader, then the black paywall with RevenueCat monthly and
/// one-time products.
class ActivatePaywallScreen extends ConsumerStatefulWidget {
  const ActivatePaywallScreen({super.key});

  @override
  ConsumerState<ActivatePaywallScreen> createState() =>
      _ActivatePaywallScreenState();
}

class _ActivatePaywallScreenState extends ConsumerState<ActivatePaywallScreen> {
  bool _analyzing = true;
  Timer? _loader;

  @override
  void initState() {
    super.initState();
    unawaited(_verifySession());
    _loader = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _analyzing = false);
    });
  }

  Future<void> _verifySession() async {
    try {
      await ref.read(authRepositoryProvider).verifySession();
    } on Object {
      // Pricing remains available if local session storage cannot be read.
    }
  }

  @override
  void dispose() {
    _loader?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(subscriptionActionProvider, (_, next) {
      if (next case SubscriptionIdle(:final failure?)) {
        AppSnackBar.showError(context, failure.message);
      }
    });
    final savedCount = ref.watch(swipeControllerProvider).savedCount;
    final savedUrls = [
      for (final image in ref.watch(savedImagesProvider)) image.url,
    ];
    final revenueCatProducts = ref.watch(revenueCatProductsProvider);
    final purchaseAction = ref.watch(subscriptionActionProvider);
    final purchasingProductId = switch (purchaseAction) {
      SubscriptionPurchasing(:final productId) => productId,
      _ => null,
    };
    return Scaffold(
      backgroundColor: AppColors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _analyzing
            ? _AnalyzingLoader(savedCount: savedCount, urls: savedUrls)
            : _Paywall(
                urls: savedUrls,
                revenueCatSection: revenueCatProducts.when(
                  loading: () => RevenueCatProductsSection(
                    isLoading: true,
                    purchasingProductId: purchasingProductId,
                    onPurchase: _purchaseRevenueCatProduct,
                  ),
                  error: (error, _) => RevenueCatProductsSection(
                    errorMessage: error is Failure
                        ? error.message
                        : 'Plans are unavailable right now.',
                    purchasingProductId: purchasingProductId,
                    onPurchase: _purchaseRevenueCatProduct,
                    onRetry: () => ref.invalidate(revenueCatProductsProvider),
                  ),
                  data: (products) => RevenueCatProductsSection(
                    products: products,
                    purchasingProductId: purchasingProductId,
                    onPurchase: _purchaseRevenueCatProduct,
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _purchaseRevenueCatProduct(StoreProduct product) async {
    final purchased = await ref
        .read(subscriptionActionProvider.notifier)
        .purchase(product);
    if (!purchased || !mounted) return;
    AppSnackBar.showSuccess(context, 'Purchase successful.');
    context.go(AppRoutes.billingSuccess);
  }
}

// --- State A: analyzing loader ------------------------------------------------

class _AnalyzingLoader extends StatefulWidget {
  const _AnalyzingLoader({required this.savedCount, required this.urls});

  final int savedCount;
  final List<String> urls;

  @override
  State<_AnalyzingLoader> createState() => _AnalyzingLoaderState();
}

class _AnalyzingLoaderState extends State<_AnalyzingLoader>
    with TickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();
  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  )..forward();
  Timer? _phaseTimer;
  int _phase = 0;

  List<String> get _phases => [
    'Analyzing your ${widget.savedCount} liked looks',
    'Matching your style profile',
    'Building your offer',
  ];

  @override
  void initState() {
    super.initState();
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      setState(() => _phase = (_phase + 1) % _phases.length);
    });
  }

  @override
  void dispose() {
    _orbit.dispose();
    _bar.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft overhead glow.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 0.9,
                colors: [
                  AppColors.whiteAlpha09,
                  AppColors.whiteAlpha03,
                  AppColors.transparent,
                ],
                stops: [0, 0.45, 0.75],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 256,
                    height: 256,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Center glow.
                        Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.whiteAlpha22,
                                AppColors.whiteAlpha06,
                                AppColors.transparent,
                              ],
                              stops: [0, 0.55, 0.8],
                            ),
                          ),
                        ),
                        // Six grayscale look thumbs orbiting the ring.
                        AnimatedBuilder(
                          animation: _orbit,
                          builder: (context, _) => Transform.rotate(
                            angle: _orbit.value * 2 * math.pi,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                for (var i = 0; i < 6; i++)
                                  Transform.translate(
                                    offset: Offset(
                                      math.cos(i * math.pi / 3 - math.pi / 2) *
                                          108,
                                      math.sin(i * math.pi / 3 - math.pi / 2) *
                                          108,
                                    ),
                                    child: Transform.rotate(
                                      angle: -_orbit.value * 2 * math.pi,
                                      child: _LookThumb(
                                        index: i,
                                        url: widget.urls.isEmpty
                                            ? null
                                            : widget.urls[i %
                                                  widget.urls.length],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const _Aperture(),
                        for (final corner in const [
                          Alignment.topLeft,
                          Alignment.topRight,
                          Alignment.bottomLeft,
                          Alignment.bottomRight,
                        ])
                          Align(
                            alignment: corner,
                            child: _Bracket(alignment: corner),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _phases[_phase],
                      key: ValueKey(_phase),
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.3,
                        fontWeight: AppTypography.medium,
                        letterSpacing: -0.22,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PLEASE HOLD',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: AppTypography.medium,
                      letterSpacing: 2.75,
                      color: AppColors.whiteAlpha40,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 240,
                    height: 1,
                    child: AnimatedBuilder(
                      animation: _bar,
                      builder: (context, _) => Stack(
                        children: [
                          const ColoredBox(color: AppColors.whiteAlpha10),
                          FractionallySizedBox(
                            widthFactor: _bar.value,
                            heightFactor: 1,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.whiteAlpha50,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LookThumb extends StatelessWidget {
  const _LookThumb({required this.index, required this.url});

  final int index;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.whiteAlpha15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: index.isEven
              ? const [AppColors.neutral950, AppColors.neutral925]
              : const [AppColors.neutral960, AppColors.neutral940],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.blackAlpha60,
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: url == null
          ? null
          : ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: ShotImage(url!, dark: true),
            ),
    );
  }
}

/// The camera-aperture dot with a pulsing ring.
class _Aperture extends StatefulWidget {
  const _Aperture();

  @override
  State<_Aperture> createState() => _ApertureState();
}

class _ApertureState extends State<_Aperture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.blackAlpha40,
            border: Border.all(color: AppColors.whiteAlpha30),
            boxShadow: [
              BoxShadow(
                color: AppColors.white.withValues(alpha: 0.18 * (1 - t)),
                spreadRadius: 16 * t,
              ),
            ],
          ),
          child: const Center(
            child: SizedBox.square(
              dimension: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.whiteAlpha25);
    return SizedBox.square(
      dimension: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0 ? side : BorderSide.none,
            bottom: alignment.y > 0 ? side : BorderSide.none,
            left: alignment.x < 0 ? side : BorderSide.none,
            right: alignment.x > 0 ? side : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// --- State B: the paywall -------------------------------------------------------

class _Paywall extends StatelessWidget {
  const _Paywall({
    required this.urls,
    required this.revenueCatSection,
  });

  final List<String> urls;
  final Widget revenueCatSection;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _PhotoWall(urls: urls),
        const ColoredBox(color: AppColors.blackAlpha70),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.blackAlpha40,
                AppColors.transparent,
                AppColors.blackAlpha50,
              ],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Keep your shoot going.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    height: 1.05,
                    fontWeight: AppTypography.bold,
                    letterSpacing: -0.72,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You just curated 15 looks. Pick a plan to download them '
                  'in HD and shoot the rest of your catalog this week.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: AppTypography.medium,
                    color: AppColors.whiteAlpha85,
                  ),
                ),
                const SizedBox(height: 14),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: r'Studios charge $50+ per photo. ',
                        style: TextStyle(color: AppColors.whiteAlpha65),
                      ),
                      TextSpan(
                        text: r'Plans below start at $0.22.',
                        style: TextStyle(
                          fontWeight: AppTypography.semiBold,
                          color: AppColors.whiteAlpha90,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _TrustBadge('Full commercial rights'),
                    _TrustBadge('Refund on failed shoots'),
                  ],
                ),
                const SizedBox(height: 22),
                revenueCatSection,
                const SizedBox(height: 48),
                const _Pillars(),
                const SizedBox(height: 32),
                const _TrustFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Three columns of dark placeholder "photos" drifting slowly upward behind
/// the paywall content.
class _PhotoWall extends StatefulWidget {
  const _PhotoWall({required this.urls});

  final List<String> urls;

  @override
  State<_PhotoWall> createState() => _PhotoWallState();
}

class _PhotoWallState extends State<_PhotoWall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 42),
  )..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            final height = MediaQuery.sizeOf(context).height * 1.6;
            final width = MediaQuery.sizeOf(context).width * 1.1;
            return SizedBox(
              width: width,
              height: height,
              child: Row(
                spacing: 8,
                children: [
                  for (var col = 0; col < 3; col++)
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          -_drift.value * 200 * (col.isEven ? 1 : 0.7),
                        ),
                        // The strip is intentionally taller than the screen;
                        // OverflowBox lets it hang past without complaint.
                        child: OverflowBox(
                          maxHeight: double.infinity,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 8,
                            children: [
                              for (var row = 0; row < 10; row++)
                                AspectRatio(
                                  aspectRatio: 3 / 4,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: widget.urls.isEmpty
                                        ? DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: (row + col).isEven
                                                    ? const [
                                                        AppColors.neutral950,
                                                        AppColors.neutral925,
                                                      ]
                                                    : const [
                                                        AppColors.neutral960,
                                                        AppColors.neutral940,
                                                      ],
                                              ),
                                            ),
                                          )
                                        : ShotImage(
                                            widget.urls[(row + col * 3) %
                                                widget.urls.length],
                                            dark: true,
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      background: AppColors.whiteAlpha10,
      border: Border.all(color: AppColors.whiteAlpha20),
      borderRadius: 9999,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          const Icon(Icons.check, size: 14, color: AppColors.white),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.3,
              fontWeight: AppTypography.semiBold,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    required this.padding,
    required this.background,
    required this.border,
    this.borderRadius = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Border border;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(borderRadius: radius),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: background,
              border: border,
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Pillars extends StatelessWidget {
  const _Pillars();

  static const List<(IconData, String, String)> _pillars = [
    (
      Icons.photo_camera_outlined,
      'Replaces your photographer',
      'Studio-grade shots without the day rate',
    ),
    (
      Icons.groups_outlined,
      'Same face every shoot',
      'Consistent models across your catalog',
    ),
    (
      Icons.balance_outlined,
      'Full commercial rights',
      'Use anywhere. Ads, PDP, social.',
    ),
    (
      Icons.grid_view_outlined,
      'Replaces a line item',
      'Cuts cost, not adds another tool',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        for (var i = 0; i < _pillars.length; i += 2)
          // IntrinsicHeight so both cards in a row match the taller one.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                for (var j = i; j < i + 2; j++)
                  Expanded(child: _Pillar(data: _pillars[j])),
              ],
            ),
          ),
      ],
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.data});

  final (IconData, String, String) data;

  @override
  Widget build(BuildContext context) {
    final (icon, title, sub) = data;
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      background: AppColors.whiteAlpha13,
      border: Border.all(color: AppColors.whiteAlpha20),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.whiteAlpha25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.white),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: AppTypography.semiBold,
              letterSpacing: -0.15,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.whiteAlpha80,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      children: [
        _GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          background: AppColors.whiteAlpha13,
          border: Border.all(color: AppColors.whiteAlpha20),
          borderRadius: 60,
          child: const Column(
            spacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Icon(Icons.check, size: 16, color: AppColors.white),
                  Text(
                    'One-tap cancel from Settings',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 6,
                children: [
                  _TrustItem(Icons.check, 'Failed shoots refunded'),
                  _TrustItem(Icons.verified_outlined, '30-day money-back'),
                  _TrustItem(Icons.shield_outlined, 'Secure checkout'),
                ],
              ),
            ],
          ),
        ),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Talk to a human · '),
              TextSpan(
                text: 'support@lookatlas.com',
                style: TextStyle(
                  color: AppColors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.white,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            fontWeight: AppTypography.medium,
            color: AppColors.whiteAlpha85,
          ),
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        Icon(icon, size: 14, color: AppColors.whiteAlpha85),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            height: 1.3,
            fontWeight: AppTypography.semiBold,
            color: AppColors.whiteAlpha85,
          ),
        ),
      ],
    );
  }
}
