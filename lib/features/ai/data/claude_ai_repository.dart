import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/features/ai/domain/ai_repository.dart';
import 'package:look_atlas/features/ai/domain/chat_message.dart';

/// Anthropic Claude Messages API client with Server-Sent Events streaming.
///
/// SECURITY: in production, set `AI_BASE_URL` to your own backend proxy that
/// holds the key server-side and leave `AI_API_KEY` empty. Shipping a raw API
/// key in a mobile binary lets anyone extract and abuse it. The direct-key
/// path here is for local development only.
class ClaudeAiRepository implements AiRepository {
  ClaudeAiRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.aiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(minutes: 5),
            ),
          );

  final Dio _dio;
  static const _anthropicVersion = '2023-06-01';
  static const _maxTokens = 1024;

  @override
  bool get isConfigured =>
      AppConfig.hasAiKey || AppConfig.aiBaseUrl != 'https://api.anthropic.com';

  @override
  Stream<String> streamReply({
    required List<ChatMessage> history,
    String? systemPrompt,
    CancelToken? cancelToken,
  }) async* {
    if (!isConfigured) {
      throw const AiFailure(
        'AI is not configured. Set AI_API_KEY or an AI_BASE_URL proxy.',
      );
    }

    final body = <String, dynamic>{
      'model': AppConfig.aiModel,
      'max_tokens': _maxTokens,
      'stream': true,
      'messages': history.map((m) => m.toApiJson()).toList(),
      'system': ?systemPrompt,
    };

    // The try wraps the request AND the yield* so that mid-stream errors
    // (connection drops, malformed SSE payloads) are also translated.
    try {
      final response = await _dio.post<ResponseBody>(
        ApiEndpoints.aiMessages,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'content-type': 'application/json',
            'anthropic-version': _anthropicVersion,
            // Only sent in dev; a proxy injects this server-side in prod.
            if (AppConfig.hasAiKey) 'x-api-key': AppConfig.aiApiKey,
          },
        ),
      );

      yield* _parseSse(response.data!.stream);
    } on DioException catch (error, stack) {
      // Cancellation is a deliberate user action: end the stream quietly.
      if (error.type == DioExceptionType.cancel) return;
      throw AiFailure(
        'The AI request failed. Please try again.',
        cause: error,
        stackTrace: stack,
      );
    } on FormatException catch (error, stack) {
      throw AiFailure(
        'The AI response could not be read. Please try again.',
        cause: error,
        stackTrace: stack,
      );
    }
  }

  /// Parses an SSE byte stream, yielding text deltas from `content_block_delta`
  /// events, stopping on `message_stop` and throwing [AiFailure] on `error`
  /// events (e.g. `overloaded_error`).
  Stream<String> _parseSse(Stream<List<int>> byteStream) async* {
    // LineSplitter buffers partial lines across chunk boundaries for us.
    final lines = byteStream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload.isEmpty) continue;

      final json = jsonDecode(payload) as Map<String, dynamic>;
      final type = json['type'] as String?;
      if (type == 'message_stop') return;
      if (type == 'error') {
        final error = json['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String?;
        throw AiFailure(
          message == null || message.isEmpty
              ? 'The AI service returned an error. Please try again.'
              : message,
        );
      }
      if (type == 'content_block_delta') {
        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta?['type'] == 'text_delta') {
          yield delta!['text'] as String;
        }
      }
    }
  }
}
