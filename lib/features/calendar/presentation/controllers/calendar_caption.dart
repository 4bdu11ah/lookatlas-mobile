import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/errors/content_api_exception.dart';
import 'package:look_atlas/features/create_content/domain/repositories/content_repository.dart';

/// One drawer owns one generation; late responses cannot affect another post.
class CalendarCaption extends ChangeNotifier {
  CalendarCaption(this.repository, this.generationId, {required this.refresh});
  final ContentRepository repository;
  final String generationId;
  final Future<void> Function() refresh;
  final RequestCancellation _token = RequestCancellation();
  String value = '';
  String savedValue = '';
  String? error;
  bool saving = false;
  bool loaded = false;
  bool _disposed = false;
  bool _saved = false;
  ContentGeneration? generation;
  bool get saved =>
      _saved && loaded && value == savedValue && !saving && error == null;
  List<String> get hashtags =>
      (generation?.kit?['hashtags'] as List? ?? []).cast<String>();
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void edit(String text) {
    value = text;
    error = null;
    _saved = false;
    _emit();
  }

  Future<void> load() async {
    error = null;
    _emit();
    try {
      final result = await repository.generation(
        generationId,
        cancellation: _token,
      );
      if (_disposed) return;
      generation = result;
      value = result.kit?['caption'] as String? ?? '';
      savedValue = value;
      loaded = true;
    } on Object {
      if (!_disposed) error = 'Could not load the caption. Try again.';
    }
    _emit();
  }

  Future<bool> save() async {
    if (_disposed || saving) return false;
    if (!loaded || value == savedValue) return true;
    if (value.length > 2200) {
      error = 'Captions can have at most 2,200 characters.';
      _emit();
      return false;
    }
    final submitted = value;
    saving = true;
    error = null;
    _emit();
    try {
      await repository.publishing(generationId, {
        'caption': submitted,
      }, cancellation: _token);
      if (_disposed) return false;
      savedValue = submitted;
      _saved = true;
    } on Object catch (failure) {
      if (!_disposed) {
        error = failure is ContentApiException
            ? failure.message
            : 'The caption didn’t save. Try again.';
      }
    } finally {
      await refresh();
      saving = false;
      _emit();
    }
    return !_disposed && error == null && value == savedValue;
  }

  @override
  void dispose() {
    _disposed = true;
    _token.cancel();
    super.dispose();
  }
}
