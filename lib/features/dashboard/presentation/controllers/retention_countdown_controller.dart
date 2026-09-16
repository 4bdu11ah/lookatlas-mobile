import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class RetentionCountdownController extends Notifier<Duration> {
  RetentionCountdownController(this.expiresAt);
  final DateTime expiresAt;
  @override
  Duration build() {
    final now = ref.watch(dashboardClockProvider);
    Duration remaining() {
      final value = expiresAt.difference(now());
      return value.isNegative ? Duration.zero : value;
    }

    final initial = remaining();
    if (initial == Duration.zero) return initial;
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = remaining();
      if (state == Duration.zero) timer.cancel();
    });
    ref.onDispose(timer.cancel);
    return initial;
  }
}

// Riverpod infers the family provider type from the factory.
// ignore: specify_nonobvious_property_types
final retentionCountdownProvider = NotifierProvider.autoDispose
    .family<RetentionCountdownController, Duration, DateTime>(
      RetentionCountdownController.new,
    );
