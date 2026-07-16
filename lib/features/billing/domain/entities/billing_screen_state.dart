part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

enum _BillingPlan { starter, pro, business }

enum _BillingCycle { monthly, yearly }

enum _BillingAction {
  idle,
  purchasing,
  purchaseSuccess,
  changingPlan,
  planChangeSuccess,
  cancelling,
  cancellationSuccess,
}

enum _CancellationReason {
  tooExpensive('Too expensive'),
  notUsingEnough('Not using it enough'),
  betterAlternative('Found a better alternative'),
  technicalIssues('Technical issues'),
  noLongerNeeded("Don't need it anymore"),
  other('Other');

  const _CancellationReason(this.label);

  final String label;
}

class _BillingPlanDetails {
  const _BillingPlanDetails({
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.credits,
    required this.tagline,
    required this.features,
    this.excludedFeatures = const [],
    this.isPopular = false,
  });

  final String name;
  final double monthlyPrice;
  final double yearlyPrice;
  final int credits;
  final String tagline;
  final List<String> features;
  final List<String> excludedFeatures;
  final bool isPopular;

  double priceFor(_BillingCycle cycle) => switch (cycle) {
    _BillingCycle.monthly => monthlyPrice,
    _BillingCycle.yearly => yearlyPrice,
  };
}

extension on _BillingPlan {
  double get annualPrice => switch (this) {
    _BillingPlan.starter => 490,
    _BillingPlan.pro => 990,
    _BillingPlan.business => 1790,
  };
}

class _BillingHistoryEntry {
  const _BillingHistoryEntry({
    required this.date,
    required this.description,
    required this.amount,
    required this.credits,
    required this.balance,
  });

  final String date;
  final String description;
  final String amount;
  final String credits;
  final String balance;
}

class _BillingCancellationState {
  const _BillingCancellationState({
    this.scheduled = false,
    this.reason,
    this.feedback = '',
  });

  final bool scheduled;
  final _CancellationReason? reason;
  final String feedback;

  _BillingCancellationState copyWith({
    bool? scheduled,
    _CancellationReason? reason,
    bool clearReason = false,
    String? feedback,
  }) {
    return _BillingCancellationState(
      scheduled: scheduled ?? this.scheduled,
      reason: clearReason ? null : reason ?? this.reason,
      feedback: feedback ?? this.feedback,
    );
  }
}

class _BillingScreenState {
  const _BillingScreenState({
    required this.creditsRemaining,
    required this.currentPlan,
    required this.currentCycle,
    required this.selectedCycle,
    required this.quantity,
    required this.action,
    required this.cancellation,
    required this.historyRefreshing,
  });

  final int creditsRemaining;
  final _BillingPlan currentPlan;
  final _BillingCycle currentCycle;
  final _BillingCycle selectedCycle;
  final int quantity;
  final _BillingAction action;
  final _BillingCancellationState cancellation;
  final bool historyRefreshing;

  _BillingPlanDetails get plan => _billingPlans[currentPlan]!;
  int get monthlyCredits =>
      creditsRemaining > plan.credits ? creditsRemaining : plan.credits;
  int get creditsUsed => monthlyCredits - creditsRemaining;
  int get purchaseCredits => quantity * _creditPackSize;
  double get purchaseTotal => quantity * _creditPackPrice;
  bool get cancellationScheduled => cancellation.scheduled;
  _CancellationReason? get cancellationReason => cancellation.reason;

  _BillingScreenState copyWith({
    int? creditsRemaining,
    _BillingPlan? currentPlan,
    _BillingCycle? currentCycle,
    _BillingCycle? selectedCycle,
    int? quantity,
    _BillingAction? action,
    _BillingCancellationState? cancellation,
    bool? historyRefreshing,
  }) {
    return _BillingScreenState(
      creditsRemaining: creditsRemaining ?? this.creditsRemaining,
      currentPlan: currentPlan ?? this.currentPlan,
      currentCycle: currentCycle ?? this.currentCycle,
      selectedCycle: selectedCycle ?? this.selectedCycle,
      quantity: quantity ?? this.quantity,
      action: action ?? this.action,
      cancellation: cancellation ?? this.cancellation,
      historyRefreshing: historyRefreshing ?? this.historyRefreshing,
    );
  }
}
