import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/assistant/di/assistant_providers.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';
import 'package:look_atlas/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:look_atlas/features/assistant/presentation/controllers/assistant_controller.dart';
import 'package:look_atlas/features/assistant/presentation/controllers/assistant_state.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';
import 'package:look_atlas/services/service_providers.dart';

void main() {
  test('send_pendingTurn_replacesItWithCanonicalServerMessages', () async {
    final send = Completer<Result<AssistantSendResponse>>();
    final repository = _FakeAssistantRepository(onSend: () => send.future);
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(assistantControllerProvider.notifier)
      ..setDraft('How do credits work?');

    final future = controller.send();

    expect(
      container.read(assistantControllerProvider).pendingUserMessage,
      'How do credits work?',
    );
    expect(container.read(assistantControllerProvider).draft, isEmpty);
    send.complete(const Result.ok(_sendResponse));
    expect(await future, isTrue);

    final state = container.read(assistantControllerProvider);
    expect(state.pendingUserMessage, isNull);
    expect(state.activeConversationId, 'chat-1');
    expect(state.messages.map((item) => item.id), ['user-1', 'reply-1']);
    expect(state.conversations.single.id, 'chat-1');
  });

  test('send_failure_restoresExactDraft_andMapsConversationFull', () async {
    final repository = _FakeAssistantRepository(
      onSend: () async => const Result.err(
        NetworkFailure('full', code: 'CONVERSATION_FULL'),
      ),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(assistantControllerProvider.notifier)
      ..setDraft('  exact draft  ');

    expect(await controller.send(), isFalse);

    final state = container.read(assistantControllerProvider);
    expect(state.draft, '  exact draft  ');
    expect(state.error, AssistantController.conversationFullMessage);
  });

  test('send_rateLimit_disablesComposer_andUsesRetrySeconds', () async {
    final repository = _FakeAssistantRepository(
      onSend: () async => const Result.err(
        NetworkFailure(
          'slow down',
          code: 'RATE_LIMIT_EXCEEDED',
          details: {'retryAfterSeconds': 3},
        ),
      ),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(assistantControllerProvider.notifier)
      ..setDraft('hello');

    await controller.send();

    final state = container.read(assistantControllerProvider);
    expect(state.limit, AssistantLimit.minute);
    expect(state.limitSeconds, 3);
    expect(state.composerDisabled, isTrue);
  });

  test(
    'selectConversation_404_removesStaleConversation_andStartsNew',
    () async {
      const stale = AssistantConversation(
        id: 'stale',
        title: 'Old chat',
        messageCount: 2,
      );
      final repository = _FakeAssistantRepository(
        conversations: const [stale],
        onMessages: () async => const Result.err(
          NetworkFailure('missing', statusCode: 404),
        ),
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(assistantControllerProvider.notifier);
      await controller.loadConversations();

      await controller.selectConversation('stale');

      final state = container.read(assistantControllerProvider);
      expect(state.activeConversationId, isNull);
      expect(state.conversations, isEmpty);
      expect(state.error, AssistantController.missingConversationMessage);
    },
  );

  test('send_assistantDisabled_disablesFeatureWithExactSupportCopy', () async {
    final repository = _FakeAssistantRepository(
      onSend: () async => const Result.err(
        NetworkFailure('disabled', code: 'ASSISTANT_DISABLED'),
      ),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(assistantControllerProvider.notifier)
      ..setDraft('hello');

    await controller.send();

    final state = container.read(assistantControllerProvider);
    expect(state.limit, AssistantLimit.daily);
    expect(state.error, assistantUnavailableMessage);
    expect(state.composerDisabled, isTrue);
  });

  test('send_duplicateWhilePending_callsRepositoryOnce', () async {
    final send = Completer<Result<AssistantSendResponse>>();
    final repository = _FakeAssistantRepository(onSend: () => send.future);
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(assistantControllerProvider.notifier)
      ..setDraft('hello');

    final first = controller.send();
    expect(await controller.send(), isFalse);
    send.complete(const Result.ok(_sendResponse));
    await first;

    expect(repository.sendCalls, 1);
  });

  test('confirmDelete_failure_keepsConversationAndShowsExactError', () async {
    const conversation = AssistantConversation(
      id: 'chat-1',
      title: 'Credits',
      messageCount: 2,
    );
    final repository = _FakeAssistantRepository(
      conversations: const [conversation],
      onDelete: () async => const Result.err(NetworkFailure('failed')),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(assistantControllerProvider.notifier);
    await controller.loadConversations();
    controller.requestDelete('chat-1');

    expect(await controller.confirmDelete(), isFalse);

    final state = container.read(assistantControllerProvider);
    expect(state.conversations.single.id, 'chat-1');
    expect(state.error, AssistantController.deleteFailureMessage);
  });

  test(
    'confirmDelete_activeChat_invalidatesPendingLoadAndStartsNewChat',
    () async {
      const conversation = AssistantConversation(
        id: 'chat-1',
        title: 'Credits',
        messageCount: 2,
      );
      final messages = Completer<Result<AssistantThread>>();
      final repository = _FakeAssistantRepository(
        conversations: const [conversation],
        onMessages: () => messages.future,
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(assistantControllerProvider.notifier);
      await controller.loadConversations();
      final selection = controller.selectConversation('chat-1');
      controller
        ..showHistory()
        ..requestDelete('chat-1');

      expect(await controller.confirmDelete(), isTrue);
      messages.complete(
        const Result.ok(
          AssistantThread(
            conversation: conversation,
            messages: [_sendResponseUserMessage, _sendResponseReply],
          ),
        ),
      );
      await selection;

      final state = container.read(assistantControllerProvider);
      expect(state.view, AssistantView.chat);
      expect(state.activeConversationId, isNull);
      expect(state.messages, isEmpty);
      expect(state.messagesByConversationId, isNot(contains('chat-1')));
      expect(state.messagesLoading, isFalse);
    },
  );

  test('send_longConversationNudge_setsNonblockingBannerState', () async {
    final repository = _FakeAssistantRepository(
      onSend: () async => const Result.ok(
        AssistantSendResponse(
          conversation: _sendResponseConversation,
          userMessage: _sendResponseUserMessage,
          reply: _sendResponseReply,
          nudge: 'long_conversation',
        ),
      ),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(assistantControllerProvider.notifier)
      ..setDraft('hello');

    await controller.send();

    expect(
      container.read(assistantControllerProvider).longConversationNudge,
      isTrue,
    );
  });
}

ProviderContainer _container(AssistantRepository repository) =>
    ProviderContainer(
      overrides: [
        assistantRepositoryProvider.overrideWithValue(repository),
        analyticsServiceProvider.overrideWithValue(NoopAnalyticsService()),
      ],
    );

class _FakeAssistantRepository implements AssistantRepository {
  _FakeAssistantRepository({
    this.conversations = const [],
    this.onMessages,
    this.onSend,
    this.onDelete,
  });

  final List<AssistantConversation> conversations;
  final Future<Result<AssistantThread>> Function()? onMessages;
  final Future<Result<AssistantSendResponse>> Function()? onSend;
  final Future<Result<void>> Function()? onDelete;
  int sendCalls = 0;

  @override
  void cancelPendingLoads() {}

  @override
  Future<Result<void>> deleteConversation(String conversationId) =>
      onDelete?.call() ?? Future.value(const Result.ok(null));

  @override
  Future<Result<List<AssistantConversation>>> getConversations() async =>
      Result.ok(conversations);

  @override
  Future<Result<AssistantThread>> getMessages(String conversationId) =>
      onMessages?.call() ??
      Future.value(
        Result.ok(
          AssistantThread(
            conversation: conversations.single,
            messages: const [],
          ),
        ),
      );

  @override
  Future<Result<AssistantSendResponse>> sendMessage({
    required String message,
    String? conversationId,
  }) {
    sendCalls++;
    return onSend?.call() ?? Future.value(const Result.ok(_sendResponse));
  }
}

const _sendResponse = AssistantSendResponse(
  conversation: _sendResponseConversation,
  userMessage: _sendResponseUserMessage,
  reply: _sendResponseReply,
);

const _sendResponseConversation = AssistantConversation(
  id: 'chat-1',
  title: 'Credits',
  messageCount: 2,
);

const _sendResponseUserMessage = AssistantMessage(
  id: 'user-1',
  role: AssistantRole.user,
  content: 'How do credits work?',
);

const _sendResponseReply = AssistantMessage(
  id: 'reply-1',
  role: AssistantRole.assistant,
  content: 'Credits work like a wallet.',
);
