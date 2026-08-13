import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/assistant/di/assistant_providers.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';
import 'package:look_atlas/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:look_atlas/features/assistant/presentation/controllers/assistant_analytics.dart';
import 'package:look_atlas/features/assistant/presentation/controllers/assistant_state.dart';
import 'package:look_atlas/services/service_providers.dart';

const assistantUnavailableMessage =
    'The assistant is temporarily unavailable. Please try again later. '
    'If you need help right now, visit the Support page.';

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );

class AssistantController extends Notifier<AssistantState> {
  static const conversationFullMessage =
      'This chat has reached its limit. Start a new chat to continue.';
  static const missingConversationMessage =
      'This conversation is no longer available';
  static const sendFailureMessage =
      'The assistant could not reply just now. Your message is back in the '
      'box, please try again.';
  static const deleteFailureMessage =
      'Could not delete the chat. Please try again.';

  Timer? _limitTimer;
  int _messageLoadId = 0;
  late final AssistantAnalytics _analytics;

  AssistantRepository get _repository => ref.read(assistantRepositoryProvider);

  @override
  AssistantState build() {
    final repository = ref.read(assistantRepositoryProvider);
    _analytics = AssistantAnalytics(ref.read(analyticsServiceProvider));
    ref.onDispose(() {
      _limitTimer?.cancel();
      repository.cancelPendingLoads();
    });
    return const AssistantState();
  }

  Future<void> open() async {
    _analytics.opened();
    if (state.conversationsLoading || state.messagesLoading) {
      state = state.copyWith(
        conversationsLoading: false,
        messagesLoading: false,
      );
    }
    if (!state.conversationsLoaded && !state.conversationsLoading) {
      await loadConversations();
    } else if (state.activeConversationId != null &&
        !state.messagesByConversationId.containsKey(
          state.activeConversationId,
        )) {
      await _loadActiveMessages();
    }
  }

  void close() {
    _messageLoadId++;
    _repository.cancelPendingLoads();
    state = state.copyWith(view: AssistantView.chat, messagesLoading: false);
  }

  void disposeView() {
    _messageLoadId++;
    _repository.cancelPendingLoads();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(conversationsLoading: true);
    final result = await _repository.getConversations();
    if (result case Err(:final failure)) {
      if (failure is CancelledFailure) {
        state = state.copyWith(conversationsLoading: false);
        return;
      }
      state = state.copyWith(
        conversationsLoading: false,
        conversationsLoaded: true,
      );
      _trackError(failure);
      return;
    }
    final conversations = result.valueOrNull!;
    final activeExists = conversations.any(
      (item) => item.id == state.activeConversationId,
    );
    state = state.copyWith(
      conversations: conversations,
      conversationsLoading: false,
      conversationsLoaded: true,
      activeConversationId: activeExists ? state.activeConversationId : null,
    );
    if (activeExists &&
        !state.messagesByConversationId.containsKey(
          state.activeConversationId,
        )) {
      await _loadActiveMessages();
    }
  }

  void showHistory() => state = state.copyWith(view: AssistantView.history);

  void showChat() => state = state.copyWith(view: AssistantView.chat);

  void newChat() {
    _messageLoadId++;
    _repository.cancelPendingLoads();
    state = state.copyWith(
      view: AssistantView.chat,
      activeConversationId: null,
      messagesLoading: false,
      error: null,
      longConversationNudge: false,
      deleteCandidateId: null,
    );
  }

  Future<void> selectConversation(String conversationId) async {
    state = state.copyWith(
      view: AssistantView.chat,
      activeConversationId: conversationId,
      error: null,
      longConversationNudge: false,
    );
    if (!state.messagesByConversationId.containsKey(conversationId)) {
      await _loadActiveMessages();
    }
  }

  Future<void> _loadActiveMessages() async {
    final conversationId = state.activeConversationId;
    if (conversationId == null) return;
    final requestId = ++_messageLoadId;
    state = state.copyWith(messagesLoading: true);
    final result = await _repository.getMessages(conversationId);
    if (requestId != _messageLoadId) return;
    if (result case Err(:final failure)) {
      if (failure is CancelledFailure) return;
      if (_isMissing(failure)) {
        _removeMissingConversation(conversationId);
      } else {
        state = state.copyWith(messagesLoading: false);
        _trackError(failure);
      }
      return;
    }
    final thread = result.valueOrNull!;
    state = state.copyWith(
      messagesLoading: false,
      messagesByConversationId: {
        ...state.messagesByConversationId,
        conversationId: thread.messages,
      },
    );
  }

  void setDraft(String value) {
    if (value.length > 2000) return;
    state = state.copyWith(drafts: {...state.drafts, state.draftKey: value});
  }

  Future<bool> send([String? rawMessage]) async {
    final originalMessage = rawMessage ?? state.draft;
    final message = originalMessage.trim();
    if (message.isEmpty || message.length > 2000 || state.composerDisabled) {
      return false;
    }
    final conversationId = state.activeConversationId;
    final draftKey = state.draftKey;
    final stopwatch = Stopwatch()..start();
    state = state.copyWith(
      pendingUserMessage: message,
      sending: true,
      drafts: {...state.drafts, draftKey: ''},
      error: null,
    );
    _trackMessageSent(conversationId, message.length);
    final result = await _repository.sendMessage(
      message: message,
      conversationId: conversationId,
    );
    if (result case Err(:final failure)) {
      _handleSendFailure(failure, draftKey, originalMessage, conversationId);
      return false;
    }
    final response = result.valueOrNull!;
    final existing = conversationId == null
        ? const <AssistantMessage>[]
        : state.messagesByConversationId[conversationId] ?? const [];
    final messages = [...existing, response.userMessage, response.reply];
    state = state.copyWith(
      activeConversationId: response.conversation.id,
      messagesByConversationId: {
        ...state.messagesByConversationId,
        response.conversation.id: messages,
      },
      conversations: _moveConversationToTop(response.conversation),
      pendingUserMessage: null,
      sending: false,
      longConversationNudge: response.nudge == 'long_conversation',
    );
    _analytics.replyReceived(stopwatch.elapsedMilliseconds);
    return true;
  }

  void _handleSendFailure(
    Failure failure,
    String draftKey,
    String message,
    String? conversationId,
  ) {
    final code = failure is NetworkFailure ? failure.code : null;
    state = state.copyWith(
      pendingUserMessage: null,
      sending: false,
      drafts: {...state.drafts, draftKey: message},
    );
    if (_isMissing(failure) && conversationId != null) {
      _removeMissingConversation(conversationId, restoredDraft: message);
    } else if (code == 'RATE_LIMIT_EXCEEDED') {
      final seconds = failure is NetworkFailure
          ? _retrySeconds(failure.details['retryAfterSeconds'])
          : 15;
      _startMinuteLimit(seconds);
    } else if (code == 'ASSISTANT_LIMIT_REACHED' ||
        code == 'ASSISTANT_DISABLED') {
      state = state.copyWith(
        limit: AssistantLimit.daily,
        error: assistantUnavailableMessage,
      );
      if (code == 'ASSISTANT_LIMIT_REACHED') _trackRateLimit('daily');
    } else {
      state = state.copyWith(
        error: code == 'CONVERSATION_FULL'
            ? conversationFullMessage
            : sendFailureMessage,
      );
    }
    _trackError(failure);
  }

  void requestDelete(String conversationId) =>
      state = state.copyWith(deleteCandidateId: conversationId);

  void cancelDelete() => state = state.copyWith(deleteCandidateId: null);

  Future<bool> confirmDelete() async {
    final conversationId = state.deleteCandidateId;
    if (conversationId == null) return false;
    final result = await _repository.deleteConversation(conversationId);
    if (result case Err(:final failure)) {
      state = state.copyWith(
        deleteCandidateId: null,
        error: deleteFailureMessage,
      );
      _trackError(failure);
      return false;
    }
    final messages = {...state.messagesByConversationId}
      ..remove(conversationId);
    final wasActive = state.activeConversationId == conversationId;
    state = state.copyWith(
      conversations: [
        for (final item in state.conversations)
          if (item.id != conversationId) item,
      ],
      messagesByConversationId: messages,
      activeConversationId: wasActive ? null : state.activeConversationId,
      view: wasActive ? AssistantView.chat : state.view,
      deleteCandidateId: null,
      error: null,
    );
    _analytics.conversationDeleted();
    return true;
  }

  void clearError() => state = state.copyWith(error: null);

  void _removeMissingConversation(
    String conversationId, {
    String? restoredDraft,
  }) {
    final messages = {...state.messagesByConversationId}
      ..remove(conversationId);
    state = state.copyWith(
      conversations: [
        for (final item in state.conversations)
          if (item.id != conversationId) item,
      ],
      messagesByConversationId: messages,
      activeConversationId: null,
      messagesLoading: false,
      drafts: restoredDraft == null
          ? state.drafts
          : {...state.drafts, 'new': restoredDraft},
      error: missingConversationMessage,
    );
  }

  List<AssistantConversation> _moveConversationToTop(
    AssistantConversation conversation,
  ) => [
    conversation,
    for (final item in state.conversations)
      if (item.id != conversation.id) item,
  ];

  void _startMinuteLimit(int seconds) {
    _limitTimer?.cancel();
    state = state.copyWith(
      limit: AssistantLimit.minute,
      limitSeconds: seconds,
      error: null,
    );
    _trackRateLimit('minute');
    _limitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.limitSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(
          limit: AssistantLimit.none,
          limitSeconds: 0,
        );
      } else {
        state = state.copyWith(limitSeconds: remaining);
      }
    });
  }

  void _trackMessageSent(String? conversationId, int chars) =>
      _analytics.messageSent(conversationId, chars);

  void trackStarter(String label) {
    _analytics.starterClicked(label);
  }

  void _trackRateLimit(String reason) {
    _analytics.rateLimited(reason);
  }

  void _trackError(Failure failure) {
    final code = failure is NetworkFailure
        ? failure.code ?? failure.statusCode?.toString() ?? 'unknown'
        : 'unknown';
    _analytics.error(code);
  }

  static bool _isMissing(Failure failure) =>
      failure is NetworkFailure && failure.statusCode == 404;

  static int _retrySeconds(Object? value) {
    final seconds = value is num ? value.toInt() : int.tryParse('$value');
    return seconds != null && seconds > 0 ? seconds : 15;
  }
}
