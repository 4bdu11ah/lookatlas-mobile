import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';

enum AssistantView { chat, history }

enum AssistantLimit { none, minute, daily }

class AssistantState {
  const AssistantState({
    this.view = AssistantView.chat,
    this.conversations = const [],
    this.conversationsLoaded = false,
    this.conversationsLoading = false,
    this.activeConversationId,
    this.messagesByConversationId = const {},
    this.messagesLoading = false,
    this.pendingUserMessage,
    this.sending = false,
    this.drafts = const {},
    this.limit = AssistantLimit.none,
    this.limitSeconds = 0,
    this.error,
    this.longConversationNudge = false,
    this.deleteCandidateId,
  });

  final AssistantView view;
  final List<AssistantConversation> conversations;
  final bool conversationsLoaded;
  final bool conversationsLoading;
  final String? activeConversationId;
  final Map<String, List<AssistantMessage>> messagesByConversationId;
  final bool messagesLoading;
  final String? pendingUserMessage;
  final bool sending;
  final Map<String, String> drafts;
  final AssistantLimit limit;
  final int limitSeconds;
  final String? error;
  final bool longConversationNudge;
  final String? deleteCandidateId;

  String get draftKey => activeConversationId ?? 'new';
  String get draft => drafts[draftKey] ?? '';
  List<AssistantMessage> get messages =>
      messagesByConversationId[activeConversationId] ?? const [];
  bool get composerDisabled => limit != AssistantLimit.none || sending;

  AssistantState copyWith({
    AssistantView? view,
    List<AssistantConversation>? conversations,
    bool? conversationsLoaded,
    bool? conversationsLoading,
    Object? activeConversationId = _unset,
    Map<String, List<AssistantMessage>>? messagesByConversationId,
    bool? messagesLoading,
    Object? pendingUserMessage = _unset,
    bool? sending,
    Map<String, String>? drafts,
    AssistantLimit? limit,
    int? limitSeconds,
    Object? error = _unset,
    bool? longConversationNudge,
    Object? deleteCandidateId = _unset,
  }) => AssistantState(
    view: view ?? this.view,
    conversations: conversations ?? this.conversations,
    conversationsLoaded: conversationsLoaded ?? this.conversationsLoaded,
    conversationsLoading: conversationsLoading ?? this.conversationsLoading,
    activeConversationId: identical(activeConversationId, _unset)
        ? this.activeConversationId
        : activeConversationId as String?,
    messagesByConversationId:
        messagesByConversationId ?? this.messagesByConversationId,
    messagesLoading: messagesLoading ?? this.messagesLoading,
    pendingUserMessage: identical(pendingUserMessage, _unset)
        ? this.pendingUserMessage
        : pendingUserMessage as String?,
    sending: sending ?? this.sending,
    drafts: drafts ?? this.drafts,
    limit: limit ?? this.limit,
    limitSeconds: limitSeconds ?? this.limitSeconds,
    error: identical(error, _unset) ? this.error : error as String?,
    longConversationNudge: longConversationNudge ?? this.longConversationNudge,
    deleteCandidateId: identical(deleteCandidateId, _unset)
        ? this.deleteCandidateId
        : deleteCandidateId as String?,
  );
}

const _unset = Object();
