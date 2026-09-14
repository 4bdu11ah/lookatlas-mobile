import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:look_atlas/features/calendar/domain/use_cases/calendar_plan_use_cases.dart';
import 'package:look_atlas/features/calendar/domain/use_cases/validate_calendar_mutation_use_case.dart';

class CalendarSession extends ChangeNotifier {
  CalendarSession(
    this.repo, {
    required this.planUseCases,
    required this.validateMutation,
    this.onRefresh,
    this.now = DateTime.now,
  });
  final CalendarRepository repo;
  final CalendarPlanUseCases planUseCases;
  final ValidateCalendarMutationUseCase validateMutation;
  final DateTime Function() now;
  final VoidCallback? onRefresh;
  final setup = CalendarSetup();
  CalendarOverview? overview;
  String? _overviewFingerprint;
  List<CalendarProduct> products = [];
  CalendarQuote? quote;
  String? error;
  String? actionError;
  String? productError;
  String? quoteError;
  String? notice;
  final Map<String, String> mutationErrors = {};
  final Set<String> busy = {};
  final Set<String> picked = {};
  bool loading = true;
  bool productsLoading = true;
  bool setupOverride = false;
  bool _disposed = false;
  bool _paused = false;
  bool _trailing = false;
  bool _prefilled = false;
  bool _productsLoaded = false;
  String? _selectedPlan;
  Timer? _timer;
  Future<void>? _refresh;
  RequestCancellation _reads = RequestCancellation();
  RequestCancellation? _quoteToken;
  final RequestCancellation _mutations = RequestCancellation();
  bool get isSetup =>
      setupOverride ||
      overview?.plan == null ||
      {'planning', 'plan_failed', 'archived'}.contains(overview?.plan?.status);
  bool get planning => overview?.plan?.status == 'planning';
  bool get revising => overview?.plan?.revision == 'applying';
  void emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    await Future.wait([refresh(), loadProducts()]);
  }

  Future<void> loadProducts() async {
    final token = _reads;
    productsLoading = true;
    productError = null;
    emit();
    try {
      final result = await repo.products(token);
      if (!_disposed && !token.isCancelled) {
        products = result;
        _productsLoaded = true;
      }
    } on Object catch (e) {
      if (!_disposed && !token.isCancelled) productError = e.toString();
    } finally {
      if (identical(token, _reads)) {
        productsLoading = false;
        emit();
      }
    }
  }

  Future<void> refresh() {
    if (_disposed || _paused) return Future.value();
    if (_refresh != null) {
      _trailing = true;
      return _refresh!;
    }
    final completer = Completer<void>();
    _refresh = completer.future;
    unawaited(() async {
      do {
        _trailing = false;
        final token = _reads;
        try {
          final result = await repo.overview(token);
          if (_disposed || _paused) break;
          final fingerprint = jsonEncode(result.json);
          if (fingerprint != _overviewFingerprint) {
            overview = result;
            _overviewFingerprint = fingerprint;
          }
          error = null;
          final plan = result.plan;
          if (!_prefilled && plan != null) {
            setup.prefill(plan);
            _prefilled = true;
          }
          if (plan?.id != _selectedPlan) {
            _selectedPlan = plan?.id;
            picked
              ..clear()
              ..addAll(result.items.map((i) => i.id));
          }
          if (plan?.status == 'planning') setupOverride = false;
          onRefresh?.call();
        } on Object catch (e) {
          if (!_disposed && !token.isCancelled) error = e.toString();
        }
        loading = false;
        emit();
      } while (_trailing && !_disposed && !_paused);
      _refresh = null;
      completer.complete();
      _schedule();
    }());
    return completer.future;
  }

  void _schedule() {
    _timer?.cancel();
    if (_disposed || _paused) return;
    final delay =
        overview?.pollDelay ??
        (error != null ? const Duration(seconds: 5) : null);
    if (delay != null) _timer = Timer(delay, refresh);
  }

  void setPaused({required bool value}) {
    if (_paused == value) return;
    _paused = value;
    _timer?.cancel();
    if (value) {
      _reads.cancel();
      _quoteToken?.cancel();
    } else {
      _reads = RequestCancellation();
      unawaited(refresh());
      if (!_productsLoaded || productError != null) unawaited(loadProducts());
    }
  }

  Future<void> requote() async {
    _quoteToken?.cancel();
    final token = RequestCancellation();
    _quoteToken = token;
    quote = null;
    quoteError = null;
    emit();
    try {
      final result = await repo.quote(setup, token);
      if (!_disposed && !token.isCancelled) quote = result;
    } on Object catch (e) {
      if (!_disposed && !token.isCancelled) quoteError = e.toString();
    } finally {
      if (!token.isCancelled) emit();
    }
  }

  void clearQuote() {
    _quoteToken?.cancel();
    _quoteToken = null;
    quote = null;
    quoteError = null;
  }

  void changeSetup() {
    setupOverride = true;
    clearQuote();
    emit();
  }

  void dismissError() {
    actionError = null;
    emit();
  }

  Future<bool> mutate(
    String key,
    Future<CalendarMutationResult> Function() action, {
    CalendarMutationEntity? requiredEntity,
    bool alreadyBusy = false,
  }) async {
    if (_disposed || (!alreadyBusy && busy.contains(key))) return false;
    if (!alreadyBusy) busy.add(key);
    mutationErrors.remove(key);
    actionError = null;
    emit();
    var success = false;
    try {
      final result = await action();
      if (requiredEntity != null) validateMutation(result, requiredEntity);
      if (result.creditWarning) {
        notice =
            'We’ll create as much as your credits cover and pause the rest.';
      }
      success = true;
    } on Object catch (e) {
      if (!_disposed) {
        actionError = e.toString();
        mutationErrors[key] = e.toString();
      }
    } finally {
      await refresh();
      busy.remove(key);
      emit();
    }
    return success;
  }

  Future<bool> createPlan() async {
    if (planning || setup.validation != null || busy.contains('plan')) {
      return false;
    }
    busy.add('plan');
    emit();
    await requote();
    if (_disposed || quote == null) {
      busy.remove('plan');
      emit();
      return false;
    }
    return mutate(
      'plan',
      () => planUseCases.create(setup, quote, _mutations),
      requiredEntity: CalendarMutationEntity.plan,
      alreadyBusy: true,
    );
  }

  Future<bool> approve() async {
    final plan = overview?.plan;
    if (plan == null || revising) return false;
    final selected = planUseCases.approvalItemIds(
      plan,
      overview!.items,
      picked,
    );
    if (selected.isEmpty) return false;
    return mutate(
      'plan',
      () => planUseCases.approve(plan, selected, _mutations),
    );
  }

  Future<bool> revise(String instruction) async {
    final plan = overview?.plan;
    final normalized = planUseCases.revisionInstruction(instruction);
    if (plan == null || revising || normalized == null) return false;
    return mutate(
      'plan',
      () => planUseCases.revise(plan, normalized, _mutations),
    );
  }

  Future<bool> updatePlan(CalendarJson patch) async {
    final plan = overview?.plan;
    if (plan == null) return false;
    return mutate(
      'plan',
      () => repo.changePlan(
        plan.id,
        'PATCH',
        data: patch,
        cancellation: _mutations,
      ),
      requiredEntity: CalendarMutationEntity.plan,
    );
  }

  Future<bool> itemAction(CalendarItem item, String action) async {
    if (!item.actions.contains(action)) return false;
    return mutate(
      item.id,
      () => repo.changeItem(
        item.id,
        action: action,
        cancellation: _mutations,
      ),
      requiredEntity: CalendarMutationEntity.item,
    );
  }

  Future<bool> updateItem(String itemId, CalendarJson patch) => mutate(
    itemId,
    () => repo.changeItem(
      itemId,
      patch: patch,
      cancellation: _mutations,
    ),
    requiredEntity: CalendarMutationEntity.item,
  );
  Future<bool> addItem(CalendarJson payload) async {
    final plan = overview?.plan;
    if (plan == null) return false;
    return mutate(
      'add',
      () => repo.changePlan(
        plan.id,
        'POST',
        action: 'items',
        data: payload,
        cancellation: _mutations,
      ),
      requiredEntity: CalendarMutationEntity.item,
    );
  }

  Future<bool> connection(String platform, {bool disconnect = false}) async {
    if (!calendarPlatforms.containsKey(platform)) return false;
    return mutate(
      'connection:$platform',
      () async {
        await repo.setConnection(
          platform,
          connected: !disconnect,
          cancellation: _mutations,
        );
        return const CalendarMutationResult(
          hasPlan: false,
          hasItem: false,
          creditWarning: false,
        );
      },
    );
  }

  Future<bool> rollover() async {
    final plan = overview?.plan;
    if (plan == null) return false;
    final success = await mutate(
      'plan',
      () => repo.changePlan(
        plan.id,
        'POST',
        action: 'archive',
        cancellation: _mutations,
      ),
    );
    if (success && !_disposed) {
      setup.prefill(plan, rollover: true);
      setupOverride = true;
      clearQuote();
      emit();
    }
    return success;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _reads.cancel();
    _quoteToken?.cancel();
    _mutations.cancel();
    super.dispose();
  }
}
