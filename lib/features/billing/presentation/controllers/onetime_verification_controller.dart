import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/billing/di/billing_api_providers.dart';
import 'package:look_atlas/features/billing/domain/entities/billing_checkout.dart';

@immutable
class OnetimeVerificationState {
  const OnetimeVerificationState({
    this.status = OnetimePaymentStatus.pending,
    this.isPolling = false,
    this.pollCount = 0,
    this.failure,
    this.offerExpiresAt,
  });

  final OnetimePaymentStatus status;
  final bool isPolling;
  final int pollCount;
  final Failure? failure;
  final DateTime? offerExpiresAt;
}

class OnetimeVerificationController extends Notifier<OnetimeVerificationState> {
  static const pollInterval = Duration(seconds: 2);
  static const maxPolls = 10;

  Timer? _timer;
  String? _sessionId;

  @override
  OnetimeVerificationState build() {
    ref.onDispose(() => _timer?.cancel());
    return const OnetimeVerificationState();
  }

  void start(String sessionId) {
    if (sessionId.isEmpty || state.isPolling) return;
    _sessionId = sessionId;
    state = const OnetimeVerificationState(isPolling: true);
    unawaited(_poll());
  }

  Future<void> _poll() async {
    final sessionId = _sessionId;
    if (sessionId == null || state.pollCount >= maxPolls) {
      _stop();
      return;
    }
    final nextCount = state.pollCount + 1;
    final result = await ref.read(verifyOnetimeUseCaseProvider)(sessionId);
    final verification = result.valueOrNull;
    if (verification == null) {
      state = OnetimeVerificationState(
        pollCount: nextCount,
        failure: result.failureOrNull,
      );
      _stop();
      return;
    }
    final terminal = verification.status != OnetimePaymentStatus.pending;
    state = OnetimeVerificationState(
      status: verification.status,
      isPolling: !terminal && nextCount < maxPolls,
      pollCount: nextCount,
      offerExpiresAt: verification.offerExpiresAt,
    );
    if (terminal || nextCount >= maxPolls) {
      _stop();
    } else {
      _timer = Timer(pollInterval, () => unawaited(_poll()));
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (state.isPolling) {
      state = OnetimeVerificationState(
        status: state.status,
        pollCount: state.pollCount,
        failure: state.failure,
        offerExpiresAt: state.offerExpiresAt,
      );
    }
  }
}

final onetimeVerificationControllerProvider =
    NotifierProvider<OnetimeVerificationController, OnetimeVerificationState>(
      OnetimeVerificationController.new,
    );
