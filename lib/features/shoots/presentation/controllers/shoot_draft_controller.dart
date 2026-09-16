import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/shoots/di/shoots_providers.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_draft.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/create_shoot_controller.dart';

const shootDraftAutosaveDelay = Duration(milliseconds: 800);

class ShootDraftsState {
  const ShootDraftsState({
    this.drafts = const [],
    this.activeDraftId,
    this.isLoading = false,
    this.failure,
  });

  final List<ShootDraftSummary> drafts;
  final String? activeDraftId;
  final bool isLoading;
  final Failure? failure;

  ShootDraftsState copyWith({
    List<ShootDraftSummary>? drafts,
    String? activeDraftId,
    bool clearActiveDraft = false,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
  }) => ShootDraftsState(
    drafts: drafts ?? this.drafts,
    activeDraftId: clearActiveDraft
        ? null
        : activeDraftId ?? this.activeDraftId,
    isLoading: isLoading ?? this.isLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class ShootDraftController extends Notifier<ShootDraftsState> {
  Timer? _saveTimer;
  Future<void>? _saveInFlight;
  ShootDraftSnapshot? _pendingSnapshot;
  bool _restoring = false;

  String? get _userId => ref.read(authRepositoryProvider).currentUser?.id;

  @override
  ShootDraftsState build() {
    ref.watch(authStateProvider.select((auth) => auth.value?.id));
    ref.onDispose(() => _saveTimer?.cancel());
    unawaited(Future<void>.microtask(load));
    return const ShootDraftsState(isLoading: true);
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) {
      state = const ShootDraftsState();
      return;
    }
    state = state.copyWith(isLoading: true, clearFailure: true);
    final mirror = _readMirror(userId);
    final result = await ref.read(shootsRepositoryProvider).getShootDrafts();
    if (!ref.mounted || userId != _userId) return;
    final remote = result.valueOrNull ?? const <ShootDraftSummary>[];
    state = state.copyWith(
      drafts: _mergeMirror(remote, mirror),
      isLoading: false,
      failure: result.failureOrNull,
      clearFailure: result.isOk,
    );
  }

  Future<void> initializeEditor(String? draftId) async {
    _saveTimer?.cancel();
    _pendingSnapshot = null;
    final createController = ref.read(createShootControllerProvider.notifier);
    if (draftId == null) {
      state = state.copyWith(clearActiveDraft: true);
      createController.reset();
      return;
    }
    final userId = _userId;
    if (userId == null) return;
    final mirror = _readMirror(userId);
    ShootDraft? remote;
    if (draftId != 'local') {
      final result = await ref
          .read(shootsRepositoryProvider)
          .getShootDraft(draftId);
      if (!ref.mounted) return;
      if (result.failureOrNull case final failure?) {
        state = state.copyWith(isLoading: false, failure: failure);
      }
      remote = result.valueOrNull;
    }
    final useMirror =
        mirror != null &&
        (draftId == 'local' ||
            (mirror.draftId == draftId &&
                (remote == null ||
                    mirror.updatedAt.isAfter(remote.summary.updatedAt))));
    final snapshot = useMirror ? mirror.snapshot : remote?.snapshot;
    if (snapshot == null) return;
    state = state.copyWith(
      activeDraftId: remote?.summary.id ?? mirror?.draftId,
      clearFailure: true,
    );
    _restoring = true;
    try {
      await createController.restoreDraft(snapshot);
    } finally {
      _restoring = false;
    }
  }

  void scheduleSave(CreateShootState createState) {
    if (_restoring || createState.isLoading || !createState.hasChanges) return;
    final userId = _userId;
    if (userId == null) return;
    final snapshot = createState.toDraftSnapshot();
    final mirror = ShootDraftMirror(
      draftId: state.activeDraftId,
      snapshot: snapshot,
      title: createState.selectedProducts.firstOrNull?.name ?? 'Untitled shoot',
      thumbnailUrl: createState.selectedProducts.firstOrNull?.imageUrl ?? '',
      updatedAt: DateTime.now().toUtc(),
    );
    _pendingSnapshot = snapshot;
    unawaited(_writeMirror(userId, mirror));
    _upsert(_summaryFromMirror(mirror));
    _saveTimer?.cancel();
    _saveTimer = Timer(shootDraftAutosaveDelay, () {
      final pending = _pendingSnapshot;
      _pendingSnapshot = null;
      if (pending != null) unawaited(_persist(pending));
    });
  }

  Future<void> flush(CreateShootState createState) async {
    if (!createState.hasChanges) return;
    scheduleSave(createState);
    _saveTimer?.cancel();
    final pending = _pendingSnapshot;
    _pendingSnapshot = null;
    if (pending != null) await _persist(pending);
    final inFlight = _saveInFlight;
    if (inFlight != null) await inFlight;
  }

  Future<bool> delete(String draftId) async {
    if (draftId != 'local') {
      final result = await ref
          .read(shootsRepositoryProvider)
          .deleteShootDraft(draftId);
      if (result.failureOrNull case final failure?) {
        state = state.copyWith(failure: failure);
        return false;
      }
    }
    await _clearMirrorIfMatching(draftId);
    state = state.copyWith(
      drafts: state.drafts.where((draft) => draft.id != draftId).toList(),
      clearActiveDraft: state.activeDraftId == draftId,
      clearFailure: true,
    );
    return true;
  }

  Future<bool> discardActive() async {
    _saveTimer?.cancel();
    _pendingSnapshot = null;
    final inFlight = _saveInFlight;
    if (inFlight != null) await inFlight;
    final draftId = state.activeDraftId;
    final deleted = draftId == null || await delete(draftId);
    if (!deleted) return false;
    await _clearMirror();
    state = state.copyWith(clearActiveDraft: true);
    ref.read(createShootControllerProvider.notifier).reset();
    return true;
  }

  Future<void> completeActive() async {
    _saveTimer?.cancel();
    _pendingSnapshot = null;
    final inFlight = _saveInFlight;
    if (inFlight != null) await inFlight;
    final draftId = state.activeDraftId;
    if (draftId != null) {
      await ref.read(shootsRepositoryProvider).deleteShootDraft(draftId);
    }
    await _clearMirror();
    state = state.copyWith(
      drafts: draftId == null
          ? state.drafts
          : state.drafts.where((draft) => draft.id != draftId).toList(),
      clearActiveDraft: true,
    );
  }

  Future<void> _persist(ShootDraftSnapshot snapshot) async {
    final previous = _saveInFlight ?? Future<void>.value();
    final operation = previous.then((_) => _save(snapshot));
    _saveInFlight = operation;
    await operation;
    if (identical(_saveInFlight, operation)) _saveInFlight = null;
  }

  Future<void> _save(ShootDraftSnapshot snapshot) async {
    final result = await ref
        .read(shootsRepositoryProvider)
        .saveShootDraft(
          snapshot,
          draftId: state.activeDraftId,
        );
    if (!ref.mounted) return;
    if (result.failureOrNull case final failure?) {
      state = state.copyWith(failure: failure);
      return;
    }
    final draft = result.valueOrNull!;
    final draftId = draft.summary.id.isEmpty
        ? state.activeDraftId
        : draft.summary.id;
    if (draftId == null) return;
    final summary = ShootDraftSummary(
      id: draftId,
      title: draft.summary.title,
      currentStep: draft.summary.currentStep,
      thumbnailUrl: draft.summary.thumbnailUrl,
      updatedAt: draft.summary.updatedAt,
    );
    state = state.copyWith(activeDraftId: draftId, clearFailure: true);
    _upsert(summary);
    final userId = _userId;
    final mirror = userId == null ? null : _readMirror(userId);
    if (userId != null && mirror != null) {
      await _writeMirror(
        userId,
        ShootDraftMirror(
          draftId: draftId,
          snapshot: mirror.snapshot,
          title: summary.title,
          thumbnailUrl: summary.thumbnailUrl,
          updatedAt: mirror.updatedAt,
        ),
      );
    }
  }

  void _upsert(ShootDraftSummary summary) {
    final drafts = [
      summary,
      for (final draft in state.drafts)
        if (draft.id != summary.id &&
            !(summary.id != 'local' && draft.id == 'local'))
          draft,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(drafts: drafts);
  }

  List<ShootDraftSummary> _mergeMirror(
    List<ShootDraftSummary> remote,
    ShootDraftMirror? mirror,
  ) {
    if (mirror == null) return remote;
    final local = _summaryFromMirror(mirror);
    final matching = remote.where((draft) => draft.id == local.id).firstOrNull;
    if (matching != null && !local.updatedAt.isAfter(matching.updatedAt)) {
      return remote;
    }
    return [local, ...remote.where((draft) => draft.id != local.id)];
  }

  ShootDraftSummary _summaryFromMirror(ShootDraftMirror mirror) =>
      ShootDraftSummary(
        id: mirror.draftId ?? 'local',
        title: mirror.title,
        currentStep: mirror.snapshot.currentStep,
        thumbnailUrl: mirror.thumbnailUrl,
        updatedAt: mirror.updatedAt,
      );

  ShootDraftMirror? _readMirror(String userId) {
    final raw = ref
        .read(sharedPreferencesProvider)
        .getString(ShootDraftMirror.storageKey(userId));
    if (raw == null) return null;
    try {
      return ShootDraftMirror.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } on Object {
      unawaited(
        ref
            .read(sharedPreferencesProvider)
            .remove(ShootDraftMirror.storageKey(userId)),
      );
      return null;
    }
  }

  Future<void> _writeMirror(String userId, ShootDraftMirror mirror) => ref
      .read(sharedPreferencesProvider)
      .setString(
        ShootDraftMirror.storageKey(userId),
        jsonEncode(mirror.toJson()),
      );

  Future<void> _clearMirror() async {
    final userId = _userId;
    if (userId == null) return;
    await ref
        .read(sharedPreferencesProvider)
        .remove(ShootDraftMirror.storageKey(userId));
  }

  Future<void> _clearMirrorIfMatching(String draftId) async {
    final userId = _userId;
    if (userId == null) return;
    final mirror = _readMirror(userId);
    if (mirror == null) return;
    if ((mirror.draftId ?? 'local') == draftId) await _clearMirror();
  }
}

final NotifierProvider<ShootDraftController, ShootDraftsState>
shootDraftProvider = NotifierProvider<ShootDraftController, ShootDraftsState>(
  ShootDraftController.new,
);
