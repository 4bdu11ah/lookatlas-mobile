import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';
import 'package:look_atlas/features/billing/presentation/controllers/onetime_verification_controller.dart';
import 'package:look_atlas/shared/widgets/app_bottom_sheet.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';

/// Where the one-time purchase flow can land (mockup 12, states A–E).
enum _SuccessPhase { confirming, paid, pending, failed }

/// One-time purchase success screen (dark): confirming spinner, then the
/// "Your shoot is yours" state with a time-limited Pro upsell bottom sheet.
/// Pending and failed states are handled too. "Open my shoot" returns to the
/// authenticated results collection.
class OnetimeSuccessScreen extends ConsumerStatefulWidget {
  const OnetimeSuccessScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  ConsumerState<OnetimeSuccessScreen> createState() =>
      _OnetimeSuccessScreenState();
}

class _OnetimeSuccessScreenState extends ConsumerState<OnetimeSuccessScreen> {
  static const _offerWindow = Duration(hours: 23, minutes: 41);

  _SuccessPhase _phase = _SuccessPhase.confirming;
  Timer? _countdown;
  Duration _offerLeft = _offerWindow;

  @override
  void initState() {
    super.initState();
    final sessionId = widget.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      _phase = _SuccessPhase.failed;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(onetimeVerificationControllerProvider.notifier)
            .start(sessionId);
      });
    }
    _countdown = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _offerLeft -= const Duration(minutes: 1));
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  String get _offerText =>
      '${_offerLeft.inHours}h ${_offerLeft.inMinutes % 60}m';

  void _openShoot() => context.go(AppRoutes.onboardingResults);

  void _showProUpsell() {
    unawaited(
      showAppBottomSheet<void>(
        context,
        backgroundColor: AppColors.transparent,
        barrierColor: AppColors.blackAlpha70,
        builder: (context) => _ProUpsellSheet(
          offerText: _offerText,
          onContinue: () {
            Navigator.of(context).pop();
            context.go('${AppRoutes.onboardingActivate}?upsell=onetime20');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onetimeVerificationControllerProvider, (_, next) {
      final phase = next.failure != null
          ? _SuccessPhase.failed
          : switch (next.status) {
              OnetimePaymentStatus.paid => _SuccessPhase.paid,
              OnetimePaymentStatus.failed ||
              OnetimePaymentStatus.refunded => _SuccessPhase.failed,
              OnetimePaymentStatus.pending when !next.isPolling =>
                _SuccessPhase.pending,
              OnetimePaymentStatus.pending => _SuccessPhase.confirming,
            };
      if (mounted && phase != _phase) setState(() => _phase = phase);
    });
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: switch (_phase) {
            _SuccessPhase.confirming => const _Confirming(),
            _SuccessPhase.paid => _Paid(
              offerText: _offerText,
              onOpenShoot: _openShoot,
              onProOffer: _showProUpsell,
            ),
            _SuccessPhase.pending => _Pending(onDashboard: _openShoot),
            _SuccessPhase.failed => const _Failed(),
          },
        ),
      ),
    );
  }
}

class _Confirming extends StatelessWidget {
  const _Confirming();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          BarSpinner(size: 32, color: AppColors.white),
          Text(
            'Confirming your purchase…',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.whiteAlpha60,
            ),
          ),
        ],
      ),
    );
  }
}

class _Paid extends StatelessWidget {
  const _Paid({
    required this.offerText,
    required this.onOpenShoot,
    required this.onProOffer,
  });

  final String offerText;
  final VoidCallback onOpenShoot;
  final VoidCallback onProOffer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Medallion(),
            const SizedBox(height: 20),
            const Text(
              'Your shoot is yours.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                height: 1.2,
                fontWeight: AppTypography.semiBold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Full-resolution files, no watermark. Yours to use anywhere.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppColors.whiteAlpha70,
              ),
            ),
            const SizedBox(height: 40),
            _WhiteButton(
              label: 'Open my shoot',
              icon: Icons.download,
              onTap: onOpenShoot,
            ),
            const SizedBox(height: 20),
            // Pro upsell banner with the offer countdown.
            Material(
              color: AppColors.whiteAlpha04,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onProOffer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.whiteAlpha10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            const Text(
                              'Your Pro offer is open',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: AppTypography.semiBold,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              '$offerText left to claim 20% off Pro',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.whiteAlpha60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.whiteAlpha60,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({required this.onDashboard});

  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Medallion(),
            const SizedBox(height: 20),
            const Text(
              'Payment received.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                height: 1.2,
                fontWeight: AppTypography.semiBold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your full-resolution downloads will be ready in a moment. '
              "We'll email you the link too.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppColors.whiteAlpha70,
              ),
            ),
            const SizedBox(height: 40),
            _WhiteButton(
              label: 'Go to dashboard',
              icon: Icons.arrow_forward,
              iconTrailing: true,
              onTap: onDashboard,
            ),
          ],
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Payment didn't go through",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: AppTypography.semiBold,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your card was declined. No charge was made. You can try '
                'again or pick a subscription plan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: AppColors.whiteAlpha70,
                ),
              ),
              SizedBox(height: 24),
              _LinkText('Try again', color: AppColors.white),
              SizedBox(height: 8),
              _LinkText('Contact support', color: AppColors.whiteAlpha60),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: color,
        decoration: TextDecoration.underline,
        decorationColor: color,
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.whiteAlpha10,
          border: Border.all(color: AppColors.whiteAlpha20),
        ),
        child: const Icon(Icons.check, size: 28, color: AppColors.white),
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconTrailing = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool iconTrailing;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        height: 1.2,
        fontWeight: AppTypography.semiBold,
        color: AppColors.black,
      ),
    );
    final iconWidget = Icon(
      icon,
      size: iconTrailing ? 16 : 20,
      color: AppColors.black,
    );
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: iconTrailing ? [text, iconWidget] : [iconWidget, text],
          ),
        ),
      ),
    );
  }
}

/// The 20%-off Pro upsell bottom sheet (state C).
class _ProUpsellSheet extends StatelessWidget {
  const _ProUpsellSheet({required this.offerText, required this.onContinue});

  final String offerText;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.neutral900,
          border: Border.all(color: AppColors.whiteAlpha15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'PRO OFFER',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        letterSpacing: 1.2,
                        color: AppColors.whiteAlpha50,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.whiteAlpha60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(right: 40),
                child: Text(
                  '20% off Pro — exclusive to your purchase.',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.4,
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '200 photos a month + AI video. 20% off your first month or '
                'first year — your call. Cancel anytime.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.whiteAlpha70,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Offer ends in $offerText.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.whiteAlpha50,
                ),
              ),
              const SizedBox(height: 20),
              _WhiteButton(
                label: 'Continue with Pro at 20% off',
                icon: Icons.arrow_forward,
                iconTrailing: true,
                onTap: onContinue,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Not now, just my shoot',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.whiteAlpha60,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
