import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_controller.dart';
import 'package:look_atlas/services/service_providers.dart';

class DashboardWelcomePreferences {
  const DashboardWelcomePreferences({
    required this.collapsed,
    required this.consultDismissed,
    required this.callBooked,
    required this.flipDismissed,
    required this.showRescue,
    this.claiming = false,
  });

  final bool collapsed;
  final bool consultDismissed;
  final bool callBooked;
  final bool flipDismissed;
  final bool showRescue;
  final bool claiming;

  DashboardWelcomePreferences copyWith({
    bool? collapsed,
    bool? consultDismissed,
    bool? callBooked,
    bool? flipDismissed,
    bool? showRescue,
    bool? claiming,
  }) => DashboardWelcomePreferences(
    collapsed: collapsed ?? this.collapsed,
    consultDismissed: consultDismissed ?? this.consultDismissed,
    callBooked: callBooked ?? this.callBooked,
    flipDismissed: flipDismissed ?? this.flipDismissed,
    showRescue: showRescue ?? this.showRescue,
    claiming: claiming ?? this.claiming,
  );
}

class DashboardWelcomeController extends Notifier<DashboardWelcomePreferences> {
  static const rescueDelay = Duration(minutes: 10);

  String? _userId;
  Timer? _timer;
  bool _claiming = false;
  bool _introRedirectAttempted = false;

  @override
  DashboardWelcomePreferences build() {
    ref.onDispose(() => _timer?.cancel());
    _userId = ref.watch(authStateProvider).value?.id;
    final userId = _userId;
    if (userId == null) return _defaults;
    final store = ref.read(keyValueStoreProvider);
    bool read(String key) {
      try {
        return store.getBool('$key:$userId') ?? false;
      } on Object {
        return false;
      }
    }

    return DashboardWelcomePreferences(
      collapsed: read('la_welcome_seen') || read('la_welcome_dismissed'),
      consultDismissed: read('la_welcome_consult_dismissed'),
      callBooked: read('la_welcome_call_booked'),
      flipDismissed: read('la_welcome_flip_dismissed'),
      showRescue: false,
    );
  }

  Future<void> markSeen() => _write('la_welcome_seen', true);

  bool shouldOpenIntro(DashboardWelcomeState welcome) {
    if (_introRedirectAttempted ||
        welcome.introSeen ||
        !welcome.profileFullyEmpty ||
        (welcome.steps[DashboardWelcomeStepId.firstShoot] ?? false)) {
      return false;
    }
    final userId = _userId;
    if (userId == null) return false;
    try {
      if (ref
              .read(keyValueStoreProvider)
              .getBool('la_welcome_intro_done:$userId') ??
          false) {
        return false;
      }
    } on Object {
      // The in-memory guard below prevents loops when storage is unavailable.
    }
    _introRedirectAttempted = true;
    return true;
  }

  Future<void> collapse({bool skipped = false}) async {
    state = state.copyWith(collapsed: true);
    await _write(skipped ? 'la_welcome_dismissed' : 'la_welcome_seen', true);
    _track(skipped ? 'welcome.dismissed' : 'welcome.collapsed');
  }

  Future<void> expand() async {
    state = state.copyWith(collapsed: false);
    await _write('la_welcome_dismissed', false);
  }

  Future<void> dismissConsult() async {
    state = state.copyWith(consultDismissed: true, showRescue: false);
    await _write('la_welcome_consult_dismissed', true);
    _track('welcome.consult_dismissed');
  }

  Future<void> confirmCallBooked() async {
    state = state.copyWith(callBooked: true, showRescue: false);
    await _write('la_welcome_call_booked', true);
    await _recordServerEvent('welcome.call_booked');
    _track('welcome.call_booked');
  }

  Future<void> dismissFlip() async {
    state = state.copyWith(flipDismissed: true);
    await _write('la_welcome_flip_dismissed', true);
    await _recordServerEvent('welcome.flip_dismissed');
    _track('welcome.flip_dismissed');
    _refreshWelcome();
  }

  void syncRescue(DashboardWelcomeState welcome) {
    _syncCompletedSteps(welcome);
    final zeroKeepers =
        welcome.campaign != null && welcome.campaign!.keptImages == 0;
    if (state.consultDismissed ||
        state.callBooked ||
        (welcome.checklistComplete && !zeroKeepers)) {
      _timer?.cancel();
      if (state.showRescue) state = state.copyWith(showRescue: false);
      return;
    }
    final active = DashboardWelcomeStepId.values
        .where((id) => welcome.steps[id] != true)
        .firstOrNull;
    final rescueKey = zeroKeepers
        ? 'zero:${welcome.campaign!.jobId}'
        : 'step:${active?.name ?? 'complete'}';
    final userId = _userId;
    if (userId == null) return;
    final store = ref.read(keyValueStoreProvider);
    final baselineKey = zeroKeepers
        ? 'la_welcome_zero_keepers_started:$userId'
        : 'la_welcome_step_started:$userId';
    List<String>? saved;
    try {
      saved = store.getString(baselineKey)?.split('|');
    } on Object {
      return;
    }
    DateTime startedAt;
    if (saved == null || saved.length != 2 || saved.first != rescueKey) {
      startedAt = DateTime.now();
      unawaited(
        store.setString(
          baselineKey,
          '$rescueKey|${startedAt.toIso8601String()}',
        ),
      );
    } else {
      startedAt = DateTime.tryParse(saved.last) ?? DateTime.now();
    }
    final remaining = rescueDelay - DateTime.now().difference(startedAt);
    if (remaining <= Duration.zero) {
      if (!state.showRescue) {
        state = state.copyWith(showRescue: true);
        _track('welcome.rescue_shown', {
          'reason': rescueKey.startsWith('zero:')
              ? 'zero_keepers'
              : 'stuck_on_step',
        });
      }
      return;
    }
    _timer?.cancel();
    _timer = Timer(remaining, () => state = state.copyWith(showRescue: true));
  }

  Future<bool> claimChecklist() async {
    final userId = _userId;
    if (userId == null || _claiming) return false;
    _claiming = true;
    state = state.copyWith(claiming: true);
    try {
      final result = await ref
          .read(welcomeRepositoryProvider)
          .claimChecklist(userId);
      if (result.isErr) return false;
      _track('welcome.reward_claimed', {'kind': 'checklist'});
      await ref.read(studioSchoolControllerProvider.notifier).refresh();
      return true;
    } finally {
      _claiming = false;
      state = state.copyWith(claiming: false);
    }
  }

  void _syncCompletedSteps(DashboardWelcomeState welcome) {
    final userId = _userId;
    if (userId == null) return;
    final store = ref.read(keyValueStoreProvider);
    final key = 'la_welcome_steps_seen:$userId';
    final completed = [
      for (final entry in welcome.steps.entries)
        if (entry.value) entry.key.name,
    ];
    List<String>? seen;
    try {
      seen = store.getStringList(key);
    } on Object {
      return;
    }
    if (seen case final seenSteps?) {
      for (final step in completed.where((step) => !seenSteps.contains(step))) {
        _track('welcome.step_completed', {'step': step});
      }
    }
    if (seen?.join('|') != completed.join('|')) {
      unawaited(store.setStringList(key, completed));
    }
  }

  Future<void> _write(String key, bool value) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await ref
          .read(keyValueStoreProvider)
          .setBool('$key:$userId', value: value);
    } on Object {
      return;
    }
  }

  void _track(String event, [Map<String, Object>? properties]) => unawaited(
    ref.read(analyticsServiceProvider).track(event, properties: properties),
  );

  Future<void> _recordServerEvent(String event) async {
    final userId = _userId;
    if (userId == null) return;
    await ref.read(welcomeRepositoryProvider).recordEvent(userId, event);
  }

  void _refreshWelcome() => unawaited(
    ref.read(studioSchoolControllerProvider.notifier).refresh(),
  );

  static const _defaults = DashboardWelcomePreferences(
    collapsed: false,
    consultDismissed: false,
    callBooked: false,
    flipDismissed: false,
    showRescue: false,
  );
}

final NotifierProvider<DashboardWelcomeController, DashboardWelcomePreferences>
dashboardWelcomeControllerProvider =
    NotifierProvider.autoDispose<
      DashboardWelcomeController,
      DashboardWelcomePreferences
    >(DashboardWelcomeController.new);
