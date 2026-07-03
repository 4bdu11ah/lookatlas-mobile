import 'package:dio/dio.dart';
import 'package:look_atlas/features/ai/domain/chat_message.dart';

/// Streaming AI contract. Implementations yield incremental text deltas and
/// throw an `AiFailure` on error.
abstract interface class AiRepository {
  bool get isConfigured;

  /// Streams the assistant reply token-by-token given the conversation
  /// [history] (the latest user message must be last).
  ///
  /// Pass a [cancelToken] to abort the in-flight request; cancellation ends
  /// the stream quietly (no error is thrown) and tears down the underlying
  /// HTTP connection so no further tokens are generated.
  Stream<String> streamReply({
    required List<ChatMessage> history,
    String? systemPrompt,
    CancelToken? cancelToken,
  });
}
