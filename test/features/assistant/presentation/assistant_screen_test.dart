import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/features/assistant/di/assistant_providers.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';
import 'package:look_atlas/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:look_atlas/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_feature_scaffold.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

void main() {
  Future<void> pumpAssistant(
    WidgetTester tester, {
    List<AssistantConversation> conversations = const [],
    AssistantRepository? repository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantRepositoryProvider.overrideWithValue(
            repository ?? _ScreenAssistantRepository(conversations),
          ),
          analyticsServiceProvider.overrideWithValue(NoopAnalyticsService()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AssistantScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('emptyState_starterSendsCanonicalTurn_andShowsReply', (
    tester,
  ) async {
    await pumpAssistant(tester);

    expect(find.text('How can I help?'), findsOneWidget);
    expect(
      find.text('Ask anything about shoots, credits, or billing.'),
      findsOneWidget,
    );
    expect(find.text('How do refunds work?'), findsOneWidget);
    expect(find.byType(AppFeatureScaffold), findsOneWidget);
    expect(find.byType(CustomAppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.byTooltip('New chat'), findsOneWidget);
    expect(find.byIcon(Icons.chat_outlined), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(
      find.ancestor(
        of: find.byKey(const Key('assistant-send')),
        matching: find.byType(AppTextField),
      ),
      findsNothing,
    );
    final textFieldBounds = tester.getRect(
      find.byKey(const Key('assistant-composer')),
    );
    final sendButtonBounds = tester.getRect(
      find.byKey(const Key('assistant-send')),
    );
    expect(sendButtonBounds.left - textFieldBounds.right, 5);
    expect(sendButtonBounds.height, textFieldBounds.height);
    expect(sendButtonBounds.height, 48);

    await tester.tap(find.text('How do credits work?'));
    await tester.pumpAndSettle();

    expect(find.text('How do credits work?'), findsOneWidget);
    expect(find.text('Credits work like a wallet.'), findsOneWidget);
  });

  testWidgets('history_deleteShowsExactConfirmation_andRemovesRow', (
    tester,
  ) async {
    final twoMinutesAgo = DateTime.now().toUtc().subtract(
      const Duration(minutes: 2),
    );
    await pumpAssistant(
      tester,
      conversations: [
        AssistantConversation(
          id: 'chat-1',
          title: 'How do credits work?',
          messageCount: 2,
          lastMessageAt: twoMinutesAgo,
        ),
      ],
    );

    await tester.tap(find.byTooltip('Past chats'));
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('How do credits work?'), findsOneWidget);
    expect(find.text('2m'), findsOneWidget);
    expect(find.text('2m ago'), findsNothing);
    expect(find.byTooltip('New chat'), findsNothing);
    expect(find.byTooltip('Past chats'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsOneWidget);
    expect(find.byType(AppDialogActionFooter), findsOneWidget);
    expect(find.text('Delete this chat?'), findsOneWidget);
    expect(
      find.text(
        'This removes the conversation from your history. '
        'This cannot be undone.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('How do credits work?'), findsNothing);
  });

  testWidgets('history_deleteActiveChat_opensCleanNewChat', (tester) async {
    const conversation = AssistantConversation(
      id: 'chat-1',
      title: 'Current chat',
      messageCount: 2,
    );
    final repository = _DelayedMessagesAssistantRepository(
      const [conversation],
    );
    await pumpAssistant(tester, repository: repository);

    await tester.tap(find.byTooltip('Past chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current chat'));
    await tester.pump();
    await tester.tap(find.byTooltip('Past chats'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('How can I help?'), findsOneWidget);
    repository.completeMessages();
    await tester.pumpAndSettle();
    expect(find.text('Cached deleted message'), findsNothing);
    expect(find.text('How can I help?'), findsOneWidget);
  });
}

class _ScreenAssistantRepository implements AssistantRepository {
  _ScreenAssistantRepository(this.conversations);

  final List<AssistantConversation> conversations;

  @override
  void cancelPendingLoads() {}

  @override
  Future<Result<void>> deleteConversation(String conversationId) async =>
      const Result.ok(null);

  @override
  Future<Result<List<AssistantConversation>>> getConversations() async =>
      Result.ok(conversations);

  @override
  Future<Result<AssistantThread>> getMessages(String conversationId) async =>
      Result.ok(
        AssistantThread(
          conversation: conversations.singleWhere(
            (item) => item.id == conversationId,
          ),
          messages: const [],
        ),
      );

  @override
  Future<Result<AssistantSendResponse>> sendMessage({
    required String message,
    String? conversationId,
  }) async => const Result.ok(
    AssistantSendResponse(
      conversation: AssistantConversation(
        id: 'chat-1',
        title: 'How do credits work?',
        messageCount: 2,
      ),
      userMessage: AssistantMessage(
        id: 'user-1',
        role: AssistantRole.user,
        content: 'How do credits work?',
      ),
      reply: AssistantMessage(
        id: 'reply-1',
        role: AssistantRole.assistant,
        content: 'Credits work like a wallet.',
      ),
    ),
  );
}

class _DelayedMessagesAssistantRepository extends _ScreenAssistantRepository {
  _DelayedMessagesAssistantRepository(super.conversations);

  final _messagesCompleter = Completer<Result<AssistantThread>>();

  @override
  Future<Result<AssistantThread>> getMessages(String conversationId) =>
      _messagesCompleter.future;

  void completeMessages() {
    _messagesCompleter.complete(
      Result.ok(
        AssistantThread(
          conversation: conversations.single,
          messages: const [
            AssistantMessage(
              id: 'message-1',
              role: AssistantRole.user,
              content: 'Cached deleted message',
            ),
          ],
        ),
      ),
    );
  }
}
