import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';

class LearningCreditBalanceController extends Notifier<int?> {
  @override
  int? build() {
    ref.watch(authStateProvider.select((value) => value.value?.id));
    ref.listen(dashboardStatsProvider, (_, next) {
      if (!next.isLoading && next.asData != null) state = null;
    });
    return null;
  }

  void applyReward(int granted) {
    final credits = ref.read(dashboardStatsProvider).value?.credits;
    if (credits != null && granted > 0) state = credits + granted;
  }
}

final NotifierProvider<LearningCreditBalanceController, int?>
learningCreditBalanceProvider =
    NotifierProvider.autoDispose<LearningCreditBalanceController, int?>(
      LearningCreditBalanceController.new,
    );
