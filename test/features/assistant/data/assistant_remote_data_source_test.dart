import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/assistant/data/data_sources/assistant_remote_data_source.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late AssistantRemoteDataSource dataSource;

  setUpAll(() => registerFallbackValue(CancelToken()));

  setUp(() {
    api = _MockApiService();
    dataSource = AssistantRemoteDataSourceImpl(api);
  });

  test('getConversations_callsListEndpoint_andDecodesRows', () async {
    when(
      () => api.get<List<AssistantConversation>>(
        ApiEndpoints.assistantConversations,
        cancelToken: any(named: 'cancelToken'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as List<AssistantConversation> Function(dynamic);
      return Result.ok(
        decoder({
          'conversations': [
            {
              'id': 'chat-1',
              'title': 'Credits',
              'messageCount': 2,
              'createdAt': '2026-08-12T10:00:00.000Z',
              'lastMessageAt': '2026-08-12T10:00:01.000Z',
            },
          ],
        }),
      );
    });

    final conversation =
        (await dataSource.getConversations()).valueOrNull!.single;

    expect(conversation.id, 'chat-1');
    expect(conversation.messageCount, 2);
  });

  test('getMessages_callsConversationEndpoint_andPreservesPlainText', () async {
    when(
      () => api.get<AssistantThread>(
        ApiEndpoints.assistantMessages('chat-1'),
        cancelToken: any(named: 'cancelToken'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as AssistantThread Function(dynamic);
      return Result.ok(
        decoder({
          'conversation': {
            'id': 'chat-1',
            'title': 'Credits',
            'messageCount': 1,
          },
          'messages': [
            {
              'id': 'message-1',
              'role': 'assistant',
              'content': '**plain**\nsecond line',
              'createdAt': '2026-08-12T10:00:01.000Z',
            },
          ],
        }),
      );
    });

    final message = (await dataSource.getMessages(
      'chat-1',
    )).valueOrNull!.messages.single;

    expect(message.role, AssistantRole.assistant);
    expect(message.content, '**plain**\nsecond line');
  });

  test(
    'sendMessage_newChat_postsOnlyMessage_andDecodesCanonicalTurn',
    () async {
      when(
        () => api.post<AssistantSendResponse>(
          ApiEndpoints.assistantSend,
          data: {'message': 'How do credits work?'},
          decoder: any(named: 'decoder'),
        ),
      ).thenAnswer((invocation) async {
        final decoder =
            invocation.namedArguments[#decoder]
                as AssistantSendResponse Function(dynamic);
        return Result.ok(decoder(_sendPayload));
      });

      final response = (await dataSource.sendMessage(
        message: 'How do credits work?',
      )).valueOrNull!;

      expect(response.conversation.id, 'chat-1');
      expect(response.userMessage.id, 'user-1');
      expect(response.reply.id, 'reply-1');
    },
  );

  test('deleteConversation_callsExactConversationEndpoint', () async {
    when(
      () => api.delete<void>(
        ApiEndpoints.assistantConversation('chat-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    final result = await dataSource.deleteConversation('chat-1');

    expect(result.isOk, isTrue);
    verify(
      () => api.delete<void>(
        ApiEndpoints.assistantConversation('chat-1'),
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });
}

const Map<String, Object> _sendPayload = {
  'conversation': {
    'id': 'chat-1',
    'title': 'Credits',
    'messageCount': 2,
  },
  'userMessage': {
    'id': 'user-1',
    'role': 'user',
    'content': 'How do credits work?',
    'createdAt': '2026-08-12T10:00:00.000Z',
  },
  'reply': {
    'id': 'reply-1',
    'role': 'assistant',
    'content': 'Credits work like a wallet.',
    'createdAt': '2026-08-12T10:00:01.000Z',
  },
};
