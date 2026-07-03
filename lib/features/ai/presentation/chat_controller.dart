import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/features/ai/di/ai_providers.dart';
import 'package:look_atlas/features/ai/domain/ai_repository.dart';
import 'package:look_atlas/features/ai/domain/chat_message.dart';

@immutable
class ChatState {
  const ChatState({this.messages = const [], this.isStreaming = false});

  final List<ChatMessage> messages;
  final bool isStreaming;

  ChatState copyWith({List<ChatMessage>? messages, bool? isStreaming}) =>
      ChatState(
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}

class ChatController extends Notifier<ChatState> {
  /// Monotonic id of the current generation. Bumped on every [send], [stop]
  /// and [clear] so a stale stream can never write into a newer conversation.
  int _generation = 0;

  /// Token cancelling the in-flight HTTP request, if any.
  CancelToken? _cancelToken;

  @override
  ChatState build() {
    ref.onDispose(() => _cancelToken?.cancel());
    return const ChatState();
  }

  AiRepository get _repo => ref.read(aiRepositoryProvider);

  /// Sends [input] and streams the assistant reply into a placeholder bubble.
  ///
  /// No-op while a reply is already streaming; use [stop] to interrupt it.
  Future<void> send(String input) async {
    final text = input.trim();
    if (text.isEmpty || state.isStreaming) return;

    final generation = ++_generation;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final history = [
      ...state.messages,
      ChatMessage(role: ChatRole.user, text: text),
    ];

    // Append the user message plus an empty assistant placeholder to stream into.
    state = state.copyWith(
      messages: [
        ...history,
        const ChatMessage(
          role: ChatRole.assistant,
          text: '',
          isStreaming: true,
        ),
      ],
      isStreaming: true,
    );

    final buffer = StringBuffer();
    try {
      final stream = _repo.streamReply(
        history: history,
        cancelToken: cancelToken,
      );
      await for (final delta in stream) {
        // Abandon the loop if this generation was stopped or cleared.
        if (generation != _generation) return;
        buffer.write(delta);
        _updateAssistant(generation, buffer.toString(), streaming: true);
      }
      _updateAssistant(generation, buffer.toString(), streaming: false);
    } on AiFailure catch (failure) {
      _updateAssistant(generation, failure.message, streaming: false);
    } on Object {
      _updateAssistant(
        generation,
        'Something went wrong. Please try again.',
        streaming: false,
      );
    } finally {
      if (generation == _generation) {
        _cancelToken = null;
        _finishStreaming();
      }
    }
  }

  /// Stops the in-flight generation, cancelling the underlying HTTP request.
  ///
  /// The partially streamed assistant bubble is kept and marked complete.
  void stop() {
    if (!state.isStreaming) return;
    _generation++;
    _cancelToken?.cancel('Generation stopped by user.');
    _cancelToken = null;
    _finishStreaming();
  }

  /// Clears the conversation, cancelling any in-flight generation first.
  void clear() {
    _generation++;
    _cancelToken?.cancel('Conversation cleared.');
    _cancelToken = null;
    state = const ChatState();
  }

  /// Rewrites the last (assistant) bubble, but only if [generation] is still
  /// current — stale streams must never touch a newer conversation.
  void _updateAssistant(
    int generation,
    String text, {
    required bool streaming,
  }) {
    if (generation != _generation) return;
    if (state.messages.isEmpty) return;
    final messages = [...state.messages];
    messages[messages.length - 1] = messages.last.copyWith(
      text: text,
      isStreaming: streaming,
    );
    state = state.copyWith(messages: messages);
  }

  /// Clears the state-level streaming flag and any lingering per-bubble flag.
  void _finishStreaming() {
    final messages = [...state.messages];
    if (messages.isNotEmpty && messages.last.isStreaming) {
      messages[messages.length - 1] = messages.last.copyWith(
        isStreaming: false,
      );
    }
    state = state.copyWith(messages: messages, isStreaming: false);
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
