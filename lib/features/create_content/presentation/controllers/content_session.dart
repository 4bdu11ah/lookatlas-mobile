import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/errors/content_api_exception.dart';
import 'package:look_atlas/features/create_content/domain/repositories/content_repository.dart';
import 'package:look_atlas/features/create_content/domain/use_cases/save_content_draft_use_case.dart';
import 'package:look_atlas/features/products/domain/entities/product_catalog.dart';

enum ContentSaveState { saved, saving, unsaved, offline }

/// One session per route. All writes are serialized, and every asynchronous
/// reader is fenced/cancelled when its input or lifecycle changes.
class ContentSession extends ChangeNotifier {
  ContentSession(
    this.repository,
    this.format, {
    required this.saveDraft,
    required this.refreshCredits,
    this.restoreRecovery,
    this.persistRecovery,
  }) : brief = defaultContentBrief(format);
  final ContentRepository repository;
  final SaveContentDraftUseCase saveDraft;
  ContentFormat format;
  final VoidCallback refreshCredits;
  final String? Function()? restoreRecovery;
  final Future<void> Function(String?)? persistRecovery;
  ContentJson brief;
  String? draftId;
  ContentGeneration? generation;
  ContentGeneration? otherActive;
  ContentGeneration? latestCompleted;
  int furthestStep = 1;
  bool restorationFailed = false;
  ContentQuote? quote;
  List<ProductCatalogItem> products = [];
  ProductCatalogItem? selectedProduct;
  String? uploadUrl;
  String? error;
  String? productError;
  String? quoteError;
  String? editError;
  int? paywall;
  bool loading = true;
  bool productsLoading = false;
  bool uploading = false;
  bool submitting = false;
  bool quoteLoading = false;
  bool editBusy = false;
  bool disposed = false;
  bool paused = false;
  String? editJobId;
  int selectedFrame = 0;
  ContentSaveState saveState = ContentSaveState.saved;
  ContentSaveState editSaveState = ContentSaveState.saved;
  ContentJson _pendingDraft = {};
  final Map<String, ContentJson> _pendingFrames = {};
  ContentJson _pendingKit = {};
  Timer? _saveTimer;
  Timer? _searchTimer;
  Timer? _pollTimer;
  Timer? _editTimer;
  Timer? _cropTimer;
  Timer? _captionTimer;
  RequestCancellation? _searchToken;
  RequestCancellation? _quoteToken;
  RequestCancellation? _pollToken;
  RequestCancellation? _editToken;
  final RequestCancellation _restoreToken = RequestCancellation();
  Future<bool>? _save;
  Future<bool>? _editSave;
  Future<void> _recoveryWrite = Future.value();
  int _searchVersion = 0;
  int _quoteVersion = 0;
  int _pollEpoch = 0;
  int _editEpoch = 0;
  bool _polling = false;
  bool _editPolling = false;

  ContentJson get settings => contentObject(brief['settings']);
  int get step => (settings['lastStep'] as num? ?? 1).toInt().clamp(1, 3);
  bool get hasSource =>
      brief['productId'] != null || brief['sourceUploadPath'] != null;
  bool get reviewing => generation?.completed ?? false;
  ContentFrame? get frame => generation == null || generation!.frames.isEmpty
      ? null
      : generation!.frames[selectedFrame.clamp(
          0,
          generation!.frames.length - 1,
        )];
  bool get hasPending =>
      _pendingDraft.isNotEmpty ||
      _pendingFrames.isNotEmpty ||
      _pendingKit.isNotEmpty ||
      _save != null ||
      _editSave != null ||
      uploading ||
      submitting;
  void changed() {
    if (!disposed) notifyListeners();
  }

  void _remember() {
    final snapshot = jsonEncode({
      'draftId': draftId,
      'brief': brief,
      'pendingDraft': _pendingDraft,
      'generationId': generation?.id,
      'pendingFrames': _pendingFrames,
      'pendingKit': _pendingKit,
      'editJobId': editJobId,
      'uploadUrl': uploadUrl,
    });
    _recoveryWrite = _recoveryWrite
        .then((_) async {
          await persistRecovery?.call(snapshot);
        })
        .catchError((Object _) {
          error = 'Local recovery could not be saved. Keep this screen open until your changes are saved.';
          changed();
        });
  }

  Future<void> initialize({String? generationId}) async {
    loading = true;
    restorationFailed = false;
    error = null;
    changed();
    try {
      final stored = restoreRecovery?.call();
      ContentJson? recovery;
      if (stored != null) {
        try {
          recovery = contentObject(jsonDecode(stored));
        } on Object {
          /* Remote draft remains authoritative. */
        }
      }
      if (generationId != null) {
        generation = await repository.generation(
          generationId,
          cancellation: _restoreToken,
        );
        format = generation!.format;
        brief = defaultContentBrief(format);
        final completedDraftId = generation!.data['draftId'] as String?;
        if (generation!.completed && completedDraftId != null) {
          await _deleteCompletedDraft(
            completedDraftId,
            cancellation: _restoreToken,
          );
        }
      } else {
        final results = await Future.wait<Object?>([
          repository.active(cancellation: _restoreToken),
          repository.latest(format, cancellation: _restoreToken),
          repository.history(cancellation: _restoreToken),
        ]);
        if (disposed) return;
        var draft = results[1] as ContentDraft?;
        final history = results[2]! as List<ContentGeneration>;
        latestCompleted = history
            .where(
              (item) =>
                  item.format == format && item.data['source'] != 'runway',
            )
            .firstOrNull;
        if (draft != null &&
            history.any((item) => item.data['draftId'] == draft!.id)) {
          final completedDraftId = draft.id;
          await _deleteCompletedDraft(completedDraftId);
          if (recovery?['draftId'] == completedDraftId) {
            recovery = null;
            await persistRecovery?.call(null);
          }
          draft = null;
        }
        if (draft != null) {
          draftId = draft.id;
          uploadUrl = draft.data['sourceUploadUrl'] as String?;
          brief = {
            ...brief,
            ...Map.fromEntries(
              draft.data.entries.where((e) => brief.containsKey(e.key)),
            ),
            'settings': {...settings, ...contentObject(draft.data['settings'])},
          };
        }
        final active = results[0] as ContentGeneration?;
        if (active != null && active.active) {
          if (active.format == format) {
            generation = active;
          } else {
            otherActive = active;
          }
        }
        if (recovery != null) {
          final pending = contentObject(recovery['pendingDraft']);
          if (pending.isNotEmpty) {
            brief = contentObject(recovery['brief']);
            draftId = recovery['draftId'] as String?;
            _pendingDraft = pending;
            saveState = ContentSaveState.unsaved;
          }
          uploadUrl = recovery['uploadUrl'] as String? ?? uploadUrl;
          final recoveredId = recovery['generationId'] as String?;
          if (generation == null &&
              recoveredId != null &&
              (contentObject(recovery['pendingFrames']).isNotEmpty ||
                  contentObject(recovery['pendingKit']).isNotEmpty ||
                  recovery['editJobId'] != null)) {
            generation = await repository.generation(
              recoveredId,
              cancellation: _restoreToken,
            );
          }
        }
      }
      if (disposed) return;
      furthestStep = step;
      if (recovery != null && recovery['generationId'] == generation?.id) {
        final frames = contentObject(recovery['pendingFrames']);
        for (final entry in frames.entries) {
          _pendingFrames[entry.key] = contentObject(entry.value);
        }
        _pendingKit = contentObject(recovery['pendingKit']);
        editJobId = recovery['editJobId'] as String?;
        editBusy = editJobId != null;
        for (final entry in _pendingFrames.entries) {
          _optimisticFrame(entry.key, entry.value);
        }
        if (_pendingKit.isNotEmpty) _optimisticKit(_pendingKit);
      }
      if (brief['productId'] != null) {
        try {
          final library = await repository.products(
            cancellation: _restoreToken,
          );
          selectedProduct = library
              .where((p) => p.id == brief['productId'])
              .firstOrNull;
        } on Object {
          productError = 'Your product preview could not be loaded.';
        }
      }
      if (generation?.active ?? false) unawaited(pollGeneration());
      if (editJobId != null) unawaited(pollEdit());
      unawaited(loadProducts(''));
      unawaited(requote());
    } on Object catch (e) {
      restorationFailed = true;
      _handle(e);
    }
    loading = false;
    changed();
  }

  void updateBrief(ContentJson patch) {
    if (loading ||
        restorationFailed ||
        submitting ||
        generation?.active == true) {
      return;
    }
    final mergedPatch = patch['settings'] != null
        ? {
            ...patch,
            'settings': {...settings, ...contentObject(patch['settings'])},
          }
        : patch;
    brief = {...brief, ...mergedPatch};
    if (step > furthestStep) furthestStep = step;
    _pendingDraft.addAll(mergedPatch);
    saveState = ContentSaveState.unsaved;
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 800),
      () => unawaited(flushDraft()),
    );
    final changedSettings = patch['settings'];
    if (changedSettings is Map<String, dynamic> &&
        (changedSettings.containsKey('frameCount') ||
            changedSettings.containsKey('durationSeconds'))) {
      unawaited(requote());
    }
    _remember();
    changed();
  }

  void selectProduct(ProductCatalogItem product) {
    selectedProduct = product;
    uploadUrl = null;
    updateBrief({
      'productId': product.id,
      'sourceUploadPath': null,
      if (brief['title'] == null) 'title': '${product.name} · ${format.label}',
    });
  }

  Future<void> upload(Uint8List bytes, String name) async {
    if (uploading) return;
    uploading = true;
    error = null;
    changed();
    try {
      final source = await repository.upload(bytes, name);
      if (disposed) return;
      uploadUrl = source['url'] as String;
      selectedProduct = null;
      updateBrief({
        'productId': null,
        'sourceUploadPath': source['sourcePath'] as String,
      });
    } on Object catch (e) {
      _handle(e);
    }
    uploading = false;
    changed();
  }

  void search(String query) {
    _searchTimer?.cancel();
    _searchToken?.cancel();
    ++_searchVersion;
    productsLoading = true;
    changed();
    _searchTimer = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(loadProducts(query)),
    );
  }

  Future<void> loadProducts(String query) async {
    final version = ++_searchVersion;
    _searchToken?.cancel();
    final token = _searchToken = RequestCancellation();
    productsLoading = true;
    productError = null;
    changed();
    try {
      final result = await repository.products(
        search: query,
        cancellation: token,
      );
      if (disposed || version != _searchVersion) return;
      products = result;
    } on Object catch (_) {
      if (disposed || version != _searchVersion) return;
      productError = 'Your products could not be loaded. Please try again.';
    }
    productsLoading = false;
    changed();
  }

  Future<void> requote() async {
    final version = ++_quoteVersion;
    _quoteToken?.cancel();
    final token = _quoteToken = RequestCancellation();
    quote = null;
    quoteLoading = true;
    quoteError = null;
    changed();
    try {
      final result = await repository.quote(
        format,
        settings,
        cancellation: token,
      );
      if (disposed || version != _quoteVersion) return;
      quote = result;
    } on Object catch (_) {
      if (disposed || version != _quoteVersion) return;
      quoteError = 'Credit estimate unavailable.';
    }
    quoteLoading = false;
    changed();
  }

  Future<bool> flushDraft() {
    _saveTimer?.cancel();
    return _save ??= _drainDraft().whenComplete(() {
      _save = null;
    });
  }

  Future<bool> _drainDraft() async {
    while (_pendingDraft.isNotEmpty) {
      final patch = Map<String, dynamic>.from(_pendingDraft);
      _pendingDraft.clear();
      saveState = ContentSaveState.saving;
      changed();
      try {
        final saved = await saveDraft(
          format: format,
          draftId: draftId,
          brief: brief,
          patch: patch,
          onRemoteDraftMissing: () => draftId = null,
        );
        draftId = saved.id;
      } on Object catch (e) {
        _pendingDraft = {...patch, ..._pendingDraft};
        saveState = ContentSaveState.offline;
        _handle(e);
        _remember();
        changed();
        return false;
      }
      _remember();
    }
    saveState = ContentSaveState.saved;
    error = null;
    changed();
    return true;
  }

  Future<void> generate({bool retry = false}) async {
    if (submitting ||
        generation?.active == true ||
        uploading ||
        loading ||
        restorationFailed) {
      return;
    }
    submitting = true;
    error = null;
    changed();
    try {
      if (retry &&
          (generation?.failed != true || generation?.retryable != true)) {
        return;
      }
      if (!retry && !hasSource) {
        error = 'Choose a product or upload an image first.';
        return;
      }
      if (!await flush()) return;
      if (!retry && draftId == null) {
        error = 'Save your brief before generating.';
        return;
      }
      final response = retry
          ? await repository.retry(generation!.id)
          : await repository.start(draftId!);
      final id = contentId(response);
      generation = ContentGeneration({
        ...response,
        'format': format.name,
        'frames': const <dynamic>[],
      });
      refreshCredits();
      _remember();
      await pollGeneration(id: id);
    } on ContentApiException catch (e) {
      if (e.status == 409 && e.activeJobId != null) {
        try {
          generation = await repository.generation(e.activeJobId!);
          format = generation!.format;
          final completedDraftId =
              generation!.data['draftId'] as String? ?? draftId;
          if (generation!.completed && completedDraftId != null) {
            await _deleteCompletedDraft(completedDraftId);
          }
          refreshCredits();
          _remember();
          if (generation!.active) unawaited(pollGeneration());
        } on Object catch (restoreError) {
          _handle(restoreError);
        }
      } else {
        _handle(e);
      }
    } on Object catch (e) {
      _handle(e);
    } finally {
      submitting = false;
      changed();
    }
  }

  Future<void> pollGeneration({String? id}) async {
    if (_polling || paused || disposed) return;
    final target = id ?? generation?.id;
    if (target == null) return;
    _pollTimer?.cancel();
    _polling = true;
    final epoch = _pollEpoch;
    final token = _pollToken = RequestCancellation();
    try {
      final result = await repository.generation(target, cancellation: token);
      if (disposed || paused || epoch != _pollEpoch) return;
      generation = result;
      format = result.format;
      error = null;
      if (result.completed) {
        final completedDraftId = result.data['draftId'] as String? ?? draftId;
        if (completedDraftId != null) {
          await _deleteCompletedDraft(
            completedDraftId,
            cancellation: token,
          );
        }
      }
      if (!result.active) refreshCredits();
      _remember();
    } on Object catch (e) {
      if (!disposed && !paused && epoch == _pollEpoch) _handle(e);
    } finally {
      _polling = false;
      if (!disposed && !paused && generation?.active == true) {
        _pollTimer = Timer(
          const Duration(seconds: 3),
          () => unawaited(pollGeneration()),
        );
      }
      changed();
    }
  }

  Future<void> _deleteCompletedDraft(
    String completedDraftId, {
    RequestCancellation? cancellation,
  }) async {
    try {
      await repository.deleteDraft(
        completedDraftId,
        cancellation: cancellation,
      );
    } on ContentApiException catch (e) {
      if (e.status != 404) rethrow;
    }
    if (draftId != completedDraftId) return;
    _saveTimer?.cancel();
    _pendingDraft.clear();
    draftId = null;
    saveState = ContentSaveState.saved;
  }

  Future<void> adjustBrief() async {
    if (generation?.active == true || editBusy) return;
    if (!await flushEdits()) return;
    final originalDraftId = generation?.data['draftId'];
    if (originalDraftId != null && draftId != originalDraftId) {
      try {
        final restored = await repository.latest(format);
        if (restored?.id == originalDraftId) {
          draftId = restored!.id;
          brief = {
            ...defaultContentBrief(format),
            ...Map.fromEntries(
              restored.data.entries.where(
                (e) => defaultContentBrief(format).containsKey(e.key),
              ),
            ),
          };
          uploadUrl = restored.data['sourceUploadUrl'] as String?;
        } else {
          brief = defaultContentBrief(format);
          draftId = null;
          selectedProduct = null;
          uploadUrl = null;
        }
      } on Object catch (e) {
        _handle(e);
        changed();
        return;
      }
    }
    generation = null;
    error = null;
    selectedFrame = 0;
    if (!hasSource) {
      error = 'Choose a product or upload an image to adjust this brief.';
    }
    updateBrief({
      'settings': {'lastStep': 1},
    });
    _remember();
    changed();
  }

  void selectFrame(int index) {
    if (generation == null) return;
    selectedFrame = index.clamp(0, generation!.frames.length - 1);
    changed();
  }

  Future<void> startNewBrief() async {
    if (submitting ||
        uploading ||
        generation?.active == true ||
        !await flush()) {
      return;
    }
    brief = defaultContentBrief(format);
    draftId = null;
    selectedProduct = null;
    uploadUrl = null;
    generation = null;
    furthestStep = 1;
    saveState = ContentSaveState.saved;
    _remember();
    unawaited(requote());
    changed();
  }

  void reportFailure(Object error) {
    _handle(error);
    changed();
  }

  void _optimisticFrame(String frameId, ContentJson patch) {
    generation = generation?.patch({
      'frames': [
        for (final f in generation!.frames)
          if (f.id == frameId) {...f.data, ...patch} else f.data,
      ],
    });
  }

  void _optimisticKit(ContentJson patch) {
    final cover = patch['coverFrameIndex'];
    generation = generation?.patch({
      'publishingKit': {
        ...?generation?.kit,
        ...Map.fromEntries(
          patch.entries.where((e) => e.key != 'coverFrameIndex'),
        ),
      },
      if (cover != null && generation?.video != null)
        'video': {...generation!.video!, 'coverFrameIndex': cover},
    });
  }

  void updateCrop(ContentJson? crop) {
    final current = frame;
    if (current == null || editBusy) return;
    _cropTimer?.cancel();
    _queueFrame(current.id, {'crop': crop});
    if (crop == null) {
      unawaited(flushEdits());
    } else {
      _cropTimer = Timer(
        const Duration(milliseconds: 600),
        () => unawaited(flushEdits()),
      );
    }
  }

  void selectVariant(String variantId) {
    if (frame == null || editBusy) return;
    _queueFrame(frame!.id, {'selectedVariantId': variantId});
    unawaited(flushEdits());
  }

  void _queueFrame(String id, ContentJson patch) {
    _pendingFrames[id] = {...?_pendingFrames[id], ...patch};
    _optimisticFrame(id, patch);
    editSaveState = ContentSaveState.unsaved;
    _remember();
    changed();
  }

  void updatePublishing(ContentJson patch, {bool debounce = false}) {
    if (!reviewing) return;
    final normalizedPatch = patch['hashtags'] != null
        ? {
            ...patch,
            'hashtags': normalizeContentHashtags(
              (patch['hashtags'] as List).cast<String>(),
            ),
          }
        : patch;
    _pendingKit.addAll(normalizedPatch);
    _optimisticKit(normalizedPatch);
    editSaveState = ContentSaveState.unsaved;
    _captionTimer?.cancel();
    if (debounce) {
      _captionTimer = Timer(
        const Duration(milliseconds: 800),
        () => unawaited(flushEdits()),
      );
    } else {
      unawaited(flushEdits());
    }
    _remember();
    changed();
  }

  Future<bool> flushEdits() {
    _cropTimer?.cancel();
    _captionTimer?.cancel();
    return _editSave ??= _drainEdits().whenComplete(() {
      _editSave = null;
    });
  }

  Future<bool> _drainEdits() async {
    final id = generation?.id;
    if (id == null) return true;
    while (_pendingFrames.isNotEmpty || _pendingKit.isNotEmpty) {
      editSaveState = ContentSaveState.saving;
      editError = null;
      changed();
      final frames = Map<String, ContentJson>.from(_pendingFrames);
      _pendingFrames.clear();
      final kit = Map<String, dynamic>.from(_pendingKit);
      _pendingKit.clear();
      try {
        for (final key in frames.keys.toList()) {
          final result = await repository.frame(id, key, frames[key]!);
          _optimisticFrame(key, {...result.data, ...?_pendingFrames[key]});
          frames.remove(key);
        }
        if (kit.isNotEmpty) {
          final result = await repository.publishing(id, kit);
          _optimisticKit({
            ...contentObject(result['publishingKit']),
            if (result['coverFrameIndex'] != null)
              'coverFrameIndex': result['coverFrameIndex'],
            ..._pendingKit,
          });
        }
      } on Object catch (e) {
        for (final entry in frames.entries) {
          _pendingFrames[entry.key] = {
            ...entry.value,
            ...?_pendingFrames[entry.key],
          };
        }
        _pendingKit = {...kit, ..._pendingKit};
        editSaveState = ContentSaveState.offline;
        editError = 'Changes are not saved. Retry before leaving.';
        _handle(e);
        _remember();
        changed();
        return false;
      }
      _remember();
    }
    editSaveState = ContentSaveState.saved;
    changed();
    return true;
  }

  Future<bool> flush() async {
    final draftSaved = await flushDraft();
    final editsSaved = await flushEdits();
    await _recoveryWrite;
    return draftSaved && editsSaved;
  }

  Future<void> editFrame({String? prompt}) async {
    if (editBusy || frame == null || prompt != null && prompt.trim().isEmpty) {
      return;
    }
    editBusy = true;
    final generationId = generation!.id;
    final frameId = frame!.id;
    error = null;
    changed();
    try {
      if (!await flushEdits()) {
        editBusy = false;
        return;
      }
      final result = await repository.edit(
        generationId,
        frameId,
        prompt: prompt?.trim(),
      );
      editJobId = contentId(result);
      refreshCredits();
      _remember();
      await pollEdit();
    } on ContentApiException catch (e) {
      if (e.status == 409 && e.activeJobId != null) {
        editJobId = e.activeJobId;
        _remember();
        await pollEdit();
      } else {
        editBusy = false;
        _handle(e);
      }
    } on Object catch (e) {
      editBusy = false;
      _handle(e);
    }
    changed();
  }

  Future<void> pollEdit() async {
    if (editJobId == null || _editPolling || paused || disposed) return;
    _editTimer?.cancel();
    _editPolling = true;
    final epoch = _editEpoch;
    final token = _editToken = RequestCancellation();
    try {
      final result = await repository.editStatus(
        editJobId!,
        cancellation: token,
      );
      if (disposed || paused || epoch != _editEpoch) return;
      if (!contentIsActive(result['status'] as String?)) {
        if (result['status'] == 'completed') {
          if (!await flushEdits()) return;
          final editedGenerationId = result['generationId'] as String;
          final refreshed = await repository.generation(
            editedGenerationId,
            cancellation: token,
          );
          if (generation?.id == refreshed.id) {
            generation = refreshed;
            for (final entry in _pendingFrames.entries) {
              _optimisticFrame(entry.key, entry.value);
            }
            if (_pendingKit.isNotEmpty) _optimisticKit(_pendingKit);
          }
        } else {
          editError = 'This frame edit failed. You can try again.';
        }
        editJobId = null;
        editBusy = false;
        refreshCredits();
        _remember();
      }
    } on Object catch (e) {
      if (!paused && !disposed) _handle(e);
    } finally {
      _editPolling = false;
      if (!disposed && !paused && editJobId != null) {
        _editTimer = Timer(
          const Duration(seconds: 3),
          () => unawaited(pollEdit()),
        );
      }
      changed();
    }
  }

  void _handle(Object e) {
    if (e is ContentApiException && e.cancelled) return;
    error = e is ContentApiException
        ? e.message
        : 'Something went wrong. Please try again.';
    if (e is ContentApiException && (e.status == 402 || e.status == 403)) {
      paywall = e.status;
    }
  }

  void setPaused({required bool value}) {
    paused = value;
    ++_pollEpoch;
    ++_editEpoch;
    _pollTimer?.cancel();
    _editTimer?.cancel();
    _pollToken?.cancel();
    _editToken?.cancel();
    if (value) {
      _remember();
      unawaited(flush());
    } else {
      if (generation?.active == true) unawaited(pollGeneration());
      if (editJobId != null) unawaited(pollEdit());
    }
  }

  @override
  void dispose() {
    disposed = true;
    for (final timer in [
      _saveTimer,
      _searchTimer,
      _pollTimer,
      _editTimer,
      _cropTimer,
      _captionTimer,
    ]) {
      timer?.cancel();
    }
    for (final token in [
      _restoreToken,
      _searchToken,
      _quoteToken,
      _pollToken,
      _editToken,
    ]) {
      token?.cancel();
    }
    super.dispose();
  }
}
