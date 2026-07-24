import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/shared/widgets/look_atlas_loader.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

class BillingSuccessScreen extends ConsumerStatefulWidget {
  const BillingSuccessScreen({super.key});

  @override
  ConsumerState<BillingSuccessScreen> createState() =>
      _BillingSuccessScreenState();
}

class _BillingSuccessScreenState extends ConsumerState<BillingSuccessScreen> {
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    setState(() => _failure = null);
    final result = await ref.read(completeOnboardingUseCaseProvider)();
    if (!mounted) return;
    if (result case Err(:final failure)) {
      setState(() => _failure = failure);
      return;
    }
    ref.invalidate(onboardingStatusProvider);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Try again', onPressed: _complete),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(body: LookAtlasLoader());
  }
}
